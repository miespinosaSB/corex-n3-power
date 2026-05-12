---
inclusion: manual
---

# Estándares y Buenas Prácticas — Implementación de APIs con Adaptador V3

> Documento de referencia para el equipo de desarrollo de microservicios Java que consumen procedimientos almacenados Oracle a través del Adaptador V3 de base de datos.
>
> Basado en: JAM-EC001 (Estructura Comunes Java), JAM-MI020 (Manual de Implementación Adaptador V2 y V3), y los steering files del proyecto.

---

## 1. Arquitectura General

El microservicio no se conecta directamente a la base de datos Oracle. En su lugar, consume un **API Gateway** que expone el Adaptador V3, el cual ejecuta procedimientos almacenados vía HTTP.

```
┌──────────────┐     HTTP/JSON      ┌──────────────────┐     JDBC      ┌──────────┐
│  Controller  │ ──────────────────► │  Adaptador V3    │ ────────────► │  Oracle  │
│  (REST API)  │ ◄────────────────── │  (API Gateway)   │ ◄──────────── │  (SP)    │
└──────┬───────┘                     └──────────────────┘               └──────────┘
       │
       ▼
┌──────────────┐
│   Service    │  Lógica de negocio
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  CoreService │  Orquestación de operaciones
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Repository  │  Interfaz del adaptador
│  (Adapter)   │  Mapeo de parámetros y respuestas
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ AdapterV3    │  Cliente HTTP (RestTemplate + OAuth2)
│ Client       │  Serialización JSON, headers, timeout
└──────────────┘
```

### Flujo de una petición

1. El **Controller** recibe el request REST y delega al **Service**.
2. El **Service** (o **CoreService** si es compartido) transforma el request en entidades de dominio.
3. El **Repository (Adapter)** arma el `Map<String, Object>` de parámetros y llama al `DatabaseAdapterV3Client`.
4. El **Client** construye el body JSON (`owner`, `package`, `procedure`, `parameters`), obtiene token OAuth2, envía la petición HTTP POST y parsea la respuesta.
5. El **Repository** mapea la respuesta (`op_resultado`, `op_arre_errores`, etc.) a DTOs de salida.
6. El **Service** evalúa el resultado y construye el Response o lanza `BolivarBusinessException`.

---

## 2. Estructura de Capas y Paquetes

```
com.bolivar.{dominio}/
├── commons/
│   ├── adapter/
│   │   ├── ExpedientePolizaAdapterRepository.java      # Interfaz del repositorio
│   │   └── AdapterV3ExpedientePolizaRepository.java    # Implementación con Adaptador V3
│   ├── dto/
│   │   ├── CrearExpGenericaOutputDto.java               # DTO de salida del SP
│   │   ├── ValidarDatosPolizaOutputDto.java
│   │   ├── PersistirDatosPolizaOutputDto.java
│   │   └── database/
│   │       ├── ExpGenerica.java                         # Entidad de BD
│   │       └── Proceso.java
│   ├── models/
│   │   ├── CrearExpGenericaRequest.java                 # Request compartido
│   │   ├── CrearExpGenericaResponse.java                # Response compartido
│   │   └── ...
│   └── services/
│       ├── ExpedientePolizaCoreService.java             # Interfaz del servicio core
│       └── impl/
│           └── ExpedientePolizaCoreServiceImpl.java     # Implementación
├── config/
│   └── adapter/
│       ├── DatabaseAdapterV3Client.java                 # Cliente HTTP del Adaptador V3
│       ├── DatabaseAdapterV3Config.java                 # @Configuration + @Bean
│       └── DatabaseAdapterV3Properties.java             # @ConfigurationProperties
├── {funcionalidad}/
│   ├── controller/
│   ├── services/
│   └── models/
└── utils/
    └── ConstantsUtil.java                               # Constantes de parámetros Oracle
```

### Reglas de paquetes

| Capa | Paquete | Responsabilidad |
|---|---|---|
| Controller | `{funcionalidad}.controller` | Recibir HTTP, validar `@Valid`, delegar al Service |
| Service | `{funcionalidad}.services` + `impl/` | Lógica de negocio específica de la operación |
| Core Service | `commons.services` + `impl/` | Lógica reutilizable entre operaciones |
| Repository | `commons.adapter` | Interfaz + implementación de acceso al Adaptador V3 |
| Client | `config.adapter` | Cliente HTTP, OAuth2, serialización |
| DTOs | `commons.dto` | Objetos de transferencia entre capas internas |
| Models | `commons.models` o `{funcionalidad}.models` | Request/Response de la API REST |
| Config | `config.adapter` | Properties y beans de configuración |

