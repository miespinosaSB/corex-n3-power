---
inclusion: auto
---

# Análisis de Impacto - Regla Obligatoria

## Regla General

**ANTES de sugerir cualquier cambio en código PL/SQL, paquetes, procedimientos, funciones o triggers, SIEMPRE se debe realizar un análisis de impacto.**

⚠️ **Prerequisito:** Antes de este análisis, ejecutar la **detección de colisiones** (steering `deteccion-colisiones.md`) para verificar que ningún otro desarrollador esté trabajando en el mismo objeto. Solo proceder con el análisis de impacto si la detección da 🟢 o el usuario autoriza en caso de 🟡.

## Procedimiento Obligatorio

### 1. Identificar el objeto a modificar
- Nombre del paquete/procedimiento/función/trigger
- Esquema al que pertenece

### 2. Buscar referencias y dependencias

Usar el tool `get_dependencies` del MCP oracle-readonly:

```
get_dependencies(object_name="NOMBRE_OBJETO", direction="both")
```

Esto retorna automáticamente:
- `uses`: qué objetos usa el objeto (dependencias directas)
- `used_by`: quién usa este objeto (dependencias inversas)

### 3. Leer el código fuente del objeto

Usar `get_source` para entender qué hace el objeto antes de modificarlo:

```
get_source(object_name="NOMBRE_OBJETO", object_type="PACKAGE BODY")
get_source(object_name="NOMBRE_OBJETO", object_type="PACKAGE")  # especificación
```

### 4. Buscar objetos relacionados por nombre

Si se necesita encontrar objetos con nombres similares o del mismo módulo:

```
search_objects(pattern="NOMBRE_PARCIAL")
```

### 5. Buscar en el repositorio local
Buscar en los archivos del repositorio (`Base Datos/`) referencias al objeto:
- Packages (`.pkb`, `.pks`)
- Procedimientos (`.prc`)
- Funciones (`.fnc`)
- Triggers (`.trg`)

### 6. Evaluar impacto
Para cada referencia encontrada:
- ¿El cambio afecta la firma (parámetros de entrada/salida)?
- ¿El cambio afecta el comportamiento de retorno?
- ¿El cambio afecta datos que otros procesos leen?
- ¿Hay triggers en las tablas afectadas?

### 7. Documentar antes de proceder
Presentar al usuario un resumen de impacto:

```
## Análisis de Impacto - [OBJETO]

### Objeto a modificar
- Nombre: [nombre]
- Tipo: [package/procedure/function/trigger]
- Esquema: [esquema]

### Dependencias encontradas
| Objeto | Tipo | Esquema | Impacto |
|--------|------|---------|---------|
| ... | ... | ... | Alto/Medio/Bajo |

### Tablas afectadas
| Tabla | Operación | Triggers asociados |
|-------|-----------|-------------------|
| ... | SELECT/INSERT/UPDATE/DELETE | ... |

### Riesgo
- [ ] Cambio de firma → requiere actualizar dependencias
- [ ] Cambio de comportamiento → requiere pruebas de regresión
- [ ] Tablas con triggers → verificar efectos cascada
- [ ] Procesos batch afectados → coordinar ventana de despliegue

### Recomendación
[Proceder / Proceder con precaución / No proceder sin revisión adicional]
```

## Reglas Adicionales

- **NUNCA** modificar un paquete sin verificar primero sus dependencias
- Si el objeto tiene más de 5 dependencias directas, marcar como **alto riesgo**
- Si el cambio afecta tablas con triggers (especialmente A2000030 con 18 triggers), documentar TODOS los triggers
- Siempre verificar si hay jobs (`Base Datos/Jobs/`) que ejecutan el objeto
- Consultar la Base de Conocimiento en Confluence (ID: 1677787138) para patrones conocidos

## Consultas Útiles para Análisis

```sql
-- Triggers de una tabla
SELECT trigger_name, trigger_type, triggering_event, status
FROM all_triggers
WHERE table_name = :TABLA
AND owner = 'OPS$PUMA'
ORDER BY trigger_name;

-- Objetos inválidos después de un cambio
SELECT owner, object_name, object_type, status
FROM all_objects
WHERE status = 'INVALID'
AND owner = 'OPS$PUMA'
ORDER BY object_type, object_name;

-- Grants sobre un objeto
SELECT grantee, privilege, grantable
FROM all_tab_privs
WHERE table_name = :NOMBRE_OBJETO
AND grantor = 'OPS$PUMA'
ORDER BY grantee;
```
