---
inclusion: manual
---

# Scaffolding de Nuevo Microservicio con Adaptador V3

> Instrucciones para generar un microservicio Java/Spring Boot 3 que consume procedimientos almacenados Oracle a través del Adaptador V3.
> Referencia complementaria: #[[file:docs/estandares-implementacion-adapter-v3.md]] y #[[file:.kiro/steering/new-feature-guide.md]]
> Para publicar librerías compartidas en JFrog Artifactory, ver #[[file:steering/publicacion-librerias-jfrog.md]]

## Variables de Plantilla

Al crear un nuevo microservicio, reemplazar estas variables:

| Variable | Descripción | Ejemplo |
|---|---|---|
| `{nombre-ms}` | Nombre del microservicio con guiones | `factura-electronica-ms` |
| `{nombreMs}` | Nombre camelCase para Spring | `facturaElectronicaMs` |
| `{NombreMs}` | Nombre PascalCase para clases | `FacturaElectronica` |
| `{dominio}` | Paquete base del dominio | `facturaelectronica` |
| `{context-path}` | Context path del servlet | `/factura_electronica` |
| `{descripcion}` | Descripción corta del API | `API de Facturación Electrónica` |
| `{channel}` | Header channel para Adaptador V3 | `factura-electronica-ms` |
| `{channel-operation}` | Header channel_operation | `consulta-ramo` |
| `{contacto-nombre}` | Nombre del responsable | `Nombre Apellido` |
| `{contacto-email}` | Email del responsable | `nombre@segurosbolivar.com` |

## Estructura de Carpetas

```
apis/{nombre-ms}/
├── build.gradle
├── settings.gradle
├── gradle.properties                          # Credenciales Artifactory (NO commitear reales)
├── lombok.config
├── gradlew / gradlew.bat
├── gradle/wrapper/
│   ├── gradle-wrapper.jar
│   └── gradle-wrapper.properties
├── src/main/java/com/bolivar/{dominio}/
│   ├── {NombreMs}Application.java             # @SpringBootApplication
│   ├── commons/
│   │   ├── adapter/
│   │   │   ├── {NombreMs}AdapterRepository.java        # Interfaz
│   │   │   └── AdapterV3{NombreMs}Repository.java      # Implementación
│   │   ├── dto/
│   │   │   └── {Operacion}OutputDto.java
│   │   ├── models/                            # Request/Response compartidos
│   │   └── services/
│   │       ├── {NombreMs}CoreService.java     # Interfaz
│   │       └── impl/
│   │           └── {NombreMs}CoreServiceImpl.java
│   ├── config/
│   │   ├── adapter/
│   │   │   ├── DatabaseAdapterV3Client.java   # Copiar tal cual del template
│   │   │   ├── DatabaseAdapterV3Config.java
│   │   │   └── DatabaseAdapterV3Properties.java
│   │   ├── logs/
│   │   │   └── BolivarLoggerConfig.java
│   │   ├── openapi/
│   │   │   └── OpenApiConfig.java
│   │   └── security/
│   │       └── SecurityHeadersFilter.java
│   ├── utils/
│   │   ├── ConstantsUtil.java
│   │   ├── ParseUtil.java
│   │   └── UtilLog.java
│   └── {funcionalidad}/
│       ├── controller/
│       ├── services/ + impl/
│       ├── models/
│       └── README.md
├── src/main/resources/
│   └── application.yml
└── src/test/java/com/bolivar/{dominio}/
    └── (misma estructura que main)
```


## Archivos de Infraestructura — Plantillas

### settings.gradle

```groovy
rootProject.name = '{nombre-ms}'
```

### gradle.properties

```properties
#Maven Credentials — reemplazar con credenciales reales (NO commitear)
artifactory_user=USUARIO@segurosbolivar.com
artifactory_password=TOKEN_ARTIFACTORY
```

### lombok.config

```
config.stopBubbling = true
lombok.addLombokGeneratedAnnotation = true
```

### build.gradle

