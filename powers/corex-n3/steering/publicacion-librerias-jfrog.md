---
inclusion: manual
---

# Publicación de Librerías Gradle en JFrog

Guía completa para publicar librerías Java/Gradle en JFrog Artifactory usando el pipeline de DevOps (`devops-actions-library-templates`).

## Prerrequisitos

- Repositorio creado en GitHub (`segurosbolivar/<nombre-repo>`)
- Repositorio JFrog creado por DevOps (ej: `commons-gradle-<equipo>-dev-local`)
- Pipeline configurado con el template de librerías

## Estructura Obligatoria del Proyecto

El template de DevOps **requiere un proyecto single-module** (no multi-módulo). El jar debe generarse en `build/libs/` de la raíz.

```
mi-libreria/
├── .github/workflows/pipeline.yml
├── build.gradle.kts          ← Plugin artifactory + maven-publish
├── settings.gradle.kts       ← rootProject.name = "nombre-artefacto"
├── gradle/wrapper/
│   ├── gradle-wrapper.jar
│   └── gradle-wrapper.properties
├── gradlew
├── gradlew.bat
├── pom.xml                   ← DUMMY (solo para que el template lea la versión)
├── package.json              ← DUMMY (solo para que el template lea el nombre)
├── WorkflowFile.json
├── sonar-project.properties
├── src/
│   ├── main/java/...
│   ├── main/resources/.gitkeep   ← Obligatorio (template copia .env aquí)
│   └── test/java/...
└── CHANGELOG.md
```

⚠️ **NO usar estructura multi-módulo** — el template no la soporta.

## Archivos de Configuración

### pipeline.yml

```yaml
name: "Library Template"
run-name: ${{ github.event_name == 'pull_request' && format('Analysing PR {0} <- {1}', github.base_ref, github.head_ref) || ((github.event_name == 'push' && startsWith(github.ref, 'refs/heads/v') && endsWith(github.ref, '-release')) && format('Analysing branch {0}', github.ref_name) || format('Deploying version {0}', github.ref_name)) }}

on:
  workflow_dispatch:
  pull_request:
    branches: [develop, stage, pre, master]
    types: [opened, synchronize, reopened, edited]
  push:
    branches:
      - 'v[0-9]+.[0-9]+.[0-9]+-release+'
      - 'master'

permissions:
  contents: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  main:
    secrets: inherit
    uses: segurosbolivar/devops-actions-library-templates/.github/workflows/template.yml@v2.0.0-branch
    with:
      language_package_manager: "gradle"
      language_version: "21"
      framework_version: "8.10"  # ← Versión de Gradle (sin esto provisiona 6.9)
```

### build.gradle.kts

```kotlin
plugins {
    `java-library`
    `maven-publish`
    id("io.spring.dependency-management") version "1.1.6"
    id("jacoco")
    id("com.jfrog.artifactory") version "5.2.5"  // ← OBLIGATORIO
}

group = "com.segurosbolivar.simon.ventas"
version = "X.Y.Z"  // Sin -SNAPSHOT para releases

// ... (java toolchain, dependencies, etc.)

publishing {
    publications {
        create<MavenPublication>("library") {
            groupId = "com.segurosbolivar.simon.ventas"
            artifactId = "nombre-artefacto"
            version = project.version.toString()
            from(components["java"])
        }
    }
}

artifactory {
    setContextUrl(findProperty("artifactory_url")?.toString() ?: "https://segurosbolivar.jfrog.io/artifactory")
    publish {
        repository {
            setRepoKey(findProperty("repository_url")?.toString() ?: "commons-gradle-simon-ventas-dev-local")
            setUsername(findProperty("artifactory_user")?.toString() ?: "")
            setPassword(findProperty("artifactory_password")?.toString() ?: "")
        }
        defaults {
            publications("library")
            setPublishArtifacts(true)
            setPublishPom(true)
        }
    }
}
```

### WorkflowFile.json

```json
{
  "environment": {
    "release_path": "build/libs/<artifactId>-<version>.jar"
  },
  "repository_url_upload": "commons-gradle-<equipo>-dev-local"
}
```

⚠️ La key para publicación es `repository_url_upload` (no `repositoryUrl`).

### pom.xml (DUMMY — solo para el template)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Este pom.xml existe SOLO para que el template de DevOps lea la versión.
     El build real usa Gradle. NO usar Maven para compilar. -->
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.segurosbolivar.simon.ventas</groupId>
    <artifactId>nombre-artefacto</artifactId>
    <version>X.Y.Z</version>
    <name>nombre-artefacto</name>
</project>
```

### package.json (DUMMY — solo para el template)

```json
{
  "name": "nombre-artefacto",
  "version": "X.Y.Z",
  "private": true
}
```

### settings.gradle.kts

```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

rootProject.name = "nombre-artefacto"
```

## Flujo de Publicación

```
1. Desarrollar en rama v<MAJOR>.<MINOR>.<PATCH>-release
2. Push → pipeline de VALIDACIÓN (automático)
   - Build ✓
   - Unit Tests ✓
   - Static Analysis (Sonar) ✓
   - Upload artifact a GitHub ✓
