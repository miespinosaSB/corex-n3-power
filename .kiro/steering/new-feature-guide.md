---
inclusion: manual
---

# Guía para Agregar una Nueva Funcionalidad

> Basado en el documento JAM-EC001-Estructura Comunes Java de la Gerencia Middleware de Seguros Bolívar.

## Stack Tecnológico Requerido

| Tecnología | Versión |
|---|---|
| Java | 17 |
| Spring Boot | 3.x |
| Gradle | 8.x |
| JUnit | 5 |

### Librerías Comunes Bolívar

- **Actuator**: Health checks y métricas (`/actuator/health`).
- **Error Handling Starter**: Manejo centralizado de errores con `BolivarBusinessException`.
- **API Doc Starter (Swagger)**: Documentación OpenAPI automática.
- **Parameter Store**: Gestión de configuración desde AWS Parameter Store.
- **MyBatis Bolívar**: Acceso a base de datos Oracle vía procedimientos almacenados.

## Lineamientos Generales

### Idioma

- **Código fuente**: Inglés (nombres de clases, métodos, variables, paquetes).
- **Documentación**: Español (README, Swagger descriptions, comentarios de negocio).
- **Excepción**: Términos de negocio pueden mantenerse en español si no tienen traducción directa clara.

### Versionamiento

- Usar **versionamiento semántico**: `MAJOR.MINOR.PATCH` (e.g. `1.2.3`).
- `MAJOR`: Cambios incompatibles con versiones anteriores.
- `MINOR`: Nueva funcionalidad compatible hacia atrás.
- `PATCH`: Correcciones de bugs.

### Nombramiento de Operaciones

- Las URLs deben seguir el patrón: `/api/v{version}/{recurso}/{operacion}`.
- Usar **sustantivos** para recursos, no verbos.
- Usar **minúsculas** y **guiones** para separar palabras en URLs.
- El verbo HTTP define la acción (GET, POST, PUT, PATCH, DELETE).

## Estructura de Paquetes

### Paquetes Genéricos (commons)

```
com.bolivar.{dominio-negocio}.commons/
├── adapter/          # Implementaciones de acceso a datos
├── dto/              # DTOs y objetos de transferencia
│   └── database/     # Entidades/objetos de base de datos
├── handler/          # Manejadores de excepciones
├── models/           # Modelos compartidos (Request/Response)
├── repository/       # Interfaces de repositorio
└── services/         # Servicios compartidos
    └── impl/         # Implementaciones de servicios compartidos
```

### Paquetes de la Operación (por funcionalidad)

```
com.bolivar.{dominio-negocio}.{nombrefuncionalidad}/
├── controller/
│   └── {NombreFuncionalidad}Controller.java
├── services/
│   ├── {NombreFuncionalidad}Service.java          # Interface
│   └── impl/
│       └── {NombreFuncionalidad}ServiceImpl.java   # Implementación
├── models/
│   └── {NombreFuncionalidad}Request.java           # Request específico (si aplica)
└── README.md                                        # Documentación del módulo
```

## Objetos y Patrones

### Controller

- Anotar con `@RestController` y `@Tag(name = "...", description = "...")`.
- Documentar cada endpoint con `@Operation` y `@ApiResponses`.
- Validar entrada con `@Valid`.
- URL base: `/api/v1/{recurso}/{operacion}`.
- **Un controlador por operación** (no agrupar múltiples operaciones no relacionadas).
- Delegar toda la lógica al Service; el Controller solo orquesta la llamada.

```java
@RestController
@Tag(name = "Mi Funcionalidad", description = "Descripción de la funcionalidad")
public class MiFuncionalidadController {

    private final MiFuncionalidadService service;

    @Operation(summary = "Descripción corta")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Operación exitosa"),
        @ApiResponse(responseCode = "400", description = "Request inválido"),
        @ApiResponse(responseCode = "500", description = "Error interno")
    })
    @PostMapping("/api/v1/recurso/operacion")
    public ResponseEntity<MiResponse> ejecutar(@Valid @RequestBody MiRequest request) {
        return ResponseEntity.ok(service.ejecutar(request));
    }
}
```

### Service

- Definir una **interfaz** y su **implementación** separada en `impl/`.
- Anotar la implementación con `@Service`.
- Manejar errores de negocio con `BolivarBusinessException`.

```java
public interface MiFuncionalidadService {
    MiResponse ejecutar(MiRequest request);
}
```