---

## 3. Componentes del Adaptador V3

### 3.1 DatabaseAdapterV3Properties

Clase anotada con `@ConfigurationProperties(prefix = "app.adapter.v3")` que centraliza toda la configuración.

**Propiedades obligatorias:**

| Propiedad | Descripción | Ejemplo |
|---|---|---|
| `base-url` | URL del API Gateway | `https://xxx.execute-api.us-east-1.amazonaws.com/dev` |
| `adapter-path` | Path del endpoint V3 | `/api/v3/database/adapter` |
| `ejecutor` | Recurso del ejecutor | `ejecutor_tronador` |
| `client-id` | Client ID OAuth2 | Variable de entorno `ADAPTER_CLIENT_ID` |
| `client-secret` | Client Secret OAuth2 | Variable de entorno `ADAPTER_CLIENT_SECRET` |
| `owner` | Esquema Oracle | `OPS$PUMA` |
| `channel` | Cabecera obligatoria V3 | `gestion-polizas-ms` |
| `channel-operation` | Cabecera obligatoria V3 | `expedicion-poliza` |
| `timeout-seconds` | Timeout HTTP en segundos | `30` |

**Propiedades por procedimiento:**

Cada SP debe tener su `package` y `procedure` configurados como propiedades. Esto permite cambiarlos por ambiente sin recompilar.

```yaml
app:
  adapter:
    v3:
      base-url: ${ADAPTER_URL}
      client-id: ${ADAPTER_CLIENT_ID}
      client-secret: ${ADAPTER_CLIENT_SECRET}
      owner: OPS$PUMA
      channel: ${ADAPTER_CHANNEL:mi-microservicio}
      channel-operation: ${ADAPTER_CHANNEL_OPERATION:mi-operacion}
      timeout-seconds: 30
      date-format: yyyy-MM-dd
      # Propiedades específicas del SP
      package-poblar: CRX_PCK_PERSISTENCIA_DATOS
      procedure-poblar: PR_POBLAR_CRX_EXP_GENERICA
```

**Buenas prácticas:**

- Usar variables de entorno (`${VAR:default}`) para valores sensibles y que cambian por ambiente.
- Agrupar propiedades de flujos alternativos con `@NestedConfigurationProperty` (e.g. `cotizacion`).
- Documentar cada propiedad con Javadoc.

### 3.2 DatabaseAdapterV3Client

Cliente HTTP que encapsula la comunicación con el Adaptador V3.

**Responsabilidades:**
- Obtener y cachear token OAuth2.
- Construir el body JSON con la estructura requerida por V3.
- Enviar headers obligatorios (`channel`, `channel_operation`, `Authorization`).
- Parsear la respuesta y normalizar claves a lowercase.
- Lanzar `BolivarBusinessException` ante errores de comunicación o parseo.

**Estructura del request al Adaptador V3:**

```json
{
  "owner": "OPS$PUMA",
  "package": "CRX_PCK_PROCESO_EMISION",
  "procedure": "SP_VALIDAR_DATOS_POLIZA",
  "parameters": {
    "ip_nr_unc": "12345"
  }
}
```

**Headers obligatorios:**

```
Authorization: Bearer {token}
Content-Type: application/json
channel: gestion-polizas-ms
channel_operation: expedicion-poliza
```

**Buenas prácticas:**

- No instanciar `RestTemplate` manualmente en cada llamada; usar el que se crea en el constructor con timeout configurado.
- El token OAuth2 se cachea con margen de 60 segundos antes de expirar.
- Las claves de la respuesta se normalizan a lowercase para evitar problemas de case-sensitivity.

### 3.3 DatabaseAdapterV3Config

Clase `@Configuration` que registra el `DatabaseAdapterV3Client` como bean de Spring.

```java
@Configuration
@EnableConfigurationProperties(DatabaseAdapterV3Properties.class)
public class DatabaseAdapterV3Config {

    @Bean
    public DatabaseAdapterV3Client databaseAdapterV3Client(
            DatabaseAdapterV3Properties properties,
            ObjectMapper objectMapper) {
        return new DatabaseAdapterV3Client(properties, objectMapper);
    }
}
```

---

## 4. Implementación del Repository (Adapter)

### 4.1 Interfaz

Definir un contrato claro en `commons/adapter/`:

