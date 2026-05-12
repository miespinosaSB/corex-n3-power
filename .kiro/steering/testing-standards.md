---
inclusion: fileMatch
fileMatchPattern: "**/*.java,**/*.gradle"
---

# Estándares de Testing — gestion-polizas-ms

## Framework y Dependencias

- JUnit 5 (`spring-boot-starter-test`)
- Mockito para mocking
- jqwik para property-based testing
- MockWebServer (OkHttp3) para tests de integración HTTP
- H2 en runtime de test

## Estructura de Tests

Los tests replican la estructura de paquetes del código fuente:

```
src/test/java/com/bolivar/gestionpolizas/
├── commons/adapter/          → AdapterV3ExpedientePolizaRepositoryTest
├── commons/services/impl/    → ExpedientePolizaCoreServiceImplTest
├── config/adapter/           → DatabaseAdapterV3ClientPropertyTest
├── config/security/          → SecurityHeadersFilterPropertyTest
├── {modulo}/controller/      → {Modulo}ControllerTest
├── {modulo}/services/impl/   → {Modulo}ServiceImplTest
└── utils/                    → ConstantsUtilTest, ParseUtilTest, UtilLogTest
```

## Convenciones de Nombres

- Clase de test: `{ClaseBajoTest}Test.java` (e.g. `CrearExpGenericaControllerTest`).
- Property-based tests: `{ClaseBajoTest}PropertyTest.java`.
- Métodos de test: `should{Comportamiento}` o `should{Comportamiento}When{Condicion}` (e.g. `shouldCallProcedurePoblarCrxExpGenerica`, `shouldCallProcedurePoblarCrxExpGenericaWithEmptyList`).

## Patrón de Test

```java
class MiClaseTest {

    @Mock
    private DependenciaA dependenciaA;

    private ClaseBajoTest claseBajoTest;

    @BeforeEach
    void init() {
        MockitoAnnotations.openMocks(this);
        claseBajoTest = new ClaseBajoTest(dependenciaA);
        // Configurar mocks con when(...).thenReturn(...)
    }

    @Test
    void shouldHacerAlgoCuandoCondicion() {
        // Arrange
        // ...

        // Act
        var resultado = claseBajoTest.metodo(parametros);

        // Assert
        assertEquals(esperado, resultado);
        verify(dependenciaA).metodoInvocado(args);
    }
}
```

## Mocking del Adaptador V3

Para tests del repositorio adapter, mockear `DatabaseAdapterV3Client` y `DatabaseAdapterV3Properties`:

```java
@Mock private DatabaseAdapterV3Client adapterClient;
@Mock private DatabaseAdapterV3Properties properties;

@BeforeEach
void init() {
    MockitoAnnotations.openMocks(this);
    repository = new AdapterV3ExpedientePolizaRepository(adapterClient, properties);
    when(properties.getParamRegistrosPoblar()).thenReturn(IP_DTS_SLCTD);
    when(properties.getPackagePoblar()).thenReturn(CRX_PCK_PERSISTENCIA_DATOS);
    // ... demás propiedades
}
```

Simular respuesta del SP:
```java
Map<String, Object> response = new HashMap<>();
response.put(OP_RESULTADO, 0);
response.put(OP_NR_UNC, DEFAULT_NR_UNC);
response.put(OP_ARRE_ERRORES, Collections.emptyList());
when(adapterClient.executeProcedure(anyString(), anyString(), anyMap())).thenReturn(response);
```

## Verificación con ArgumentCaptor

Usar `ArgumentCaptor` para verificar los parámetros enviados al Adaptador V3:

```java
ArgumentCaptor<Map<String, Object>> paramsCaptor = ArgumentCaptor.forClass(Map.class);
verify(adapterClient).executeProcedure(eq(PACKAGE), eq(PROCEDURE), paramsCaptor.capture());
Map<String, Object> captured = paramsCaptor.getValue();
assertTrue(captured.containsKey(IP_DTS_SLCTD));
```

## Ejecución

```bash
./gradlew test
```

- Los tests de integración se excluyen con `excludeTags 'integration'` en la configuración de Gradle.
- JaCoCo genera reporte en `build/reports/jacoco.xml` y HTML en `build/reports/coverage/`.
- Exclusiones de cobertura: `**/src/test/**`, `**/config/**`, `**/handler/**`, `**/GestionPolizasApplication.java`.

## Constantes en Tests

- Reutilizar constantes de `ConstantsUtil` para nombres de parámetros Oracle.
- Declarar constantes específicas del test como `public static final` en la clase de test.
- No repetir literales más de 3 veces sin extraer a constante.
