---
name: corex-adapter-v3
description: Generación y mantenimiento de microservicios Java/Spring Boot 3 con Adaptador V3 de base de datos. Usar cuando el usuario pide crear microservicio, nuevo endpoint, scaffold, exponer un SP como servicio REST, o trabajar con el adapter de Oracle.
---

# Adapter V3 — Microservicios Corex

## Qué es el Adaptador V3

API Gateway que permite a microservicios Java/Spring Boot 3 ejecutar procedimientos almacenados Oracle vía HTTP/JSON con autenticación OAuth2. El microservicio NO se conecta directamente a Oracle.

```
Controller → Service → CoreService → Repository (Adapter) → DatabaseAdapterV3Client → API Gateway → Oracle SP
```

## Stack Tecnológico

| Tecnología | Versión |
|---|---|
| Java | 17 |
| Spring Boot | 3.2.12 |
| Gradle | 8.12 (via Wrapper) |
| JUnit | 5 |
| springdoc-openapi | 2.3.0 |
| JaCoCo | 0.8.11 |
| Lombok | (BOM Spring Boot) |
| MapStruct | 1.5.5 |

## Reglas críticas Jakarta EE

⚠️ Las librerías internas de Bolívar fueron compiladas contra Spring Boot 2.x (javax.*). Spring Boot 3 usa jakarta.*:

1. **Exclusiones en build.gradle**: Siempre excluir `javax.servlet`, `javax.validation`, `javax.annotation` y `org.springdoc`
2. **@AccessBolivarLogger**: NO usar. Registrar `BolivarLogger` manualmente
3. **ComponentScan**: Excluir `com.bolivar.centralizador.logs.config.*`
4. **management.health.db.enabled=false**: Obligatorio (sin conexión JDBC directa)
5. **SP públicos**: Verificar que el procedimiento esté en la ESPECIFICACIÓN del paquete

## Flujo: Nuevo servicio que expone un SP

1. Identificar el SP Oracle (package, procedure, parámetros IN/OUT) — usar `get_source`
2. Verificar que el SP esté en la ESPECIFICACIÓN del paquete
3. Scaffold del microservicio o agregar endpoint a uno existente
4. Implementar: Repository → CoreService → Service → Controller
5. Tests unitarios con mocks del adapter
6. Documentar en Confluence + crear HU en Jira

## Estructura del proyecto

```
ms-nombre-operacion/
├── build.gradle
├── settings.gradle
├── gradle/wrapper/
├── src/main/java/com/bolivar/corex/operacion/
│   ├── Application.java
│   ├── config/
│   │   ├── BolivarLoggerConfig.java
│   │   └── SwaggerConfig.java
│   ├── controller/
│   │   └── OperacionController.java
│   ├── service/
│   │   ├── OperacionService.java
│   │   └── OperacionCoreService.java
│   ├── repository/
│   │   └── OperacionRepository.java
│   └── dto/
│       ├── request/
│       └── response/
├── src/main/resources/
│   └── application.yml
└── src/test/java/
```

## Testing obligatorio

- Cobertura mínima: 80% en business logic
- Mocks del `DatabaseAdapterV3Client` — nunca llamar al adapter real
- Patrón Given/When/Then
- JaCoCo para reportes de cobertura

## Convenciones de nombres

- Repositorio: `comunes-<dominio>-ms`
- Operaciones: camelCase con verbos infinitivos (`consultarDatos`, `registrarPoliza`)
- API path: `/domain/api/v1/functionality/entity`