```groovy
plugins {
    id 'org.springframework.boot' version '3.2.12'
    id 'io.spring.dependency-management' version '1.1.7'
    id 'java'
    id 'jacoco'
}

group = 'com.bolivar.{dominio}'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = '17'

configurations {
    compileOnly {
        extendsFrom annotationProcessor
    }
}

repositories {
    mavenLocal {
        url "https://segurosbolivar.jfrog.io/artifactory/commons-gradle-centralizador-logs-prod-local/"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    mavenLocal {
        url "https://segurosbolivar.jfrog.io/artifactory/commons-gradle-swagger-documentation-java-prod-local/"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    mavenLocal {
        url "https://segurosbolivar.jfrog.io/artifactory/commons-gradle-error-handling-prod-local/"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    mavenLocal {
        url "https://segurosbolivar.jfrog.io/artifactory/commons-gradle-bolivar-core-error-handling-starter-local/"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    mavenLocal {
        url "https://segurosbolivar.jfrog.io/artifactory/commons-gradle-parameter-store-prod-local/"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    maven {
        url "https://segurosbolivar.jfrog.io/artifactory/jcenter"
        credentials {
            username "${artifactory_user}"
            password "${artifactory_password}"
        }
    }
    mavenCentral()
}

dependencies {
    // Error Handling — exclusiones para compatibilidad Spring Boot 3 / Jakarta EE
    implementation('com.bolivar.error.handling:bolivar-core-error-handling-starter:1.0.1.RELEASE') {
        exclude group: 'javax.servlet'
        exclude group: 'javax.validation'
        exclude group: 'javax.annotation', module: 'javax.annotation-api'
        exclude group: 'org.springdoc'
    }

    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation group: 'com.squareup.okhttp3', name: 'okhttp', version: '4.12.0'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    implementation "org.mapstruct:mapstruct:1.5.5.Final"
    annotationProcessor "org.mapstruct:mapstruct-processor:1.5.5.Final"

    // OpenAPI — springdoc 2.x compatible con Spring Boot 3.2.x
    implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.3.0'

    // Logging
    implementation 'org.apache.logging.log4j:log4j-core'
    implementation 'org.apache.logging.log4j:log4j-api'
    implementation 'org.apache.logging.log4j:log4j-to-slf4j'

    // Centralizador de logs — exclusiones Jakarta EE
    implementation(group: 'com.bolivar.centralizador.logs', name: 'bolivar-centralizador-logs', version: '1.0.0.RELEASE') {
        exclude group: 'javax.servlet'
        exclude group: 'javax.validation'
        exclude group: 'javax.annotation', module: 'javax.annotation-api'
        exclude group: 'org.springdoc'
    }

    // Parameter Store
    implementation 'com.segurosbolivar.utils:commons-gradle-parameter-store-java:1.0.0.RELEASE'

    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'com.squareup.okhttp3:mockwebserver:4.12.0'
    testImplementation 'net.jqwik:jqwik:1.9.2'
    testRuntimeOnly 'com.h2database:h2'
}

dependencyManagement {
    imports {
        mavenBom('com.amazonaws:aws-xray-recorder-sdk-bom:2.18.2')
    }
}

defaultTasks "bootRun"

tasks.withType(JavaCompile) {
    options.compilerArgs = ['-Amapstruct.suppressGeneratorTimestamp=true']
}

test {
    useJUnitPlatform {
        excludeTags 'integration'
    }
    finalizedBy jacocoTestReport
}

jacocoTestReport {
    dependsOn test
    group = "Reporting"
    reports {
        xml.required = true
        csv.required = false
        html.outputLocation = file("${buildDir}/reports/coverage")
        xml.outputLocation = file("${buildDir}/reports/jacoco.xml")
    }
}

jacoco {
    toolVersion = "0.8.11"
}
```


### application.yml

