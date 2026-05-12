---
inclusion: auto
---

# Sinónimos y Grants para Nuevos Objetos de BD

> **Alcance:** Esta regla aplica exclusivamente para el repositorio `tronador-oracle-db` (base de datos Oracle de Tronador, esquema OPS$PUMA). No aplica para repositorios de microservicios, aplicaciones Java/Spring Boot ni otros proyectos.

## Regla

Cada vez que se crea un **nuevo componente** en el esquema `OPS$PUMA` (package, tabla, secuencia, tipo, función, procedimiento, vista), se deben generar **obligatoriamente** dos scripts adicionales:

1. **Sinónimo público** en `Base Datos/Sinonimos/SYN_CRX_<HU>_1.sql`
2. **Grants** en `Base Datos/Grants/GRANT_CRX_<HU>_1.sql`

Donde `<HU>` es el identificador de la historia (ej: `GD1129-593`).

Estos scripts deben incluirse en el orden de ejecución del `pull_request.md`, **después** de compilar el objeto nuevo.

## Roles por Defecto (Genéricos - Todos los Canales)

Cuando el desarrollo es **transversal** (aplica a todos los canales), usar el conjunto completo de roles:

```sql
-- Para packages, tipos, funciones, procedimientos:
GRANT EXECUTE ON OPS$PUMA.<OBJETO> TO C_COMUNES, ROLE_USR_FINAL_TRON, ROLE_USR_PROCEDATOS, SIMONWEBAPP, USUARIOS_TRON, ROL_USR_ESTABILIZACION;

-- Para tablas:
GRANT SELECT, INSERT, UPDATE, DELETE ON OPS$PUMA.<TABLA> TO C_COMUNES, ROLE_USR_FINAL_TRON, ROLE_USR_PROCEDATOS, SIMONWEBAPP, USUARIOS_TRON, ROL_USR_ESTABILIZACION;

-- Para secuencias:
GRANT SELECT ON OPS$PUMA.<SECUENCIA> TO C_COMUNES, ROLE_USR_FINAL_TRON, ROLE_USR_PROCEDATOS, SIMONWEBAPP, USUARIOS_TRON, ROL_USR_ESTABILIZACION;
```

## Roles por Canal Específico

Si el desarrollo es para un **canal específico**, otorgar grants **solo** al rol correspondiente. No es necesario incluir todos los roles genéricos. Preguntar al desarrollador qué canal aplica y ajustar los grants en consecuencia.

## Formato del Sinónimo

```sql
CREATE OR REPLACE PUBLIC SYNONYM <OBJETO> FOR OPS$PUMA.<OBJETO>;
/
```

## Referencia

Ver ejemplos completos en:
- `Base Datos/Sinonimos/SYN_CRX_GD1129-154_1.sql`
- `Base Datos/Grants/GRANT_CRX_GD1129-154_1.sql`

## Aplica a Componentes Nuevos Únicamente

No es necesario crear sinónimos ni grants para objetos que ya existen en la BD (recompilaciones o modificaciones). Solo aplica cuando el objeto **no existe previamente** en `OPS$PUMA`.
