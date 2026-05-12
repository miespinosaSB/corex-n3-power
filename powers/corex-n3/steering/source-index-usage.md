---
inclusion: auto
---

# Uso del Índice de Fuentes COBOL/Forms

## Regla

Cuando durante un diagnóstico se identifique un programa COBOL o pantalla Forms (por nombre en el caso Jira, en comentarios, o en la KB), consultar el índice de fuentes antes de intentar leer el archivo.

## Flujo

1. **Detectar referencia** — El caso menciona un programa (ej: "CB226030", "CP200030")
2. **Consultar índice** — Leer `shared-knowledge/source-index.json`
3. **Verificar disponibilidad** — Si `cobol.available` o `forms.available` es `true`, el repo está clonado
4. **Leer código fuente** — Usar la ruta del índice o construirla:
   - COBOL: `../tronador-core-cobol/{NOMBRE}.pco`
   - Forms: `../tronador-forms/FMT/{NOMBRE}.fmt`
5. **Extraer información relevante** — SPs que llama, tablas que toca, validaciones
6. **Documentar en KB** — Si el hallazgo es reutilizable, agregar a Confluence

## Mapeo de módulos

Usar `module_map` del índice para identificar el área funcional:
- `200` → Emisión Individual
- `226` → Emisión Colectivas
- `270` → Salud
- `299` → Cartera/Cancelaciones
- `502` → Recaudo
- `850` → Reaseguros

## Mapeo de tipos

Usar `type_map` del índice para entender el tipo de programa:
- `CB` → Batch (proceso nocturno)
- `CR` → Batch Report
- `AP` → Alta de Póliza
- `CP` → Consulta de Póliza
- `CC` → Consulta/Cambio

## Si el repo no está disponible

Si `available: false` en el índice:
1. Informar al usuario que el repo no está clonado
2. Sugerir: `git clone <url>/tronador-core-cobol.git ../tronador-core-cobol`
3. Continuar el diagnóstico con la información disponible (Oracle + KB)
4. Marcar en el reporte que falta verificar el código fuente COBOL/Forms
