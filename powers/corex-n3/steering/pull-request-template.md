---
inclusion: manual
---

# Template Pull Request - tronador-oracle-db

> **Alcance:** Este steering file aplica exclusivamente para el repositorio `tronador-oracle-db` (base de datos Oracle de Tronador, esquema OPS$PUMA). No aplica para repositorios de microservicios, aplicaciones Java/Spring Boot ni otros proyectos.

## Cuándo Usar

Cuando el usuario pida generar, crear o actualizar el archivo `pull_request.md` para un desarrollo en el repositorio de base de datos Oracle de Tronador.

## Instrucciones

1. **Analizar la rama actual** con `git branch --show-current` para obtener el identificador de la HU.
2. **Obtener los archivos cambiados** con `git diff --name-only origin/master...HEAD` para listar todos los componentes del desarrollo.
3. **Determinar el orden de ejecución** siguiendo estas reglas de precedencia:
   - Primero: Scripts DDL de tablas y secuencias (`Base Datos/Tablas/`)
   - Segundo: Scripts DML / INSERTs (`Base Datos/Tablas/DML/`)
   - Tercero: Tipos (`Base Datos/Tipos/`)
   - Cuarto: Package specifications (`.pks`) — siempre antes del body
   - Quinto: Package bodies (`.pkb`)
   - Sexto: Funciones (`.fnc`) y procedimientos (`.prc`)
   - Séptimo: Sinónimos (`Base Datos/Sinonimos/`)
   - Octavo: Grants (`Base Datos/Grants/`)
   - Noveno: Jobs (`Base Datos/Jobs/`)
   - Último: Índices (`Base Datos/Indices/`)
4. **Identificar el tipo de cambio** según la descripción de la HU (feature, fix, refactor, etc.).
5. **Verificar si hay script de rollback** en `Base Datos/Rollbacks/`.
6. **Generar el archivo `pull_request.md`** en la raíz del repositorio con el template de abajo.
7. **NO incluir `pull_request.md` en commits ni push** — es un archivo local para usar al crear el PR en GitHub.

## Template

```markdown
| :books: BASE DE DATOS|:book: ESQUEMA|
|:-------------:|:---------------:|
| **TRON**| **OPS$PUMA**|

## Descripción (Obligatorio)

<Descripción clara y concisa del cambio. Qué hace, por qué se hace.>

## **Orden Ejecucion Archivos (Obligatorio)**
<Lista numerada de archivos en el orden correcto de ejecución según las reglas de precedencia.>

## Script de Rolback (Si aplica)
<Ruta al script de rollback, o "N/A" si no aplica.>

## Relación de Historias de Usuarios  (Obligatorio)

- [<ID_HU> - <Título>](https://jirasegurosbolivar.atlassian.net/browse/<ID_HU>)

## Tipos de Cambios
- [ ] **chore**: mejoras en temas de administración/mantenimiento del proyecto (i.e. actualización de dependencias)
- [ ] **feature**: nuevas funcionalidades que serán incluidas en el proyecto. (i.e. visualización de cursos)
- [ ] **refactor:** Refactorización del código en producción
- [ ] **n :** mejoras/reescritura de features existentes, no agrega un cambio grande a lo que actualmente tiene. (i.e. cambiar estados locales usando stateless components conectados a Redux)
- [ ] **fix/hotfix/patch:** corrección de un bug esperado o inesperado (i.e. links rotos)
- [ ] **test:** agregar tests a un feature existente que no cuenta con los mismos (i.e. unit testing del componente de login)
- [ ] **style:** Se aplicó formato, comas y puntos faltantes, etc; Sin cambios en el código.
```

## Notas

- La base de datos siempre es **TRON** y el esquema **OPS$PUMA** para este repositorio.
- El `.pks` (specification) siempre va antes del `.pkb` (body) del mismo paquete.
- Si hay componentes nuevos, verificar que existan los scripts de sinónimos y grants correspondientes (ver steering `sinonimos-grants-nuevos-objetos.md`).
- Marcar con `[x]` solo el tipo de cambio que aplique.