```yaml
server:
  port: 8080
  servlet:
    context-path: /{context-path}
    encoding:
      charset: UTF-8
      enabled: true
      force: true
spring:
  application:
    name: {nombreMs}
  jackson:
    serialization:
      FAIL_ON_EMPTY_BEANS: false

app:
  adapter:
    v3:
      base-url: ${ADAPTER_URL:https://4tldca0v35.execute-api.us-east-1.amazonaws.com/dev}
      adapter-path: /api/v3/database/adapter
      ejecutor: ejecutor_tronador
      client-id: ${ADAPTER_CLIENT_ID}
      client-secret: ${ADAPTER_CLIENT_SECRET}
      owner: OPS$PUMA
      timeout-seconds: 30
      channel: ${ADAPTER_CHANNEL:{channel}}
      channel-operation: ${ADAPTER_CHANNEL_OPERATION:{channel-operation}}
      date-format: yyyy-MM-dd
      # Propiedades específicas del SP — agregar según necesidad:
      # package-mi-operacion: MI_PAQUETE
      # procedure-mi-operacion: MI_PROCEDIMIENTO
  aws:
    region: us-east-1
    prefix: /config
    env_prefix: /${ENV_PREFIX:dev}

management:
  endpoints:
    web:
      exposure:
        include: mappings, health
      base-path: /api/v1/actuator
  health:
    db:
      enabled: false  # Sin conexión directa a BD (usa Adaptador V3)

info:
  status: UP

springdoc:
  api-docs:
    path: /srv-{context-path}-openapi
  swagger-ui:
    path: /swagger-ui.html
```

### {NombreMs}Application.java

```java
package com.bolivar.{dominio};

import com.bolivar.{dominio}.utils.ConstantsUtil;
import com.bolivar.{dominio}.utils.UtilLog;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.FilterType;

import jakarta.annotation.PostConstruct;
import java.text.MessageFormat;
import java.util.TimeZone;

// @AccessBolivarLogger excluido: bolivar-centralizador-logs 1.0.0 referencia
// javax.servlet.Filter, incompatible con Spring Boot 3 / Jakarta EE.
// El bean BolivarLogger se registra manualmente en BolivarLoggerConfig.
@Configuration
@SpringBootApplication
@ComponentScan(
        basePackages = "com.bolivar.{dominio}",
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.REGEX,
                pattern = "com\\.bolivar\\.centralizador\\.logs\\.config\\..*"
        )
)
public class {NombreMs}Application {

    public static void main(String[] args) {
        SpringApplication.run({NombreMs}Application.class, args);
    }

    @PostConstruct
    void started() {
        TimeZone.setDefault(TimeZone.getTimeZone(ConstantsUtil.AMERICA_BOGOTA_ZONE_ID));
        UtilLog.info(MessageFormat.format("[started(...)] - TimeZone: {0}", TimeZone.getDefault()));
    }
}
```

## Clases de Configuración — Copiar tal cual

Las siguientes clases se copian del template cambiando solo el paquete base:

### DatabaseAdapterV3Client.java
Copiar de `gestion-polizas-ms` sin modificaciones (excepto el paquete). Contiene:
- Obtención y cache de token OAuth2
- Construcción del body JSON (owner, package, procedure, parameters)
- Headers obligatorios (channel, channel_operation, Authorization)
- Parseo de respuesta con normalización de claves a lowercase
- Manejo de errores con BolivarBusinessException

### DatabaseAdapterV3Config.java
```java
@Configuration
@EnableConfigurationProperties(DatabaseAdapterV3Properties.class)
public class DatabaseAdapterV3Config {
    @Bean
    public DatabaseAdapterV3Client databaseAdapterV3Client(
            DatabaseAdapterV3Properties properties, ObjectMapper objectMapper) {
        return new DatabaseAdapterV3Client(properties, objectMapper);
    }
}
```

### DatabaseAdapterV3Properties.java
Crear con las propiedades base (baseUrl, adapterPath, ejecutor, clientId, clientSecret, channel, channelOperation, owner, timeoutSeconds, dateFormat) + propiedades específicas de los SPs del nuevo microservicio.

### SecurityHeadersFilter.java
```java
@Component
public class SecurityHeadersFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        // Prevenir MIME-type sniffing
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");
        // Forzar HTTPS en navegadores
        httpResponse.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
        // Prevenir clickjacking
        httpResponse.setHeader("X-Frame-Options", "DENY");
        // Prevenir caching de respuestas sensibles
        httpResponse.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        httpResponse.setHeader("Pragma", "no-cache");
        // Content Security Policy restrictiva para APIs (no sirven HTML)
        httpResponse.setHeader("Content-Security-Policy", "default-src 'none'");
        // No revelar servidor
        httpResponse.setHeader("X-Permitted-Cross-Domain-Policies", "none");
        chain.doFilter(request, response);
    }
}
```

