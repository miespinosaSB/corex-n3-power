---
inclusion: fileMatch
fileMatchPattern: "**/adapter-v3*,**/AdapterV3*,**/adapter_v3*"
---

# Adapter V3 en Monorepo Existente (Spring Boot 2.x)

> Se activa cuando el agente trabaja con archivos que contienen configuración del Adapter V3.
> Aplica cuando se agrega una operación V3 a un monorepo que ya tiene Adapter V1 con Cognito.

## Regla de Decisión

Antes de implementar, verificar:

1. **¿El repo ya tiene `AccessTokenRepository` y `OkHttpClientConfiguration`?**
   - SÍ → Reutilizar la autenticación existente (este steering)
   - NO → Crear config nueva (`scaffolding-microservicio.md`)

2. **¿El repo ya tiene `app.tronador_adapter` en application.yaml?**
   - SÍ → Derivar URL V3 de la V1 existente O crear bloque `adapter-v3` independiente
   - NO → Crear toda la configuración desde cero

## Opción A: Config Independiente (Recomendada)

Crear `AdapterV3Properties` con `@ConfigurationProperties(prefix = "app.adapter-v3")` y su propio bloque en `application.yaml`. NO tocar la config V1 existente.

```yaml
app:
  adapter-v3:
    base-url: ${ADAPTER_V3_URL:https://url-del-adapter/dev}
    adapter-path: /api/v3/database/adapter
    ejecutor: ejecutor_tronador
    client-id: ${ADAPTER_V3_CLIENT_ID:client-id-de-dev}
    client-secret: ${ADAPTER_V3_CLIENT_SECRET:client-secret-de-dev}
    owner: OPS$PUMA
    channel: ${ADAPTER_V3_CHANNEL:nombre-del-microservicio}
    channel-operation: ${ADAPTER_V3_CHANNEL_OPERATION:nombre-operacion}
    timeout-seconds: 30
    package-mi-sp: MI_PAQUETE
    procedure-mi-sp: MI_PROCEDIMIENTO
```

⚠️ **IMPORTANTE:** Los defaults de `client-id` y `client-secret` deben tener valores reales de dev para que funcione sin Parameter Store. Para stage/prod se sobreescriben con variables de entorno.

## Opción B: Reutilizar Config V1

Si no quieres agregar config nueva, derivar la URL V3 de la V1:

```java
@Value("${app.tronador_adapter.urL_nlb_tron_adapter}")
private String urlNlbAdapterV1;

private String buildAdapterV3Url() {
    return urlNlbAdapterV1.replace("/api/v1/database/adapter", "/api/v3/database/adapter");
}
```

## Formato del Body V3

```java
Map<String, Object> body = new LinkedHashMap<>();
body.put("owner", "OPS$PUMA");
body.put("package", "MI_PAQUETE");
body.put("procedure", "MI_PROCEDIMIENTO");
body.put("parameters", parametersMap);  // Map, NO String serializado
```

**Diferencia con V1:** V1 usa `pOwner`/`pPackage`/`pProcedure`/`pParameters` (string). V3 usa `owner`/`package`/`procedure`/`parameters` (objeto).

## Headers Obligatorios V3

```java
.addHeader("Authorization", "Bearer " + token)
.addHeader("channel", "nombre-del-microservicio")
.addHeader("channel_operation", "nombre-de-la-operacion")
.addHeader("Content-Type", "application/json")
```

## Token OAuth2

⚠️ **El endpoint de token espera JSON, NO form-urlencoded.**

```java
// ✅ Correcto — JSON
Map<String, String> tokenParams = new LinkedHashMap<>();
tokenParams.put("grant_type", "client_credentials");
tokenParams.put("client_id", properties.getClientId());
tokenParams.put("client_secret", properties.getClientSecret());
String tokenJson = objectMapper.writeValueAsString(tokenParams);
RequestBody tokenBody = RequestBody.create(tokenJson, JSON_MEDIA_TYPE);

// ❌ Incorrecto — form-urlencoded (causa error 400 en el endpoint de token)
RequestBody tokenBody = new FormBody.Builder()
        .add("grant_type", "client_credentials")
        .build();
```

## Errores Comunes

| Error | Causa | Solución |
|---|---|---|
| 404 del adapter | URL sin `/ejecutor_tronador/` | URL = base-url + `/` + ejecutor + adapter-path |
| 401 Unauthorized | Credenciales vacías en defaults | Poner credenciales reales de dev como defaults |
| 400 en token | Body form-urlencoded | Enviar como JSON |
| Body no reconocido | Formato V1 (`pOwner`) | Usar formato V3 (`owner`) |
| Falta header `channel` | No se agregaron headers V3 | Agregar `channel` y `channel_operation` |