3. Lanzar pipeline de PUBLICACIÓN (manual desde GitHub Actions → workflow_dispatch)
   - Ejecuta: ./gradlew artifactoryPublish -Partifactory_user=... -Partifactory_password=... -Partifactory_url=... -Prepository_url=...
   - Publica jar + pom en JFrog
```

## Versionamiento

- Cada versión nueva requiere una **rama nueva**: `v1.0.0-release`, `v1.1.0-release`, `v1.2.0-release`
- El template valida que la versión sea **mayor** que el último tag existente
- NO usar `-SNAPSHOT` en la versión para releases publicados
- Actualizar la versión en **3 archivos**: `build.gradle.kts`, `pom.xml`, `package.json`

## Consumir la Librería desde un BFF

En el `build.gradle.kts` del consumidor:

```kotlin
repositories {
    mavenLocal()  // Fallback para desarrollo local
    mavenCentral()
    maven {
        name = "jfrog-simon-ventas"
        url = uri("https://segurosbolivar.jfrog.io/artifactory/${System.getenv("JFROG_REPO_URL") ?: "commons-gradle-simon-ventas-dev-local"}")
        credentials {
            username = System.getenv("JFROG_USER") ?: ""
            password = System.getenv("JFROG_PASSWORD") ?: ""
        }
    }
}

dependencies {
    implementation("com.segurosbolivar.simon.ventas:nombre-artefacto:X.Y.Z")
}
```

Para desarrollo local (sin JFrog):
```bash
# En el repo de la librería:
./gradlew publishToMavenLocal

# En el BFF: compila normalmente (resuelve desde ~/.m2/repository)
./gradlew compileJava
```

## Gotchas y Problemas Conocidos

| Problema | Causa | Solución |
|---|---|---|
| `Task 'artifactoryPublish' not found` | Falta plugin `com.jfrog.artifactory` | Agregar al `build.gradle.kts` |
| 401 en publish (pipeline) | El composite action inyecta `JFROG_TOKEN` (Bearer), no user/password | Usar `HttpHeaderCredentials` con `Bearer $token` en vez de `credentials { username; password }` |
| 401 en publish (local) | Credenciales locales incorrectas en gradle.properties | Verificar `artifactoryUser` y `artifactoryPassword` en gradle.properties |
| `LIBRARY_NAME` vacío | Bug del template: no lee nombre para Gradle | Agregar `package.json` dummy |
| `cp: cannot create .env` | Falta `src/main/resources/` | Crear directorio con `.gitkeep` |
| `Version not greater than latest` | Tag de versión anterior ya existe | Crear rama con versión mayor |
| `Provision Gradle 6.9` (incompatible Java 21) | Falta `framework_version` en pipeline.yml | Agregar `framework_version: "8.10"` en `with:` del pipeline |
| Repo npm en vez de gradle | `repository_url_upload` incorrecto | Corregir en WorkflowFile.json |
| Pipeline no se dispara | Referencia `@v2.0.0` no existe o job skipped | Usar `@v2.0.0-branch` |

### Detalle: Autenticación en Pipeline vs Local

El composite action de DevOps inyecta un **access token** (`JFROG_TOKEN`), NO user/password separados. El `build.gradle.kts` debe soportar ambos modos:

```kotlin
// En el bloque artifactory → publish → repository:
// Pipeline: usa Bearer token vía -Partifactory_password=<token>
// Local: usa user/password desde gradle.properties
setUsername(findProperty("artifactory_user")?.toString() ?: "")
setPassword(findProperty("artifactory_password")?.toString() ?: "")
```

⚠️ `language_version` en el pipeline es para **Java**, no Gradle. Para especificar la versión de Gradle se usa `framework_version`:

## Desarrollo Local (gradle.properties)

Crear `gradle.properties` en la raíz (debe estar en `.gitignore`):

```properties
repositoryUrl=commons-gradle-simon-ventas-dev-local
artifactoryUser=tu.email@segurosbolivar.com
artifactoryPassword=tu-token-jfrog
```

## Referencia: Repos JFrog del Equipo

| Ambiente | Repo |
|---|---|
| Dev | `commons-gradle-simon-ventas-dev-local` |
| Stage | `commons-gradle-simon-ventas-stage-local` |
| Prod | `commons-gradle-simon-ventas-prod-local` |

## Checklist para Nueva Librería

- [ ] Crear repo en GitHub
- [ ] Solicitar a DevOps la creación del repo en JFrog
- [ ] Estructura single-module con `src/` en raíz
- [ ] Plugin `com.jfrog.artifactory` en build.gradle.kts
- [ ] Bloque `artifactory {}` con properties correctas
- [ ] `pom.xml` dummy con nombre y versión
- [ ] `package.json` dummy con nombre y versión
- [ ] `src/main/resources/.gitkeep`
- [ ] `WorkflowFile.json` con `release_path` y `repository_url_upload`
- [ ] `pipeline.yml` con template `@v2.0.0-branch`
- [ ] `gradle.properties` en `.gitignore`
- [ ] Crear rama `v1.0.0-release` y pushear
- [ ] Verificar pipeline de validación pasa
- [ ] Lanzar pipeline de publicación manualmente
- [ ] Verificar artefacto en JFrog