### BolivarLoggerConfig.java
```java
@Configuration
public class BolivarLoggerConfig {
    @Bean
    public BolivarLogger bolivarLogger() {
        return new BolivarLogger();
    }
}
```

### OpenApiConfig.java

**IMPORTANTE:** Solo activar en ambientes no productivos para no exponer la documentación del API en producción.

```java
@Configuration
@Profile({"dev", "stage"})  // NO se activa en producción
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("{descripcion}")
                        .version("1.0.0")
                        .description("API REST — {NombreMs}")
                        .contact(new Contact()
                                .name("{contacto-nombre}")
                                .email("{contacto-email}")))
                .addServersItem(new Server()
                        .url("http://localhost:8080/{context-path}")
                        .description("Local"));
    }
}
```

Adicionalmente, condicionar las rutas de Swagger en `application.yml` por perfil:

```yaml
# En application.yml (se activa solo si OpenApiConfig existe — perfiles dev/stage)
springdoc:
  api-docs:
    path: /srv-{context-path}-openapi
  swagger-ui:
    path: /swagger-ui.html
```

En producción, al no existir el bean `OpenApiConfig`, springdoc no expone endpoints. Para mayor seguridad, agregar en un `application-prod.yml`:

```yaml
springdoc:
  api-docs:
    enabled: false
  swagger-ui:
    enabled: false
```

## Pipeline CI/CD

Agregar entrada en `.github/workflows/pipeline.yaml` o crear un workflow dedicado siguiendo el template de monorepo:

```yaml
name: {NombreMs} Pipeline
on:
  workflow_dispatch:
  push:
    branches: [develop, stage, pre, master]
jobs:
  microservice-pipeline:
    secrets: inherit
    uses: segurosbolivar/devops-actions-microservices-monorepo-templates/.github/workflows/template.yml@test-datadog
    with:
      language_package_manager: "gradle"
      language_version: "17"
```

## WorkflowFile.json — Configuración de Pipeline y Despliegue

El archivo `WorkflowFile.json` va en la **raíz del repositorio** y define cómo el pipeline compila, empaqueta y despliega el microservicio en AWS ECS Fargate.

Al agregar un nuevo microservicio, agregar una entrada en cada sección:

1. `apps.{env}` — Objeto con `name`, `path` y `app` (nombre del JAR).
2. `apigateway.{nombre-ms}` — IDs del API Gateway por ambiente (pedir a DevOps).
3. `swaggerParameters.{env}.{nombre-ms}` — Rutas del NLB con el context-path correcto.
4. `dev/stage/prod.{nombre-ms}` — Configuración ECS (service, ECR, security groups, subnets, task definition).
5. `environments.{env}` — Solo si se necesitan variables de Parameter Store adicionales.

El nombre del JAR en `apps.*.app` se deriva de: `rootProject.name` (settings.gradle) + `-` + `version` (build.gradle) + `.jar`.

### Estructura de cada sección

**`environment`** — Configuración global de build:
- `dockerFileImg`: `java-runtime/v1.0.0-datadog`
- `region`: `us-east-1`
- `imageTag`: `latest`
- `fileApiSpec`: `api_spec.yaml`

**`apps.{env}`** — Cada entrada: `name` (nombre-ms), `path` (apis/nombre-ms), `app` (JAR name).

**`apigateway.{nombre-ms}.{env}`** — `id` (API Gateway ID), `name` ({proyecto}-{env}-api).

**`swaggerParameters.{env}.{nombre-ms}`** — `basePath`, `uri`, `uriopenapi` (con NLB y context-path), `vpc_link`.

**`{env}.{nombre-ms}`** — Configuración ECS Fargate: `serviceName`, `repositoryName`, `repositoryUrl`, `repositoryImage`, `securityGroups`, `subnets`, `assignPublicIp` (ENABLED), `taskDefinition` ({nombre-ms}-family), `launchType` (FARGATE), `taskCount` (2).

