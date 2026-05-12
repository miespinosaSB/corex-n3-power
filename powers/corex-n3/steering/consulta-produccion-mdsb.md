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

### Paso 2 — Subir archivo como temporary attachment

```bash
curl -s -X POST \
  'https://jirasegurosbolivar.atlassian.net/rest/servicedeskapi/servicedesk/2/attachTemporaryFile' \
  -H 'X-Atlassian-Token: no-check' \
  -H 'X-ExperimentalApi: opt-in' \
  -u '<EMAIL>:<API_TOKEN>' \
  -F "file=@<RUTA_AL_ARCHIVO_SQL>"
```

Retorna: `{"temporaryAttachments": [{"temporaryAttachmentId": "<ID>", "fileName": "..."}]}`

Guardar el `temporaryAttachmentId` para el paso 3.

### Paso 3 — Crear el request con formulario + adjunto (atómico)

Usar la API de Service Desk con el campo `form.answers` para llenar el formulario ProForma:

```python
import json, urllib.request, base64, ssl

url = "https://jirasegurosbolivar.atlassian.net/rest/servicedeskapi/request"
creds = base64.b64encode(b"<EMAIL>:<API_TOKEN>").decode()

payload = {
    "serviceDeskId": "2",
    "requestTypeId": "83",
    "requestFieldValues": {
        "attachment": ["<TEMPORARY_ATTACHMENT_ID>"]
    },
    "form": {
        "answers": {
            "102": {"choices": ["12311"]},
            "112": {"choices": ["31708"]},
            "2": {"text": "3214325244"},
            "3": {"text": "1072660049"},
            "4": {"text": "michael.espinosa@segurosbolivar.com"},
            "13": {"choices": ["34662"]},
            "6": {"choices": ["26002"]},
            "63": {"choices": ["36606"]},
            "32": {"text": "OPS$PUMA"},
            "11": {"text": "https://jirasegurosbolivar.atlassian.net/browse/MDSB-1034590"},
            "73": {"choices": ["50268"]},
            "12": {"text": "Consulta"}
        }
    }
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(url, data=data, method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Basic {creds}")
req.add_header("X-ExperimentalApi", "opt-in")

ctx = ssl.create_default_context()
with urllib.request.urlopen(req, context=ctx) as resp:
    result = json.loads(resp.read().decode())
    print(result["issueKey"])  # MDSB-XXXXXXX
```

### Paso 4 — Limpiar y reportar

1. Eliminar el archivo `.sql` temporal del workspace
2. Informar al usuario:
   - Clave del caso creado (MDSB-XXXXXXX)
   - URL directa: `https://jirasegurosbolivar.atlassian.net/browse/MDSB-XXXXXXX`
   - La consulta que se envió
   - El bot AIOps lo procesará en ~1-2 minutos

### Paso 5 — Leer resultado (cuando el usuario confirme)

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

Las credenciales se leen de las variables de entorno del power:
- Email: `JIRA_USERNAME`
- Token: `JIRA_API_TOKEN`

## Notas importantes

- **CRÍTICO:** El archivo SQL DEBE estar adjunto AL MOMENTO de crear el request. Si se adjunta después, el bot lo rechaza ("Sin Archivo SQL").
- El flujo usa la API de Service Desk (`/rest/servicedeskapi/request`), NO la API REST estándar de Jira (`jira_create_issue`). La API estándar no genera el formulario ProForma.
- El campo `form.answers` en el payload es lo que llena el formulario ProForma automáticamente.
- Los campos `select` usan `{"choices": ["<ID>"]}`, los `text` usan `{"text": "<valor>"}`.
- El bot AIOps procesa SOLO consultas SELECT (no DML/DDL).
- Si el caso queda en "Consulta con éxito" → OK.
- Si queda en "Rechazado" → leer el comentario del bot para diagnóstico.
