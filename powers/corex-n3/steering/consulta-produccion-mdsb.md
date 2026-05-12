---
inclusion: manual
---

# Consulta a Producción vía MDSB

## Cuándo usar

Cuando el usuario pida ejecutar una consulta SQL en **producción** (Tronador prod), el agente NO tiene acceso directo. En su lugar, crea un caso MDSB en el portal de Service Desk que es procesado automáticamente por el bot AIOps.

## Triggers del usuario

- "consulta en prod..."
- "ejecuta esto en producción..."
- "necesito saber en prod..."
- "crea un MDSB con esta consulta..."
- "lanza esta consulta..."

## Flujo completo (3 pasos)

### Paso 1 — Generar el archivo SQL

Crear un archivo `.sql` temporal en el workspace con el template obligatorio + la consulta:

```sql
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
SET PAGESIZE 10000
SET FEEDBACK OFF
SET TRIMSPOOL ON
SET HEADING ON
SET LINESIZE 10000
SET UNDERLINE OFF

<QUERY_1>;

<QUERY_2>;
```

**Nombre del archivo:** `ConsultaBot (<uuid>).sql` — generar UUID con `uuidgen | tr '[:upper:]' '[:lower:]'`

### Paso 2 — Subir archivo y crear request (script autocontenido)

⚠️ **Las credenciales NO están en variables de entorno del shell.** Están en `~/.kiro/settings/.env`. El script debe leerlas de ahí.

Ejecutar este script Python que hace todo en un solo paso (upload + create request):

```python
#!/usr/bin/env python3
"""Crea un request MDSB con consulta SQL para el bot AIOps."""
import json, urllib.request, base64, ssl, os, re

# --- Leer credenciales de ~/.kiro/settings/.env ---
env_path = os.path.expanduser("~/.kiro/settings/.env")
env_vars = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, val = line.split("=", 1)
            env_vars[key.strip()] = val.strip()

EMAIL = env_vars["JIRA_USERNAME"]
TOKEN = env_vars["JIRA_API_TOKEN"]
CREDS = base64.b64encode(f"{EMAIL}:{TOKEN}".encode()).decode()
BASE_URL = "https://jirasegurosbolivar.atlassian.net"
CTX = ssl.create_default_context()

# --- Paso A: Subir archivo temporal ---
SQL_FILE = "<RUTA_AL_ARCHIVO_SQL>"  # Reemplazar con la ruta real

boundary = "----FormBoundary7MA4YWxkTrZu0gW"
filename = os.path.basename(SQL_FILE)
with open(SQL_FILE, "rb") as f:
    file_data = f.read()

body = (
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
    f"Content-Type: application/sql\r\n\r\n"
).encode() + file_data + f"\r\n--{boundary}--\r\n".encode()

req = urllib.request.Request(
    f"{BASE_URL}/rest/servicedeskapi/servicedesk/2/attachTemporaryFile",
    data=body, method="POST"
)
req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
req.add_header("Authorization", f"Basic {CREDS}")
req.add_header("X-Atlassian-Token", "no-check")
req.add_header("X-ExperimentalApi", "opt-in")

with urllib.request.urlopen(req, context=CTX) as resp:
    attach_result = json.loads(resp.read().decode())
    temp_id = attach_result["temporaryAttachments"][0]["temporaryAttachmentId"]
    print(f"Attachment uploaded: {temp_id}")

# --- Paso B: Crear request con formulario ---
JIRA_ASOCIADO = "<URL_JIRA_ASOCIADO>"  # Reemplazar con URL del caso de referencia

payload = {
    "serviceDeskId": "2",
    "requestTypeId": "83",
    "requestFieldValues": {
        "attachment": [temp_id]
    },
    "form": {
        "answers": {
            "102": {"choices": ["12311"]},
            "112": {"choices": ["31708"]},
            "2": {"text": "3214325244"},
            "3": {"text": "1072660049"},
            "4": {"text": EMAIL},
            "13": {"choices": ["34662"]},
            "6": {"choices": ["26002"]},
            "63": {"choices": ["36606"]},
            "32": {"text": "OPS$PUMA"},
            "11": {"text": JIRA_ASOCIADO},
            "73": {"choices": ["50268"]},
            "12": {"text": "Consulta"}
        }
    }
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(f"{BASE_URL}/rest/servicedeskapi/request", data=data, method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Basic {CREDS}")
req.add_header("X-ExperimentalApi", "opt-in")

with urllib.request.urlopen(req, context=CTX) as resp:
    result = json.loads(resp.read().decode())
    issue_key = result["issueKey"]
    print(f"Request created: {issue_key}")
    print(f"URL: {BASE_URL}/browse/{issue_key}")
```

