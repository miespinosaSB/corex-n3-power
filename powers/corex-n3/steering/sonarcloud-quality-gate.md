---
inclusion: fileMatch
fileMatchPattern: "**/*.java"
---

# SonarCloud Quality Gate — Reglas para pasar el pipeline

> Se activa al trabajar con archivos Java.
> Estas reglas son obligatorias para que el pipeline no falle en el step de Quality Gate.

## Reglas Críticas (bloquean deploy)

### 1. Literales duplicados (squid:S1192)

Todo string literal que se repita 3 o más veces debe extraerse a una constante.

```java
// ❌ Falla SonarCloud
errores.add("El campo " + nombre + " es obligatorio");
errores.add("El campo " + nombre + " debe ser numérico");
errores.add("El campo " + nombre + " no puede ser nulo");

// ✅ Pasa SonarCloud
private static final String MSG_CAMPO = "El campo ";
errores.add(MSG_CAMPO + nombre + MSG_OBLIGATORIO);
```

**Aplica también en tests.** Los tests son código y Sonar los analiza igual.

```java
// ❌ En test — falla
response.put("op_resultado", 0);  // repetido 3+ veces
response.put("op_resultado", -1);
response.put("op_resultado", 1);

// ✅ En test — pasa
private static final String OP_RESULTADO = "op_resultado";
response.put(OP_RESULTADO, 0);
```

### 2. Complejidad cognitiva (squid:S3776)

Máximo 15 por método. Cada `if`, `else`, `for`, `while`, `catch`, `&&`, `||` suma complejidad.

**Solución:** Extraer bloques a métodos privados con nombre descriptivo.

```java
// ❌ Complejidad 16+
public void validar(Map<String, Object> response) {
    if (response == null || response.isEmpty()) { ... }
    Object resultado = response.get("op_resultado");
    if (resultado == null) resultado = response.get("OP_RESULTADO");
    if (resultado != null) {
        if (resultado instanceof Number) { ... }
        else { try { ... } catch { ... } }
        if (codResultado != 0) {
            Object errores = response.get("op_arrerrores");
            if (errores == null) errores = response.get("OP_ARRERRORES");
            if (errores instanceof List) { ... }
        }
    }
}

// ✅ Complejidad < 15 — métodos auxiliares
public void validar(Map<String, Object> response) {
    verificarResponseNoVacio(response);
    int codResultado = extraerResultado(response);
    if (codResultado != 0) {
        throw buildError(extraerMensaje(response));
    }
}
```

### 3. Cobertura de código nuevo

SonarCloud mide cobertura solo sobre **código nuevo** (líneas agregadas en el PR). Mínimo 80%.

**JaCoCo debe generar el reporte** antes de que Sonar lo lea:
```groovy
test {
    useJUnitPlatform()
    finalizedBy jacocoTestReport
}
```

## Constantes recomendadas para tests

Crear constantes al inicio de cada clase de test para valores que se repiten:

```java
class MiServiceTest {
    private static final String OP_RESULTADO = "op_resultado";
    private static final String OP_SALIDA = "op_salida";
    private static final String ESTADO_VIGENTE = "VIGENTE";
    private static final String CONTENT_TYPE = "Content-Type";
    private static final String APPLICATION_JSON = "application/json";
    private static final long POLIZA_NUM = 1100000164406L;
    private static final String VALID_DOCUMENTO = "74189717";
    // ...
}
```

## Regla de oro

> Si escribes un string literal más de 2 veces en el mismo archivo, extráelo a constante ANTES de hacer commit. Es más rápido hacerlo de una que corregirlo después cuando Sonar falle.
