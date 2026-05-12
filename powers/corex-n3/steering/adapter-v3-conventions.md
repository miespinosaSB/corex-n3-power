---
inclusion: fileMatch
fileMatchPattern: "**/*.java,**/*.gradle"
---

# Convenciones Obligatorias — Microservicios con Adaptador V3

> Reglas críticas que SIEMPRE deben cumplirse al generar o modificar código en microservicios que usan el Adaptador V3 de base de datos.

## Incompatibilidades Jakarta EE (Spring Boot 3)

Las librerías internas de Bolívar fueron compiladas contra Spring Boot 2.x (javax.*). Spring Boot 3 usa jakarta.*. Las siguientes exclusiones son OBLIGATORIAS en `build.gradle`:

```groovy
// bolivar-core-error-handling-starter — SIEMPRE excluir:
implementation('com.bolivar.error.handling:bolivar-core-error-handling-starter:1.0.1.RELEASE') {
    exclude group: 'javax.servlet'
    exclude group: 'javax.validation'
    exclude group: 'javax.annotation', module: 'javax.annotation-api'
    exclude group: 'org.springdoc'
}

// bolivar-centralizador-logs — SIEMPRE excluir:
implementation(group: 'com.bolivar.centralizador.logs', name: 'bolivar-centralizador-logs', version: '1.0.0.RELEASE') {
    exclude group: 'javax.servlet'
    exclude group: 'javax.validation'
    exclude group: 'javax.annotation', module: 'javax.annotation-api'
    exclude group: 'org.springdoc'
}
```

## @AccessBolivarLogger — NO USAR

La anotación `@AccessBolivarLogger` activa `CentralizadorLogsConfig` que referencia `javax.servlet.Filter`. Esto causa `ClassNotFoundException` en Spring Boot 3.

En su lugar:
1. Excluir el auto-config con `@ComponentScan` + `FilterType.REGEX`:
```java
@ComponentScan(
    basePackages = "com.bolivar.{dominio}",
    excludeFilters = @ComponentScan.Filter(
        type = FilterType.REGEX,
        pattern = "com\\.bolivar\\.centralizador\\.logs\\.config\\..*"
    )
)
```
2. Registrar `BolivarLogger` manualmente:
```java
@Configuration
public class BolivarLoggerConfig {
    @Bean
    public BolivarLogger bolivarLogger() { return new BolivarLogger(); }
}
```

## Health Check de Base de Datos — DESHABILITAR

El microservicio NO tiene conexión JDBC directa. Siempre incluir en `application.yml`:

```yaml
management:
  health:
    db:
      enabled: false
```

## Adaptador V3 — Reglas de Implementación

### Parámetros del SP
- Nombres de parámetros Oracle SIEMPRE como constantes en `ConstantsUtil` (e.g. `IP_COD_CIA`, `OP_RESULTADO`).
- Package y procedure SIEMPRE desde `DatabaseAdapterV3Properties`, NUNCA hardcodeados.

### Mapeo de Respuestas
- Las claves de la respuesta del Adaptador V3 se normalizan a lowercase automáticamente.
- Usar métodos helper que prueben múltiples claves alternativas (e.g. `op_resultado` / `op_rsltd`).
- Formato de fechas: usar `properties.getDateFormat()` (default `yyyy-MM-dd`) para evitar `ORA-01830`.

### Manejo de Errores
- `resultado == 0` → Éxito.
- `resultado != 0` con errores → `BolivarBusinessException` con `TipoErrorEnum.NEGOCIO`.
- `resultado != 0` sin errores → `BolivarBusinessException` con `TipoErrorEnum.TECNICO`.
- Excepción inesperada → Re-lanzar si es `BolivarBusinessException`, sino envolver en una nueva.

### Inyección de Dependencias
- SIEMPRE inyección por constructor. NUNCA `@Autowired` en campos.

### Procedimientos Almacenados
- Verificar que el SP esté declarado en la ESPECIFICACIÓN del paquete Oracle (no solo en el body). Los procedimientos privados NO se pueden invocar desde el Adaptador V3.

## OpenAPI / Swagger
- Usar `springdoc-openapi-starter-webmvc-ui:2.3.0` (compatible con Spring Boot 3.2.x).
- NO usar `commons-gradle-swagger-documentation-java` (incompatible con Spring Boot 3).
- Configurar con `OpenApiConfig.java` nativo de springdoc 2.x.

## Zona Horaria
- Establecer `America/Bogota` en `@PostConstruct` de la clase Application para consistencia con Oracle.
