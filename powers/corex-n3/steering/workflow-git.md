# Workflow de Git - Tribu Corex

## Repositorio
- **URL:** https://github.com/segurosbolivar/tronador-oracle-db.git
- **Rama base:** `master`
- **PR destino:** `dev`

## Crear rama para un fix

```bash
# Siempre partir de master actualizado
git checkout master
git pull origin master

# Crear rama con nombre del Jira principal (NUNCA subtarea)
git checkout -b GD986-XXXX
```

Ejemplo: `git checkout -b GD986-1254`

## Convenciones de commits

```
GD986-XXXX: Descripción corta del cambio

Ejemplo:
GD986-1254: Fix cálculo fecha_vto_fact efecto end-of-month ADD_MONTHS
```

## Regla de oro: cambios PUNTUALES

⚠️ **NUNCA reemplazar un archivo .pkb, .pks o .prc completo.**

Los paquetes PL/SQL son archivos de 1,000 a 11,000+ líneas donde múltiples desarrolladores trabajan simultáneamente. Si reemplazás el archivo completo:
- Perdés los cambios de otros compañeros
- Generás conflictos de merge imposibles de resolver
- Rompés el historial de Git

**Correcto:**
```bash
# Editar SOLO las líneas que cambian
# Ejemplo: agregar condición en línea 585 de PROCESO_REPORTE_FACTURACION.pkb
```

**Incorrecto:**
```bash
# Copiar el archivo completo desde SQL Developer y reemplazar
# ❌ NUNCA hacer esto
```

## Estructura de archivos en el repo

```
Base Datos/
├── Funciones/*.fnc          # Funciones standalone
├── Packages/*.pks           # Package specs
├── Packages/*.pkb           # Package bodies
├── Procedimientos/*.prc     # Procedimientos standalone
├── Indices/*.sql            # Índices
├── Jobs/*.sql               # Jobs programados
└── Grants/*.sql             # Permisos
```

## Crear Pull Request

### Opción 1: GitHub Web
1. Ir a https://github.com/segurosbolivar/tronador-oracle-db/pulls
2. "New Pull Request"
3. Base: `dev` ← Compare: `GD986-XXXX`
4. Título: `GD986-XXXX: Descripción`
5. Descripción:
```markdown
## Jira
[GD986-XXXX](https://jirasegurosbolivar.atlassian.net/browse/GD986-XXXX)

## Confluence
[Documentación técnica](URL_CONFLUENCE)

## Cambios
- [Archivo modificado]: descripción del cambio

## Criterios de aceptación
- CA1: ...
- CA2: ...

## Pruebas
- [ ] Prueba unitaria ejecutada
- [ ] Sin regresión en flujo normal
```

### Opción 2: GitHub CLI (si está instalado)
```bash
gh pr create --base dev --title "GD986-XXXX: Descripción" --body "..."
```

## Flujo completo

```
master ──────────────────────────────────────────────
    \                                               
     └── GD986-1254 ── commit1 ── commit2 ── PR → dev
```

## Encoding de archivos

- Archivos `.sql`, `.pks`, `.pkb`, `.fnc`, `.prc`: **ISO-8859-1 (Latin1)**
- Archivos `.md`, `.json`, `.yml`: **UTF-8**

Si tu editor guarda en UTF-8 por defecto, configurar para archivos Oracle:
- VS Code: "files.encoding" por extensión
- Kiro: respetar el encoding existente del archivo