```java
@Service
@RequiredArgsConstructor
public class MiFuncionalidadServiceImpl implements MiFuncionalidadService {

    private final ExpedientePolizaCoreService coreService;

    @Override
    public MiResponse ejecutar(MiRequest request) {
        // Lógica de negocio
    }
}
```

### Request y Response

- Usar **Lombok** (`@Data`, `@Builder`, `@AllArgsConstructor`, `@NoArgsConstructor`).
- Anotar con `@JsonInclude(JsonInclude.Include.NON_NULL)`.
- Documentar cada campo con `@Schema`.
- Validar campos requeridos con `@NotNull`, `@NotBlank`, etc.
- Usar `@JsonProperty` para mapear nombres JSON.

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class MiFuncionalidadRequest {
    @JsonProperty("campo")
    @NotNull(message = "campo es requerido")
    @Schema(name = "campo", description = "Descripción del campo", required = true)
    private String campo;
}
```

### DTOs (Data Transfer Objects)

- Usar DTOs para mapear datos de/hacia la base de datos.
- Ubicar en `commons/dto/` si son compartidos, o en `commons/dto/database/` si representan entidades de BD.
- **No exponer DTOs de base de datos directamente en el Response**; transformar a modelos de respuesta.

### Repository

- Definir una **interfaz** en `commons/repository/` o `commons/adapter/`.
- Implementar en `commons/adapter/` siguiendo el patrón existente con `DatabaseAdapterV3Client`.
- Agregar constantes de nombres de parámetros en `ConstantsUtil`.

## Verbos HTTP

| Verbo | Uso | Idempotente |
|---|---|---|
| `POST` | Crear recurso o ejecutar operación | No |
| `GET` | Consultar recurso(s) | Sí |
| `PUT` | Reemplazar recurso completo | Sí |
| `PATCH` | Actualizar parcialmente un recurso | No |
| `DELETE` | Eliminar recurso | Sí |

## Pasos para Agregar una Nueva Funcionalidad

### 1. Crear el paquete del módulo

Bajo `com.bolivar.<dominio-negocio>`, crear un paquete con el nombre de la funcionalidad en **minúsculas sin separadores** (e.g. `mifuncionalidad`).

### 2. Crear el modelo Request (si es necesario)

Si el endpoint recibe un body diferente a `CrearExpGenericaRequest`, crear un request específico en `models/` del módulo.

### 3. Crear la interfaz del servicio

En `services/` del módulo.

### 4. Crear la implementación del servicio

En `services/impl/` del módulo. Anotar con `@Service`.

### 5. Crear el controlador

En `controller/` del módulo. Seguir las convenciones de anotaciones descritas arriba.

### 6. Si se necesita un nuevo procedimiento almacenado

1. Agregar el método en `ExpedientePolizaAdapterRepository` (interfaz).
2. Implementar en `AdapterV3ExpedientePolizaRepository` siguiendo el patrón existente.
3. Agregar constantes de nombres de parámetros en `ConstantsUtil`.
4. Si se necesitan propiedades configurables, agregarlas en `DatabaseAdapterV3Properties` y `application.yml`.
5. Agregar el método en `ExpedientePolizaCoreService` y su implementación.

### 7. Crear tests

- **Test del controlador**: Mockear el servicio con `@MockBean`.
- **Test del servicio**: Mockear `ExpedientePolizaCoreService` o el repositorio con `@Mock`.
- **Test del repositorio adapter** (si aplica): Mockear `DatabaseAdapterV3Client` y `DatabaseAdapterV3Properties`.
- Usar **JUnit 5** y **Mockito**.
- Nombrar tests descriptivamente: `should_ReturnSuccess_When_ValidRequest`.

### 8. Crear README.md del módulo

Documentar:
- Descripción de la funcionalidad.
- Endpoint (URL, método HTTP).
- Request/Response de ejemplo.
- Procedimiento Oracle invocado (si aplica).
- Códigos de error específicos.

### 9. Actualizar README.md principal

Agregar la nueva funcionalidad en la sección "Detalle de Funcionalidades" del README raíz.

## Documentación de Repositorios

### README del Microservicio

Debe incluir:
- Nombre y descripción del microservicio.
- Stack tecnológico.
- Listado de funcionalidades/operaciones.
- Instrucciones de ejecución local.
- Variables de entorno requeridas.

### README de cada Operación

Debe incluir:
- Descripción de la operación.
- Endpoint y método HTTP.
- Ejemplo de Request y Response.
- Procedimiento almacenado invocado.
- Tabla de códigos de error.
