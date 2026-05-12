---
inclusion: auto
---

# Fuentes de Código — Repositorios Tronador

## Repositorios disponibles localmente

El agente tiene acceso de lectura a 3 repositorios de código fuente que complementan la BD Oracle:

| Repositorio | Ruta relativa | Contenido | Formato |
|---|---|---|---|
| **tronador-oracle-db** | `<TRONADOR_BASE>/tronador-oracle-db/Base Datos/` | Packages, procedures, functions, triggers, tablas | `.pks`, `.pkb`, `.prc`, `.fnc`, `.trg`, `.sql` |
| **tronador-core-cobol** | `<TRONADOR_BASE>/tronador-core-cobol/` | Programas batch/online COBOL con SQL embebido | `.pco` (texto plano, legible) |
| **tronador-forms** | `<TRONADOR_BASE>/tronador-forms/FMT/` | Pantallas Oracle Forms (triggers, validaciones, lógica UI) | `.fmt` (texto plano, legible) |

### Configuración de ruta base

La ruta base de los repositorios Tronador se determina así:
1. Si existe la variable `TRONADOR_BASE` en el `.env` → usar esa ruta
2. Si no, asumir que los 3 repos están en el **directorio padre** del repo `tronador-oracle-db`

**Para compañeros del equipo:** Clonar los 3 repos en la misma carpeta padre:
```bash
mkdir -p ~/Documents/tronador && cd ~/Documents/tronador
git clone <url>/tronador-oracle-db.git
git clone <url>/tronador-core-cobol.git
git clone <url>/tronador-forms.git
```

Opcionalmente agregar al `.env`:
```
TRONADOR_BASE=/Users/tu-usuario/Documents/tronador
```

**Nota:** Los repos de COBOL y Forms son de solo lectura para el power. No se modifican. Solo se leen para diagnóstico.

## Cuándo consultar cada repositorio

### COBOL (`tronador-core-cobol`)
Consultar cuando:
- El caso menciona un **proceso batch** (CB = batch, CR = batch report)
- Se necesita entender el **flujo completo** de un proceso (emisión, recaudo, cancelación)
- El SP Oracle es llamado desde un programa COBOL y se necesita ver los parámetros que envía
- Se menciona un programa por nombre (ej: CB226030, CR902038)

**Convención de nombres COBOL:**
- `CB` = Batch (proceso nocturno/programado)
- `CR` = Batch Report (generación de reportes)
- Los números corresponden al módulo: `226` = emisión colectivas, `270` = salud, `299` = cartera, `502` = recaudo, `902` = siniestros, etc.

### Forms (`tronador-forms/FMT`)
Consultar cuando:
- El caso menciona una **pantalla** o **formulario** de Tronador
- Se necesita entender **validaciones de UI** que no están en la BD
- El usuario reporta un error en una pantalla específica (ej: "la pantalla de emisión no deja...")

**Convención de nombres Forms:**
- `AP` = Alta de Póliza (emisión)
- `CP` = Consulta de Póliza
- `CC` = Consulta/Cambio
- `AC` = Alta/Cambio
- `AS` = Alta Siniestro
- `AR` = Alta Reaseguro
- Los números corresponden al módulo: `200` = emisión, `270` = salud, `502` = recaudo, `850` = reaseguros, etc.

### Oracle DB (`tronador-oracle-db/Base Datos`)
Consultar cuando:
- Se necesita ver el **DDL** de una tabla, trigger, o índice
- Se necesita ver un **package/procedure** que no está en la BD de dev (fue borrado o renombrado)
- Se necesita ver el **historial de cambios** (git log) de un objeto

## Estrategia de diagnóstico con múltiples fuentes

Cuando un caso requiere trazar un flujo completo:

1. **Identificar el punto de entrada** — ¿Es un servicio REST? ¿Un batch? ¿Una pantalla?
2. **Leer el código del punto de entrada:**
   - Si es batch → buscar en `tronador-core-cobol/` el programa `.pco`
   - Si es pantalla → buscar en `tronador-forms/FMT/` el form `.fmt`
   - Si es servicio → buscar en el repo del microservicio
3. **Identificar los SPs Oracle que llama** — buscar `CALL`, `EXECUTE`, o SQL embebido
4. **Leer el SP en Oracle** — usar `get_source` del MCP oracle-readonly
5. **Trazar las tablas afectadas** — usar `get_dependencies` y `describe_table`
6. **Verificar datos** — usar `query` para validar el estado actual

## Regla de precisión en diagnósticos

⚠️ **OBLIGATORIO para mejorar precisión:**

1. **No diagnosticar solo con la KB.** Si la KB no tiene el patrón exacto, ir al código fuente.
2. **Leer el código, no asumir.** Antes de decir "el SP hace X", leer el código con `get_source` o leyendo el archivo `.pco`/`.fmt`.
3. **Trazar el flujo completo.** Un dato puede pasar 5 filtros y fallar en el 6to. Leer TODAS las funciones intermedias.
4. **Verificar con datos reales.** Después de leer el código, ejecutar queries para confirmar la hipótesis.
5. **Si la evidencia contradice el análisis, la evidencia gana.** Buscar qué se está omitiendo.

## Cómo buscar en los repositorios

Determinar la ruta base: buscar el directorio padre de `tronador-oracle-db` (donde está este power). Los repos hermanos están al mismo nivel.

Para buscar un programa COBOL por nombre:
```
Leer: <TRONADOR_BASE>/tronador-core-cobol/CB226030.pco
```

Para buscar un form por nombre:
```
Leer: <TRONADOR_BASE>/tronador-forms/FMT/CP200030.fmt
```

Para buscar un package en el repo (si no está en la BD):
```
Leer: <TRONADOR_BASE>/tronador-oracle-db/Base Datos/Packages/SIM_PCK_DEUDA.pkb
```

## Alimentación autónoma de la KB

Cuando el agente descubra información valiosa leyendo código fuente (COBOL, Forms, o PL/SQL), DEBE:

1. **Extraer el conocimiento relevante** — flujos, relaciones, validaciones, reglas de negocio
2. **Documentar en la KB de Confluence** — en la página del módulo correspondiente
3. **Formato:** Usar el formato de "Arquitectura Servicios" para paquetes/programas, o "Patrones de Problemas" para flujos descubiertos

Esto hace que la KB crezca orgánicamente con cada caso, y en el futuro el diagnóstico sea más rápido porque ya no necesita leer el código de nuevo.

### Qué documentar en la KB (criterios)

| Descubrimiento | Documentar en... | Ejemplo |
|---|---|---|
| Un programa COBOL que ejecuta un flujo clave | Arquitectura Servicios (1688338434) | "CB226030 ejecuta el proceso de emisión colectiva, llama a PRC_EMISION_COLECTIVA" |
| Una validación en Forms que causa errores | Patrones de Problemas (1688371201) | "La pantalla CP200030 valida X antes de llamar al SP, si falla muestra error Y" |
| Una relación entre tablas no documentada | Página del módulo | "A2990700.NUM_CUOTA se cruza con A5021600.NUM_CUOTA_PAGO para el recaudo" |
| Un flujo de negocio completo | Página del módulo | "Flujo de cancelación: CB299xxx → PRC_CANCELA → trigger TRG_A2000030_CANCEL → ..." |
