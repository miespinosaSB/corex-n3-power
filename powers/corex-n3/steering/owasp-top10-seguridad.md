---
inclusion: fileMatch
fileMatchPattern: "**/*.java,**/*.gradle,**/*.yml,**/*.yaml,**/*.properties"
---

# OWASP Top 10 (2021) — Reglas de Seguridad para Microservicios Corex

> Referencia: [OWASP Top 10 - 2021](https://owasp.org/Top10/)
> Aplica a: Microservicios Spring Boot 3 + Adaptador V3 + Oracle/PL-SQL + API Gateway

---

## A01 — Broken Access Control (Control de Acceso Roto)

### Reglas obligatorias

1. **Nunca confiar en datos del cliente para autorización.** El API Gateway valida el token JWT, pero el microservicio DEBE validar que el usuario tiene permiso sobre el recurso solicitado.

2. **Principio de mínimo privilegio en endpoints:**
```java
// ✅ Correcto — validar ownership del recurso
@GetMapping("/polizas/{nroPoliza}")
public ResponseEntity<?> getPoliza(@PathVariable String nroPoliza,
                                    @RequestHeader("X-User-Id") String userId) {
    // Verificar que el usuario tiene relación con la póliza
    if (!polizaService.perteneceAlUsuario(nroPoliza, userId)) {
        throw new ForbiddenException("Sin acceso a esta póliza");
    }
    return ResponseEntity.ok(polizaService.consultar(nroPoliza));
}

// ❌ Incorrecto — cualquiera con token válido accede a cualquier póliza
@GetMapping("/polizas/{nroPoliza}")
public ResponseEntity<?> getPoliza(@PathVariable String nroPoliza) {
    return ResponseEntity.ok(polizaService.consultar(nroPoliza));
}
```

3. **Denegar por defecto.** Si un endpoint no tiene regla explícita de acceso, debe estar bloqueado.

4. **No exponer IDs secuenciales predecibles** sin validación de ownership. Preferir UUIDs o validar siempre la relación usuario-recurso.

5. **CORS restrictivo:**
```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of(
        "https://portal.segurosbolivar.com",
        "https://app.segurosbolivar.com"
    ));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowCredentials(true);
    return new UrlBasedCorsConfigurationSource() {{
        registerCorsConfiguration("/**", config);
    }};
}
```

---

## A02 — Cryptographic Failures (Fallos Criptográficos)

### Reglas obligatorias

1. **Nunca loguear datos sensibles:** números de cédula completos, números de tarjeta, passwords, tokens.
```java
// ✅ Correcto — enmascarar
log.info("Consultando póliza para documento: {}****", documento.substring(0, 4));

// ❌ Incorrecto
log.info("Consultando póliza para documento: {}", documento);
```

2. **TLS obligatorio.** Toda comunicación entre servicios debe ser HTTPS. El Adaptador V3 ya usa HTTPS — no cambiar a HTTP.

3. **No almacenar secretos en código ni en application.yml:**
```yaml
# ✅ Correcto — referencia a Parameter Store
adapter:
  client-secret: ${ADAPTER_CLIENT_SECRET}

# ❌ Incorrecto — secreto hardcoded
adapter:
  client-secret: "abc123secreto"
```

4. **Algoritmos seguros.** Si se necesita hashing: BCrypt o Argon2. Si se necesita cifrado: AES-256-GCM. Nunca MD5 ni SHA-1 para seguridad.

---

## A03 — Injection (Inyección)

### Reglas obligatorias

1. **Queries parametrizadas SIEMPRE.** El Adaptador V3 ya parametriza los SPs, pero si se construye SQL dinámico en PL/SQL:
```sql
-- ✅ Correcto — bind variables
OPEN cur FOR 'SELECT * FROM polizas WHERE nr_poliza = :1' USING p_nr_poliza;

-- ❌ Incorrecto — concatenación
OPEN cur FOR 'SELECT * FROM polizas WHERE nr_poliza = ' || p_nr_poliza;
```

2. **Validar inputs en el controller ANTES de enviar al Adaptador V3:**
```java
// ✅ Correcto — validación con Bean Validation
public record ConsultaPolizaRequest(
    @NotBlank @Size(max = 20) @Pattern(regexp = "^[0-9]+$") String nroPoliza,
    @NotBlank @Size(max = 15) @Pattern(regexp = "^[0-9]+$") String nroDocumento
) {}

// ❌ Incorrecto — sin validación, pasa directo al SP
public record ConsultaPolizaRequest(String nroPoliza, String nroDocumento) {}
```

3. **No construir JSON dinámico con concatenación de strings:**
```java
// ✅ Correcto — usar ObjectMapper
ObjectMapper mapper = new ObjectMapper();
String json = mapper.writeValueAsString(request);

// ❌ Incorrecto
String json = "{\"poliza\":\"" + nroPoliza + "\"}";
```

4. **Log injection prevention.** Sanitizar valores antes de loguear:
```java
// ✅ Correcto — el placeholder de SLF4J escapa automáticamente
log.info("Poliza consultada: {}", nroPoliza);

// ❌ Incorrecto — concatenación permite inyección de logs
log.info("Poliza consultada: " + userInput);
```

---

## A04 — Insecure Design (Diseño Inseguro)

### Reglas obligatorias

1. **Rate limiting en endpoints públicos.** Configurar en API Gateway:
   - Endpoints de consulta: máx 100 req/min por usuario
   - Endpoints de escritura: máx 20 req/min por usuario

2. **Validar lógica de negocio, no solo formato:**
```java
// ✅ Correcto — validar regla de negocio
if (montoReclamado.compareTo(montoAsegurado) > 0) {
    throw new BusinessException("Monto reclamado excede cobertura");
}

// ❌ Incorrecto — solo validar que no sea null
Objects.requireNonNull(montoReclamado);
```

3. **Timeouts obligatorios** en llamadas al Adaptador V3:
```yaml
adapter:
  timeout-seconds: 30  # Nunca más de 60s
```

4. **Fail securely.** Ante error, no revelar información interna:
```java
// ✅ Correcto — mensaje genérico al cliente
throw new ServiceException("Error procesando solicitud", "ERR-001");

// ❌ Incorrecto — expone stack trace y detalles internos
throw new RuntimeException("ORA-01403: no data found en CB100270.PR_FACTURA");
```

---

## A05 — Security Misconfiguration (Configuración Insegura)

### Reglas obligatorias

1. **Headers de seguridad obligatorios** (ya en SecurityHeadersFilter):
```java
response.setHeader("X-Content-Type-Options", "nosniff");
response.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
response.setHeader("X-Frame-Options", "DENY");
response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
response.setHeader("Content-Security-Policy", "default-src 'none'");
response.setHeader("X-XSS-Protection", "0"); // Deshabilitado — CSP es suficiente
```

2. **Deshabilitar endpoints de debug en producción:**
```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    env:
      enabled: false
    beans:
      enabled: false
    configprops:
      enabled: false
```

3. **No exponer versiones de tecnología:**
```yaml
server:
  server-header: ""  # No revelar servidor
```

4. **Swagger/OpenAPI solo en dev/stage:**
```java
@Configuration
@Profile({"dev", "stage"})
public class OpenApiConfig {
    // Solo se activa en ambientes no productivos
}
```

5. **Dependencias actualizadas.** Ejecutar `./gradlew dependencyUpdates` periódicamente. Priorizar actualizaciones de seguridad.

---

## A06 — Vulnerable and Outdated Components (Componentes Vulnerables)

### Reglas obligatorias

1. **Versiones fijas en build.gradle** — nunca rangos dinámicos:
```groovy
// ✅ Correcto
implementation 'com.fasterxml.jackson.core:jackson-databind:2.17.0'

// ❌ Incorrecto
implementation 'com.fasterxml.jackson.core:jackson-databind:2.+'
```

2. **Excluir dependencias transitivas innecesarias** que amplían la superficie de ataque:
```groovy
implementation('com.bolivar.error.handling:bolivar-core-error-handling-starter:1.0.1.RELEASE') {
    exclude group: 'javax.servlet'
    exclude group: 'javax.validation'
}
```

3. **No usar librerías abandonadas.** Si una dependencia no tiene commits en >2 años, buscar alternativa.

4. **Spring Boot BOM como base.** Usar la versión de Spring Boot para gestionar versiones transitivas:
```groovy
plugins {
    id 'org.springframework.boot' version '3.3.0'
    id 'io.spring.dependency-management' version '1.1.5'
}
```

---

## A07 — Identification and Authentication Failures (Fallos de Autenticación)

### Reglas obligatorias

1. **El microservicio NO implementa autenticación directamente.** El API Gateway valida el JWT. El microservicio solo valida headers propagados:
```java
// Validar que el header de identidad existe y es coherente
@RequestHeader("X-User-Id") String userId  // Propagado por API Gateway
```

2. **Nunca aceptar tokens en query params:**
```
❌ GET /api/polizas?token=eyJhbGciOi...
✅ Authorization: Bearer eyJhbGciOi...  (header)
```

3. **Credenciales del Adaptador V3** (clientId/clientSecret) deben rotar cada 90 días. Almacenar en Parameter Store, nunca en código.

4. **Service-to-service auth.** Si un microservicio llama a otro, usar mTLS o token de servicio — nunca credenciales de usuario.

---

## A08 — Software and Data Integrity Failures (Fallos de Integridad)

### Reglas obligatorias

1. **Verificar integridad de dependencias:**
```groovy
// Habilitar verificación de checksums en Gradle
dependencyVerification {
    verify()
}
```

2. **No deserializar objetos de fuentes no confiables** sin validación:
```java
// ✅ Correcto — ObjectMapper con restricciones
ObjectMapper mapper = new ObjectMapper();
mapper.activateDefaultTyping(
    mapper.getPolymorphicTypeValidator(),
    ObjectMapper.DefaultTyping.NON_FINAL
);

// ❌ Incorrecto — deserialización sin restricciones
ObjectMapper mapper = new ObjectMapper();
mapper.enableDefaultTyping(); // VULNERABLE a gadget chains
```

3. **CI/CD seguro.** Los pipelines de GitHub Actions deben:
   - Usar versiones fijas de actions (no `@main`)
   - No exponer secretos en logs
   - Validar que el artefacto desplegado es el mismo que pasó los tests

4. **No aceptar JSON con campos extra sin validación:**
```java
// ✅ Correcto — rechazar propiedades desconocidas
@JsonIgnoreProperties(ignoreUnknown = false)
public record EmisionRequest(...) {}

// O a nivel global:
mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, true);
```

---

## A09 — Security Logging and Monitoring Failures (Fallos de Monitoreo)

### Reglas obligatorias

1. **Loguear eventos de seguridad:**
   - Intentos de acceso denegado (403)
   - Validaciones de input fallidas (400)
   - Errores de autenticación (401)
   - Operaciones sensibles (crear/modificar pólizas, pagos)

2. **Formato estructurado para logs de seguridad:**
```java
log.warn("ACCESS_DENIED | user={} | resource={} | action={} | ip={}",
    userId, recurso, accion, request.getRemoteAddr());
```

3. **No loguear datos sensibles** (ver A02). Los logs van a Datadog — cualquier dato sensible queda expuesto al equipo de observabilidad.

4. **Alertas obligatorias:**
   - >10 errores 403 del mismo usuario en 5 min → alerta
   - >50 errores 400 en 1 min → posible ataque → alerta
   - Cualquier error 500 → alerta

---

## A10 — Server-Side Request Forgery (SSRF)

### Reglas obligatorias

1. **No construir URLs con input del usuario:**
```java
// ✅ Correcto — URL fija, solo parámetros validados
String url = adapterBaseUrl + "/api/v3/execute";  // Base fija de config

// ❌ Incorrecto — URL construida con input
String url = request.getParameter("callbackUrl");
restTemplate.getForObject(url, String.class);  // SSRF!
```

2. **Whitelist de destinos permitidos.** El microservicio solo debe comunicarse con:
   - Adaptador V3 (URL fija en Parameter Store)
   - Otros microservicios internos (por service discovery)
   - API Gateway (para callbacks)

3. **No permitir redirecciones automáticas** en RestTemplate/WebClient:
```java
// ✅ Correcto — deshabilitar redirects
RestTemplate restTemplate = new RestTemplate(
    new SimpleClientHttpRequestFactory() {{
        setFollowRedirects(false);
    }}
);
```

4. **Validar respuestas del Adaptador V3.** Si el SP retorna una URL (ej: para descarga de documentos), validar que pertenece al dominio corporativo antes de usarla.

---

## Checklist Rápido para Code Review

| # | Verificación | Categoría |
|---|---|---|
| 1 | ¿Los endpoints validan ownership del recurso? | A01 |
| 2 | ¿Se enmascaran datos sensibles en logs? | A02 |
| 3 | ¿Los inputs tienen @Valid + @Pattern? | A03 |
| 4 | ¿Hay timeouts configurados? | A04 |
| 5 | ¿Los headers de seguridad están presentes? | A05 |
| 6 | ¿Las dependencias tienen versión fija? | A06 |
| 7 | ¿Los secretos están en Parameter Store? | A07 |
| 8 | ¿Se rechazan propiedades JSON desconocidas? | A08 |
| 9 | ¿Se loguean eventos de seguridad? | A09 |
| 10 | ¿Las URLs de destino son fijas/whitelisted? | A10 |

---

## Aplicación en PL/SQL (Oracle Tronador)

Para código PL/SQL en el esquema OPS$PUMA:

1. **Bind variables siempre** — nunca concatenar inputs en SQL dinámico
2. **GRANT mínimo** — los nuevos objetos solo reciben EXECUTE al usuario de servicio, nunca a PUBLIC
3. **No exponer datos sensibles en excepciones** — usar RAISE_APPLICATION_ERROR con mensajes genéricos
4. **Validar parámetros de entrada** al inicio del procedimiento:
```sql
IF p_nr_poliza IS NULL OR LENGTH(p_nr_poliza) > 20 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Parámetro inválido');
END IF;
```
5. **Auditar operaciones DML sensibles** — INSERT/UPDATE/DELETE en tablas financieras deben registrar quién, cuándo y qué cambió