```java
public interface MiAdapterRepository {

    void callProcedureMiOperacion(String parametro, MiOutputDto output)
            throws JsonProcessingException;
}
```

**Convenciones:**
- Prefijo `callProcedure` + nombre del SP.
- Recibir un DTO de salida mutable donde se mapea la respuesta.
- Declarar `throws JsonProcessingException` si hay serialización JSON.

### 4.2 Implementación

```java
@Repository
@Log4j2
public class AdapterV3MiRepository implements MiAdapterRepository {

    private final DatabaseAdapterV3Client adapterClient;
    private final DatabaseAdapterV3Properties properties;

    public AdapterV3MiRepository(DatabaseAdapterV3Client adapterClient,
                                  DatabaseAdapterV3Properties properties) {
        this.adapterClient = adapterClient;
        this.properties = properties;
    }

    @Override
    public void callProcedureMiOperacion(String parametro, MiOutputDto output)
            throws JsonProcessingException {
        // 1. Armar parámetros de entrada
        Map<String, Object> parameters = new HashMap<>();
        parameters.put(IP_MI_PARAMETRO, parametro);

        // 2. Ejecutar el SP vía el cliente
        Map<String, Object> response = adapterClient.executeProcedure(
                properties.getMiPackage(),
                properties.getMiProcedure(),
                parameters
        );

        // 3. Mapear la respuesta al DTO de salida
        mapResponse(response, output);
    }

    private void mapResponse(Map<String, Object> response, MiOutputDto output) {
        output.setOpResultado(getInteger(response, OP_RESULTADO));
        output.setOpArreErrores(parseErrores(response));
    }
}
```

**Buenas prácticas:**

| Práctica | Descripción |
|---|---|
| Anotar con `@Repository` | Para que Spring lo detecte y lo inyecte |
| Inyección por constructor | No usar `@Autowired` en campos |
| Nombres de parámetros como constantes | Usar `ConstantsUtil.IP_MI_PARAMETRO` |
| Package y procedure desde Properties | No hardcodear nombres de SP |
| Métodos privados de mapeo | Separar la lógica de parseo de la respuesta |
| Logging con `@Log4j2` | Registrar contexto en caso de error |

### 4.3 Mapeo de respuestas

La respuesta del Adaptador V3 es un `Map<String, Object>` con las claves normalizadas a lowercase.

**Parámetros de salida comunes:**

| Clave | Tipo | Descripción |
|---|---|---|
| `op_resultado` / `op_rsltd` | Integer | 0 = éxito, otro = error |
| `op_nr_unc` | String | Número UNC generado |
| `op_arre_errores` / `iop_arrrrrs` | List<Map> | Colección de errores |
| `op_num_secu_pol` | BigDecimal | Número secuencial de póliza |

**Manejo de claves alternativas:**

El adaptador puede retornar claves con nombres ligeramente diferentes. Usar métodos helper que prueben múltiples claves:

```java
private Integer getInteger(Map<String, Object> map, String... keys) {
    for (String key : keys) {
        Object val = map.get(key);
        if (val != null) {
            if (val instanceof Number number) return number.intValue();
            try { return Integer.parseInt(val.toString()); }
            catch (NumberFormatException e) { /* continuar */ }
        }
    }
    return null;
}
```

### 4.4 Mapeo de errores

Los errores del SP vienen como `List<Map<String, Object>>` y se transforman a `List<ExceptionDetailModel>`:

```java
private ExceptionDetailModel fromErrorMap(Map<String, Object> m) {
    return ExceptionDetailModel.builder()
            .codigo(getStringFirstNonBlank(m, "ID_ERROR", "id_error"))
            .descripcion(getStringFirstNonBlank(m, "DESC_ERROR", "desc_error"))
            .build();
}
```

### 4.5 Envío de colecciones (tipos TAB de Oracle)

Para enviar `CRX_TYP_EXP_GENERICA_TAB` u otros tipos colección, convertir la lista de entidades a `List<Map<String, Object>>`:

```java
private Object toRegistrosJson(List<MiEntidad> registros) {
    if (registros == null || registros.isEmpty()) {
        return new ArrayList<>();
    }
    return registros.stream()
            .map(this::entidadToMap)
            .collect(Collectors.toList());
}
```

**Formato de fechas:** Usar el formato configurado en `properties.getDateFormat()` (por defecto `yyyy-MM-dd`) para evitar errores `ORA-01830`.

---

## 5. Implementación del Core Service

El Core Service orquesta las llamadas al Repository y transforma los resultados en Responses de la API.