**`environments.{env}`** — Variables de Parameter Store: `ENV_PREFIX`, `ADAPTER_URL`, `ADAPTER_CLIENT_ID`, `ADAPTER_CLIENT_SECRET`, `ADAPTER_OWNER`. Path: `/{proyecto}/{env}/variable-name`.

**`repositoryUrl.{env}`** — Repositorio Artifactory por ambiente: `commons-gradle-centralizador-logs-{env}-virtual`.

### Template del WorkflowFile (para nuevo microservicio)

```json
{
    "environment": {
        "dockerFileImg": "java-runtime/v1.0.0-datadog",
        "region": "us-east-1",
        "imageTag": "latest",
        "fileApiSpec": "api_spec.yaml",
        "pathApiSpec": "."
    },
    "apps": {
        "dev": [{ "name": "{nombre-ms}", "path": "apis/{nombre-ms}", "app": "{nombre-ms}-0.0.1-SNAPSHOT.jar" }],
        "stage": [{ "name": "{nombre-ms}", "path": "apis/{nombre-ms}", "app": "{nombre-ms}-0.0.1-SNAPSHOT.jar" }],
        "prod": [{ "name": "{nombre-ms}", "path": "apis/{nombre-ms}", "app": "{nombre-ms}-0.0.1-SNAPSHOT.jar" }]
    },
    "apigateway": {
        "{nombre-ms}": {
            "dev": { "id": "{api-gateway-id-dev}", "name": "{proyecto}-dev-api" },
            "stage": { "id": "{api-gateway-id-stage}", "name": "{proyecto}-stage-api" },
            "prod": { "id": "{api-gateway-id-prod}", "name": "{proyecto}-prod-api" }
        }
    },
    "swaggerParameters": {
        "dev": { "{nombre-ms}": { "basePath": "http://{nlb-dev}/{basePath}", "uri": "http://{nlb-dev}/{context-path}/{proxy}", "uriopenapi": "http://{nlb-dev}/{context-path}", "vpc_link": "{vpc-link-dev}" } },
        "stage": { "{nombre-ms}": { "basePath": "http://{nlb-stage}/{basePath}", "uri": "http://{nlb-stage}/{context-path}/{proxy}", "uriopenapi": "http://{nlb-stage}/{context-path}", "vpc_link": "{vpc-link-stage}" } },
        "prod": { "{nombre-ms}": { "basePath": "http://{nlb-prod}/{basePath}", "uri": "http://{nlb-prod}/{context-path}/{proxy}", "uriopenapi": "http://{nlb-prod}/{context-path}", "vpc_link": "{vpc-link-prod}" } }
    },
    "dev": { "cluster": "{proyecto}-ecs-cluster", "{nombre-ms}": { "serviceName": "{nombre-ms}", "repositoryName": "{nombre-ms}", "repositoryUrl": "https://{account-id-dev}.dkr.ecr.us-east-1.amazonaws.com", "repositoryImage": "{account-id-dev}.dkr.ecr.us-east-1.amazonaws.com/{nombre-ms}", "securityGroups": "{sg-dev}", "subnets": "{subnets-dev}", "assignPublicIp": "ENABLED", "taskDefinition": "{nombre-ms}-family", "launchType": "FARGATE", "taskCount": "2" } },
    "stage": { "cluster": "{proyecto}-ecs-cluster", "{nombre-ms}": { "serviceName": "{nombre-ms}", "repositoryName": "{nombre-ms}", "repositoryUrl": "https://{account-id-stage}.dkr.ecr.us-east-1.amazonaws.com", "repositoryImage": "{account-id-stage}.dkr.ecr.us-east-1.amazonaws.com/{nombre-ms}", "securityGroups": "{sg-stage}", "subnets": "{subnets-stage}", "assignPublicIp": "ENABLED", "taskDefinition": "{nombre-ms}-family", "launchType": "FARGATE", "taskCount": "2" } },
    "prod": { "cluster": "{proyecto}-ecs-cluster", "{nombre-ms}": { "serviceName": "{nombre-ms}", "repositoryName": "{nombre-ms}", "repositoryUrl": "https://{account-id-prod}.dkr.ecr.us-east-1.amazonaws.com", "repositoryImage": "{account-id-prod}.dkr.ecr.us-east-1.amazonaws.com/{nombre-ms}", "securityGroups": "{sg-prod}", "subnets": "{subnets-prod}", "assignPublicIp": "ENABLED", "taskDefinition": "{nombre-ms}-family", "launchType": "FARGATE", "taskCount": "2" } },
    "environments": {
        "dev": { "ENV_PREFIX": "/{proyecto}/dev/env-prefix", "ADAPTER_URL": "/{proyecto}/dev/adapter-url", "ADAPTER_CLIENT_ID": "/{proyecto}/dev/adapter-client-id", "ADAPTER_CLIENT_SECRET": "/{proyecto}/dev/adapter-client-secret", "ADAPTER_OWNER": "/{proyecto}/dev/adapter-owner" },
        "stage": { "ENV_PREFIX": "/{proyecto}/stage/env-prefix", "ADAPTER_URL": "/{proyecto}/stage/adapter-url", "ADAPTER_CLIENT_ID": "/{proyecto}/stage/adapter-client-id", "ADAPTER_CLIENT_SECRET": "/{proyecto}/stage/adapter-client-secret", "ADAPTER_OWNER": "/{proyecto}/stage/adapter-owner" },
        "prod": { "ENV_PREFIX": "/{proyecto}/prod/env-prefix", "ADAPTER_URL": "/{proyecto}/prod/adapter-url", "ADAPTER_CLIENT_ID": "/{proyecto}/prod/adapter-client-id", "ADAPTER_CLIENT_SECRET": "/{proyecto}/prod/adapter-client-secret", "ADAPTER_OWNER": "/{proyecto}/prod/adapter-owner" }
    },
    "repositoryUrl": {
        "dev": { "repository_url": "commons-gradle-centralizador-logs-dev-virtual" },
        "stage": { "repository_url": "commons-gradle-centralizador-logs-stage-virtual" },
        "prod": { "repository_url": "commons-gradle-centralizador-logs-prod-virtual" }
    }
}
```

