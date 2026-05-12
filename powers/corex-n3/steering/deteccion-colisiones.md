---
inclusion: auto
---

# Detección de Colisiones — Protección contra sobreescritura

## Regla Fundamental

⚠️ **ANTES de modificar cualquier archivo de Base Datos** (`.pkb`, `.pks`, `.prc`, `.fnc`, `.trg`, `.sql`), el agente DEBE ejecutar una verificación de colisiones para detectar si otro desarrollador ya está trabajando en el mismo objeto.

Esta verificación es **obligatoria** y se ejecuta **antes** del análisis de impacto (steering `analisis-impacto.md`). El orden es:

```
1. Detección de colisiones (este steering)  ← ¿alguien más está tocando esto?
2. Análisis de impacto (analisis-impacto.md) ← ¿qué afecta mi cambio?
3. Implementación (si ambos dan verde)
```

---

## Verificación de Colisiones — 4 fuentes de señal

### Señal 1: Ramas activas en Git

Buscar ramas remotas que toquen el mismo archivo:

```bash
# Traer info de ramas remotas sin descargar todo
git fetch --all --prune

# Buscar ramas activas (no mergeadas a dev) que toquen el archivo
git log --all --oneline --source --remotes --not refs/remotes/origin/dev -- "Base Datos/Packages/<NOMBRE_ARCHIVO>.pkb" "Base Datos/Packages/<NOMBRE_ARCHIVO>.pks" "Base Datos/Funciones/<NOMBRE_ARCHIVO>.fnc" "Base Datos/Procedimientos/<NOMBRE_ARCHIVO>.prc"
```

Si hay resultados → hay una rama activa que ya modificó ese archivo.

**También buscar por nombre del objeto en mensajes de commit recientes:**

```bash
git log --all --oneline --since="30 days ago" --grep="<NOMBRE_OBJETO>"
```

### Señal 2: Historias en progreso en Jira

Buscar issues activos que mencionen el objeto:

```
jira_search(
  jql='project in (GD980,GD981,GD982,GD983,GD984,GD986,GD987,GD988,GD989) AND status in ("In Progress","En Progreso","En curso","En desarrollo","Code Review") AND text ~ "<NOMBRE_OBJETO>" ORDER BY updated DESC',
  fields='summary,status,assignee',
  limit=10
)
```

Si hay resultados → alguien tiene una Historia activa que involucra ese objeto.

### Señal 3: Documentación reciente en Confluence

Buscar páginas recientes que mencionen el objeto:

```
confluence_search(
  query='text ~ "<NOMBRE_OBJETO>" AND lastModified > startOfMonth("-1M")',
  limit=5,
  spaces_filter="BDCT"
)
```

Si hay resultados → alguien documentó trabajo reciente sobre ese objeto.

### Señal 4: Estado del objeto en Oracle

Verificar si el objeto fue compilado recientemente (señal de que alguien lo modificó en la BD directamente):

```sql
SELECT object_name, object_type, status, last_ddl_time
FROM all_objects
WHERE object_name = :NOMBRE_OBJETO
  AND owner = 'OPS$PUMA'
  AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER')
ORDER BY last_ddl_time DESC
```

Si `last_ddl_time` es reciente (últimos 7 días) y no corresponde a un cambio nuestro → alguien más lo modificó.

---

## Evaluación de Resultados

### 🟢 Sin colisión detectada

Ninguna señal encontró actividad de otros desarrolladores sobre el objeto. Proceder con el análisis de impacto.

### 🟡 Colisión posible

Se encontró actividad pero no es concluyente (ej: una rama vieja, un issue cerrado recientemente, un DDL de hace 5 días). Informar al usuario:

```markdown
## ⚠️ Posible colisión detectada en: <NOMBRE_OBJETO>

| Señal | Hallazgo |
|---|---|
| Git | Rama `GD986-XXXX` tocó este archivo hace X días |
| Jira | GD987-YYYY "título" está en estado "En Progreso" (assignee: Fulano) |
| Confluence | Página "título" actualizada el DD/MM |
| Oracle | last_ddl_time: DD/MM/YYYY |

**Recomendación:** Verificar con el equipo antes de proceder. ¿Querés que continúe o preferís coordinar primero?
```

### 🔴 Colisión confirmada

Hay una rama activa no mergeada que modifica el mismo archivo, O hay una Historia en progreso asignada a otro desarrollador que menciona el mismo objeto. **DETENER** y alertar:

```markdown
## 🛑 Colisión detectada en: <NOMBRE_OBJETO>

**Otro desarrollador está trabajando activamente en este objeto:**

| Señal | Detalle |
|---|---|
| Git | Rama `<rama>` tiene commits sobre `<archivo>` (autor: <nombre>) |
| Jira | <ISSUE_KEY> "<título>" — assignee: <nombre> — estado: <estado> |

**Acción requerida:** Coordinar con <nombre> antes de hacer cambios. Si ambos modifican el mismo paquete sin coordinarse, uno va a sobreescribir el trabajo del otro.

**Opciones:**
1. Esperar a que <nombre> termine y mergee su rama
2. Coordinar para trabajar en secciones distintas del paquete
3. Trabajar sobre la rama de <nombre> (si tiene sentido)
```

---

## Casos Especiales

### Paquetes grandes (>1000 líneas)

Los paquetes PL/SQL de Tronador pueden tener miles de líneas. Dos desarrolladores PUEDEN trabajar en el mismo paquete si modifican procedimientos/funciones distintos. En ese caso:

- Verificar qué procedimiento/función específico toca la otra rama
- Si son procedimientos distintos → 🟡 proceder con precaución, hacer cambios puntuales
- Si es el mismo procedimiento → 🔴 colisión confirmada

### Archivos nuevos

Si el cambio es crear un archivo nuevo (nueva función, nuevo grant, nuevo índice), la verificación de colisiones no aplica para Git. Pero SÍ verificar en Jira y Oracle que nadie más esté creando el mismo objeto.

### Múltiples objetos

Si el cambio afecta varios objetos, ejecutar la verificación para CADA uno. Basta con que uno tenga colisión para alertar.

---

## Integración con el Flujo de Atención

En el flujo de `atencion-incidente-autonomo.md`, la detección de colisiones se ejecuta **cuando el diagnóstico identifica que se necesita modificar código** (entre Fase 1 y la implementación). No se ejecuta durante el diagnóstico puro (solo lectura).

Secuencia:
1. Diagnóstico identifica causa raíz → "hay que modificar PCK_FACTURA_ELECTRONICA"
2. **Detección de colisiones** sobre PCK_FACTURA_ELECTRONICA
3. Si 🟢 → Análisis de impacto → Implementación
4. Si 🟡 → Informar al usuario → Esperar decisión
5. Si 🔴 → Detener → Coordinar con el otro desarrollador