### Patrón estándar

```java
@Service
public class MiCoreServiceImpl implements MiCoreService {

    private final MiAdapterRepository repository;

    @Override
    public MiResponse ejecutar(MiRequest request) {
        MiOutputDto output = MiOutputDto.builder().build();

        try {
            repository.callProcedureMiOperacion(request.getParametro(), output);
        } catch (Exception e) {
            if (e instanceof BolivarBusinessException) throw (BolivarBusinessException) e;
            throw BolivarBusinessException.builder()
                    .categoria(TipoErrorEnum.TECNICO)
                    .codigo("ET01")
                    .mensaje("Error técnico. Póngase en contacto con el administrador")
                    .errores(List.of(ExceptionDetailModel.builder()
                            .descripcion(e.getMessage()).build()))
                    .build();
        }

        Integer resultado = output.getOpResultado() != null ? output.getOpResultado() : -1;
        List<ExceptionDetailModel> errores = output.getOpArreErrores() != null
                ? output.getOpArreErrores() : List.of();

        // Evaluar resultado
        if (resultado != 0 && !errores.isEmpty()) {
            throw BolivarBusinessException.builder()
                    .categoria(TipoErrorEnum.NEGOCIO)
                    .codigo("ET01")
                    .mensaje("Error de negocio en la operación")
                    .errores(errores)
                    .build();
        }

        return MiResponse.builder()
                .exito(resultado == 0)
                .resultado(resultado)
                .errores(errores.isEmpty() ? null : errores)
                .build();
    }
}
```

### Reglas de manejo de errores

| Condición | Acción |
|---|---|
| `resultado == 0` | Operación exitosa, construir Response |
| `resultado != 0` con errores | Lanzar `BolivarBusinessException` con `TipoErrorEnum.NEGOCIO` |
| `resultado != 0` sin errores | Lanzar `BolivarBusinessException` con `TipoErrorEnum.TECNICO` |
| Excepción inesperada | Re-lanzar si es `BolivarBusinessException`, sino envolver en una nueva |

---

## 6. DTOs de Salida

Los DTOs de salida son objetos mutables que el Repository llena con los datos de la respuesta del SP.

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MiOutputDto {
    private Integer opResultado;
    private String opNrUnc;
    private List<ExceptionDetailModel> opArreErrores;
}
```

**Convenciones:**
- Prefijo `op` para parámetros de salida del SP.
- Usar `@Builder` para facilitar la creación en tests.
- Inicializar listas vacías en el builder para evitar NPE.

---

## 7. Constantes

Centralizar todos los nombres de parámetros Oracle en `ConstantsUtil`:

```java
public final class ConstantsUtil {
    private ConstantsUtil() {}

    // Parámetros de entrada
    public static final String IP_NR_UNC = "ip_nr_unc";
    public static final String IP_DTS_SLCTD = "ip_dts_slctd";

    // Parámetros de salida
    public static final String OP_RESULTADO = "op_resultado";
    public static final String OP_NR_UNC = "op_nr_unc";
    public static final String OP_ARRE_ERRORES = "op_arre_errores";

