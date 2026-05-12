---
inclusion: fileMatch
fileMatchPattern: "**/adapter-v3*,**/AdapterV3*,**/config/adapter/**,**/CoreService*"
---

# Testing Obligatorio — Microservicios con Adapter V3

> Se activa solo en proyectos que usan Adapter V3 (microservicios nuevos).
> NO aplica para proyectos legacy sin Adapter V3.

## Regla Principal

⚠️ **OBLIGATORIO:** Al crear o modificar cualquier clase Java con lógica de negocio en un microservicio con Adapter V3, se DEBE crear o actualizar la prueba unitaria correspondiente **en el mismo commit**.

No se permite hacer commit de código nuevo sin tests. El Quality Gate de SonarCloud bloqueará el deploy.

## Qué clases DEBEN tener test

| Capa | Patrón | Test obligatorio |
|---|---|---|
| Controller | `*Controller.java` | Sí — mock del service |
| Service impl | `*ServiceImpl.java` | Sí — mock del repository y converter |
| Repository | `*Repository.java` | Sí — MockWebServer para simular adapter |
| Validator | `*Validator.java` | Sí — casos válidos e inválidos |
| Converter | `*Converter.java` | Sí — mapeo de datos |
| Utils con lógica | `*Util.java` | Sí — si tiene lógica, no si son solo constantes |

## Qué clases NO necesitan test

| Capa | Patrón | Razón |
|---|---|---|
| DTOs | `*Dto.java`, `*DTO.java` | Solo getters/setters (Lombok) |
| Models | `*Response.java`, `*Request.java` | Solo estructura de datos |
| Config | `*Config.java`, `*Properties.java` | Configuración de Spring |
| Interfaces | `*Service.java` (sin impl) | Sin lógica |
| Constantes | `Constants*.java` | Solo valores estáticos |

## Reglas de SonarCloud

Estas reglas causan fallo del Quality Gate si no se cumplen:

1. **Literales duplicados:** Todo string que se repita 3+ veces debe ser constante `private static final`
2. **Complejidad cognitiva:** Máximo 15 por método. Extraer métodos auxiliares si se excede
3. **Cobertura mínima:** 80% en código nuevo (excluye DTOs, config, models)

## Checklist antes de commit

- [ ] Toda clase con lógica tiene su `*Test.java` correspondiente
- [ ] Tests siguen patrón `should{Comportamiento}When{Condición}`
- [ ] Constantes para literales repetidos (en código Y en tests)
- [ ] Complejidad cognitiva < 15 en todos los métodos
- [ ] Tests corren con `./gradlew test --tests 'paquete.del.modulo.*'`