**Instrucciones para el agente:**
1. Crear el archivo `.sql` (Paso 1)
2. Crear un script Python temporal (ej: `/tmp/mdsb_request.py`) con el código de arriba
3. Reemplazar `<RUTA_AL_ARCHIVO_SQL>` con la ruta real del archivo SQL creado
4. Reemplazar `<URL_JIRA_ASOCIADO>` con la URL del caso MDSB o HU de referencia
5. Ejecutar: `python3 /tmp/mdsb_request.py`
6. Capturar la clave del issue creado del output
7. Eliminar ambos archivos temporales

### Paso 3 — Limpiar y reportar

1. Eliminar el archivo `.sql` temporal del workspace
2. Informar al usuario:
   - Clave del caso creado (MDSB-XXXXXXX)
   - URL directa: `https://jirasegurosbolivar.atlassian.net/browse/MDSB-XXXXXXX`
   - La consulta que se envió
   - El bot AIOps lo procesará en ~1-2 minutos

### Paso 4 — Leer resultado (cuando el usuario confirme)

Cuando el usuario diga "ya está", "lee el resultado", "qué salió", etc.:

1. Obtener el issue: `jira_get_issue(issue_key, comment_limit=10)`
2. Verificar status = "Consulta con éxito"
3. Descargar adjuntos (logs de resultado): `jira_download_attachments(issue_key)`
4. Presentar los datos al usuario de forma legible

## Mapeo de campos del formulario ProForma

| Question ID | Campo | Tipo | Valor fijo | Choice ID |
|---|---|---|---|---|
| 102 | Tipo de Requerimiento DBA | select | Ejecución de Script de Consulta | `12311` |
| 112 | Tipo de Infraestructura | select | On Premises | `31708` |
| 2 | Número de Contacto | text | 3214325244 | — |
| 3 | Número de Documento del Usuario | text | 1072660049 | — |
| 4 | Correo Electrónico del Usuario | text | michael.espinosa@segurosbolivar.com | — |
| 13 | Tipo de Plataforma | select | Base de Datos | `34662` |
| 6 | Ambiente | select | Productivo | `26002` |
| 63 | Nombre Base de Datos | select | TRON | `36606` |
| 32 | Nombre del Esquema | text | OPS$PUMA | — |
| 11 | Jira Asociado | text | URL de referencia | — |
| 73 | ¿Extracción e inserción? | select | No | `50268` |
| 12 | Descripción | text | Consulta | — |

## Credenciales

⚠️ **Las credenciales NO están en variables de entorno del shell.** Están en el archivo:

```
~/.kiro/settings/.env
```

Variables disponibles:
- `JIRA_USERNAME` — email corporativo
- `JIRA_API_TOKEN` — token de Atlassian

**El script Python las lee directamente de ese archivo.** No intentar usar `$JIRA_USERNAME` en bash ni `os.environ["JIRA_USERNAME"]` — no funcionará. Siempre leer el archivo `.env` con `open()`.

## Notas importantes

- **CRÍTICO:** El archivo SQL DEBE estar adjunto AL MOMENTO de crear el request. Si se adjunta después, el bot lo rechaza ("Sin Archivo SQL").
- El flujo usa la API de Service Desk (`/rest/servicedeskapi/request`), NO la API REST estándar de Jira (`jira_create_issue`). La API estándar no genera el formulario ProForma.
- El campo `form.answers` en el payload es lo que llena el formulario ProForma automáticamente.
- Los campos `select` usan `{"choices": ["<ID>"]}`, los `text` usan `{"text": "<valor>"}`.
- El bot AIOps procesa SOLO consultas SELECT (no DML/DDL).
- Si el caso queda en "Consulta con éxito" → OK.
- Si queda en "Rechazado" → leer el comentario del bot para diagnóstico.