    // Claves de error
    public static final String ID_ERROR = "ID_ERROR";
    public static final String DESC_ERROR = "DESC_ERROR";
}
```

**Reglas:**
- Todo literal que se use más de 2 veces debe ser constante.
- Usar `static final` y nombres en `UPPER_SNAKE_CASE`.
- Agrupar por categoría (entrada, salida, errores, paquetes).

---

## 8. Configuración por Ambiente

### application.yml

```yaml
app:
  adapter:
    v3:
      base-url: ${ADAPTER_URL:https://default-dev-url}
      client-id: ${ADAPTER_CLIENT_ID:default-client-id}
      client-secret: ${ADAPTER_CLIENT_SECRET:default-secret}
      owner: OPS$PUMA
      channel: ${ADAPTER_CHANNEL:mi-microservicio}
      channel-operation: ${ADAPTER_CHANNEL_OPERATION:mi-operacion}
      timeout-seconds: 30
      date-format: yyyy-MM-dd
```

**Buenas prácticas:**
- Valores sensibles siempre como variables de entorno.
- Valores por defecto solo para desarrollo local.
- No commitear secrets reales en el repositorio.
- Deshabilitar `management.health.db.enabled` cuando se usa Adaptador V3 (no hay conexión directa a BD).

---

## 9. Testing del Adaptador

### 9.1 Test del Repository

```java
class AdapterV3MiRepositoryTest {

    @Mock private DatabaseAdapterV3Client adapterClient;
    @Mock private DatabaseAdapterV3Properties properties;

    private AdapterV3MiRepository repository;

    @BeforeEach
    void init() {
        MockitoAnnotations.openMocks(this);
        repository = new AdapterV3MiRepository(adapterClient, properties);
        when(properties.getMiPackage()).thenReturn("MI_PAQUETE");
        when(properties.getMiProcedure()).thenReturn("MI_PROCEDIMIENTO");
    }

    @Test
    void shouldCallProcedureWithCorrectParameters() throws Exception {
        // Arrange
        Map<String, Object> response = new HashMap<>();
        response.put("op_resultado", 0);
        response.put("op_arre_errores", Collections.emptyList());
        when(adapterClient.executeProcedure(anyString(), anyString(), anyMap()))
                .thenReturn(response);

        MiOutputDto output = MiOutputDto.builder()
                .opArreErrores(new ArrayList<>()).build();

        // Act
        repository.callProcedureMiOperacion("12345", output);

        // Assert
        assertEquals(0, output.getOpResultado());

        ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
        verify(adapterClient).executeProcedure(
                eq("MI_PAQUETE"), eq("MI_PROCEDIMIENTO"), captor.capture());
        assertEquals("12345", captor.getValue().get("ip_nr_unc"));
    }
}
```

### 9.2 Test del Core Service

```java
class MiCoreServiceImplTest {

    @Mock private MiAdapterRepository repository;
    private MiCoreServiceImpl service;

    @BeforeEach
    void init() {
        MockitoAnnotations.openMocks(this);
        service = new MiCoreServiceImpl(repository);
    }

    @Test
    void shouldReturnSuccessWhenResultadoIsZero() throws Exception {
        // Arrange: configurar mock del repository con doAnswer
        doAnswer(invocation -> {
            MiOutputDto output = invocation.getArgument(1);
            output.setOpResultado(0);
            output.setOpArreErrores(Collections.emptyList());
            return null;
        }).when(repository).callProcedureMiOperacion(anyString(), any());

        // Act
        MiResponse response = service.ejecutar(new MiRequest("12345"));

        // Assert
        assertTrue(response.isExito());
        assertEquals(0, response.getResultado());
    }

    @Test
    void shouldThrowBusinessExceptionWhenResultadoIsNotZero() throws Exception {
        doAnswer(invocation -> {
            MiOutputDto output = invocation.getArgument(1);
            output.setOpResultado(1);
            output.setOpArreErrores(List.of(
                    ExceptionDetailModel.builder()
                            .codigo("E01").descripcion("Error de prueba").build()));
            return null;
        }).when(repository).callProcedureMiOperacion(anyString(), any());

        assertThrows(BolivarBusinessException.class,
                () -> service.ejecutar(new MiRequest("12345")));
    }
}
```

### 9.3 Convenciones de testing

- Usar `@Mock` + `MockitoAnnotations.openMocks(this)` (no `@SpringBootTest` para tests unitarios).
- Usar `ArgumentCaptor` para verificar parámetros enviados al adaptador.
- Usar `doAnswer` para simular el llenado del DTO de salida por el repository.
- Nombrar tests: `should{Comportamiento}When{Condición}`.
- Extraer constantes para valores repetidos en tests.

---

## 10. Checklist para Nueva Operación con Adaptador

- [ ] Definir el SP Oracle: package, procedure, parámetros de entrada y salida.
- [ ] Agregar constantes de parámetros en `ConstantsUtil`.
- [ ] Agregar propiedades del SP en `DatabaseAdapterV3Properties` y `application.yml`.
- [ ] Agregar método en la interfaz del Repository (`ExpedientePolizaAdapterRepository`).
- [ ] Implementar el método en `AdapterV3ExpedientePolizaRepository`:
  - Armar `Map<String, Object>` de parámetros.
  - Llamar a `adapterClient.executeProcedure(...)`.
  - Mapear respuesta al DTO de salida.
- [ ] Crear DTO de salida en `commons/dto/` si es necesario.
- [ ] Agregar método en `ExpedientePolizaCoreService` (interfaz + implementación).
- [ ] Crear Service de la operación (interfaz + implementación).
- [ ] Crear Controller con anotaciones Swagger.
- [ ] Crear Request/Response en `models/`.
- [ ] Escribir tests unitarios (Repository, CoreService, Service, Controller).
- [ ] Crear `README.md` del módulo.
- [ ] Actualizar `README.md` principal.
