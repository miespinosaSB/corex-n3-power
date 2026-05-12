---
inclusion: fileMatch
fileMatchPattern: "**/*.java,**/*.gradle"
---

# Reglas de Calidad de Código

## Constantes para valores repetidos

Cualquier valor literal (string, número, etc.) que se repita **más de 2 veces** en un mismo archivo debe ser extraído a una constante (`static final`). Esto aplica tanto a código de producción como a código de pruebas.

### Ejemplo

Incorrecto:
```java
error.put(ID_ERROR, "E01");
assertEquals("E01", result.getCodigo());
validError.put(ID_ERROR, "E01");
assertEquals("E01", otherResult.getCodigo());
```

Correcto:
```java
public static final String ERROR_CODE_E01 = "E01";
// ...
error.put(ID_ERROR, ERROR_CODE_E01);
assertEquals(ERROR_CODE_E01, result.getCodigo());
```

### Excepciones

- Valores que ya son constantes importadas de otra clase (e.g. `ConstantsUtil.OP_RESULTADO`) no necesitan re-declararse.
- Valores `null`, `0`, `1`, `-1`, `Collections.emptyList()` y similares primitivos/utilitarios están exentos.
- Nombres de parámetros en Mockito matchers (`anyString()`, `anyMap()`, etc.) están exentos.