### Variables de infraestructura (pedir a DevOps)

| Variable | Descripción | Ejemplo |
|---|---|---|
| `{proyecto}` | Nombre del proyecto/tribu | `fenix` |
| `{api-gateway-id-*}` | ID del API Gateway por ambiente | `e9j5wa8o3i` |
| `{nlb-*}` | DNS del Network Load Balancer | `fenix-dev-nlb-xxx.elb.us-east-1.amazonaws.com` |
| `{vpc-link-*}` | ID del VPC Link | `3sfb2v` |
| `{account-id-*}` | ID de cuenta AWS | `224193575123` |
| `{sg-*}` | Security Group | `sg-0743955df364470ea` |
| `{subnets-*}` | Subnets (separadas por coma) | `subnet-xxx,subnet-yyy,subnet-zzz` |

Los valores de infraestructura los proporciona el equipo de DevOps.

## Reglas Importantes

1. **Incompatibilidad Jakarta EE**: Las librerías internas de Bolívar (error-handling, centralizador-logs) fueron compiladas contra Spring Boot 2.x (javax.*). Siempre aplicar las exclusiones documentadas en build.gradle.
2. **@AccessBolivarLogger**: NO usar. Registrar BolivarLogger manualmente via BolivarLoggerConfig.
3. **ComponentScan**: Excluir `com.bolivar.centralizador.logs.config.*` con FilterType.REGEX.
4. **management.health.db.enabled=false**: Obligatorio cuando se usa Adaptador V3 (sin conexión directa a BD).
5. **Gradle Wrapper**: Copiar `gradlew`, `gradlew.bat` y `gradle/wrapper/` de un microservicio existente.
6. **SP privados**: Verificar que el procedimiento Oracle esté declarado en la especificación del paquete (no solo en el body). Si es privado, no se puede invocar desde el Adaptador V3.
7. **WorkflowFile.json**: Actualizar en la raíz del repositorio con la configuración del nuevo microservicio en TODAS las secciones.
