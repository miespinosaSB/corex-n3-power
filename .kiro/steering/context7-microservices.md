---
inclusion: fileMatch
fileMatchPattern: "**/*.java,**/*.gradle,**/scaffolding*,**/new-feature*"
---

# Context7 — Documentación Actualizada para Microservicios

## Regla Principal

Al generar o modificar código de microservicios con Adaptador V3, consultar Context7 para obtener documentación actualizada de las librerías involucradas. Esto evita hallucinations y asegura que el código generado use APIs vigentes.

## Cuándo consultar Context7

| Situación | Librería a consultar | Query sugerido |
|---|---|---|
| Crear/modificar `build.gradle` | Spring Boot | "Spring Boot 3.2 Gradle dependency management" |
| Implementar Repository (Adapter V3) | Spring WebClient | "WebClient POST request with headers and body" |
| Mapeo de objetos DTO ↔ Entity | MapStruct | "MapStruct mapper interface with custom mapping" |
| Configurar OpenAPI/Swagger | springdoc-openapi | "springdoc-openapi Spring Boot 3 configuration" |
| Escribir tests unitarios | JUnit 5 + Mockito | "JUnit 5 mock WebClient test" |
| Manejo de fechas Oracle | Java Time API | "Java LocalDate parse format pattern" |
| Validación de DTOs | Jakarta Validation | "Jakarta Bean Validation constraints" |
| Health checks / Actuator | Spring Boot Actuator | "Spring Boot 3 actuator custom health indicator" |

## Cómo usar Context7

1. **Resolver el library ID** con `resolve-library-id`:
   ```
   resolve-library-id(libraryName: "Spring Boot", query: "dependency injection configuration")
   ```

2. **Consultar documentación** con `query-docs`:
   ```
   query-docs(libraryId: "/spring-projects/spring-boot", query: "WebClient POST JSON request")
   ```

## Librerías frecuentes del stack Adapter V3

| Librería | Context7 ID probable | Versión en uso |
|---|---|---|
| Spring Boot | /spring-projects/spring-boot | 3.2.12 |
| Spring Framework | /spring-projects/spring-framework | 6.1.x |
| MapStruct | /mapstruct/mapstruct | 1.5.5 |
| Lombok | /projectlombok/lombok | BOM |
| JUnit 5 | /junit-team/junit5 | 5.10.x |
| springdoc-openapi | /springdoc/springdoc-openapi | 2.3.0 |

> **Nota:** Los IDs de Context7 pueden variar. Siempre usar `resolve-library-id` primero para obtener el ID correcto.

## Regla de verificación

Antes de generar código que use una API específica (método, anotación, configuración):
1. Si tienes duda sobre la firma o disponibilidad → consultar Context7
2. Si la versión de la librería cambió recientemente → consultar Context7
3. Si el usuario pide algo que no has visto antes → consultar Context7

**NO consultar Context7 para:**
- Código PL/SQL (usar Oracle MCP directamente)
- Patrones internos de Bolívar (usar la KB de Confluence)
- Configuración de infraestructura (usar steering de DevOps)
