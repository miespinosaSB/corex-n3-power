# Decisiones Técnicas — Engram Export

> Exportado: 2026-05-12 | Proyecto: tronador-oracle-db | 65 observaciones totales

## #53 — Política cero suposiciones en diagnóstico — precisión obligatoria

**Tipo:** decision | **Fecha:** 2026-05-12

**What**: Se estableció política de precisión absoluta (cero suposiciones) en el diagnóstico del power corex-n3. Toda afirmación debe estar respaldada por código fuente leído o datos verificados con query. El reporte final ahora exige tabla de evidencia y sección 'No Verificado'.

**Why**: Un diagnóstico incorrecto puede generar cambios innecesarios en producción, afectar pólizas de clientes, o desviar al equipo. El agente tendía a inferir comportamiento por nombres de tablas/columnas sin leer el código.

**Where**: powers/corex-n3/steering/diagnostico-eficiente.md (regla absoluta al inicio), powers/corex-n3/steering/atencion-incidente-autonomo.md (scoring + reporte)

**Learned**: La regla más efectiva es: 'Si no lo leíste en el código fuente o no lo verificaste con una query, NO LO AFIRMES'. Separar claramente VERIFICADO vs NO VERIFICADO en el reporte evita que conclusiones parciales se tomen como definitivas.

---

## #47 — Optimización de steering files para reducir consumo de créditos

**Tipo:** decision | **Fecha:** 2026-05-12

**What**: Se convirtieron 6 steering files globales (rule-tech-stack, rule-tech-libraries, rule-security, rule-code-style, rule-architecture, rule-ai-generated-code) de `inclusion: always` a `inclusion: fileMatch` con patrón `**/*.{java,py,ts,tsx,js,jsx,sql,gradle,xml,toml,yaml,yml,json,tf}`. Se simplificó el steering de Engram para no activarse automáticamente al inicio de cada sesión.

**Why**: Cada mensaje cargaba ~6000 tokens de reglas de código incluso para preguntas simples de soporte N3, consumiendo créditos innecesarios. Engram hacía 2 llamadas MCP al inicio de cada sesión sin necesidad.

**Where**: ~/.kiro/steering/rule-*.md (6 archivos), ~/.kiro/steering/engram-knowledge-sync.md

**Learned**: Los steerings con `inclusion: always` se cargan en CADA turno sin importar el contexto. Para reglas de código que solo aplican al escribir/editar código, `fileMatch` es más eficiente. Impacto estimado: ~60-70% menos tokens en sesiones de soporte.

---

## #28 — Decisión: migrar power a repo dedicado (separar de tronador-oracle-db)

**Tipo:** decision | **Fecha:** 2026-05-12

**What**: Se decidió migrar el power corex-n3 a un repositorio dedicado (separado de tronador-oracle-db). El repo contendrá: el power completo, shared-knowledge de Engram, hooks, scripts, y documentación.

**Why**: Actualmente el power vive en una rama del repo de BD Oracle. Mezcla concerns: PRs de conocimiento/agente se confunden con PRs de código PL/SQL. Un repo dedicado permite versionamiento independiente, onboarding más simple (un solo clone), y shared-knowledge junto al power.

**Where**: Pendiente de crear. Estructura propuesta: powers/corex-n3/ (power), shared-knowledge/ (Engram), .kiro/ (hooks, scripts, metrics).

**Learned**: Los powers de Kiro se instalan desde un directorio local — no importa en qué repo vivan. Moverlo a un repo dedicado no rompe nada, solo cambia el path que se usa en 'Install Power from local directory'. El install.sh y update.sh siguen funcionando igual.

---

## #17 — Bloque D: Estrategias de eficiencia — menos créditos, mejor diagnóstico

**Tipo:** decision | **Fecha:** 2026-05-12

**What**: Se identificaron estrategias para reducir consumo de créditos y mejorar efectividad de diagnóstico.

**Reducción de créditos:**
- Engram-first: buscar diagnósticos previos antes de hacer llamadas MCP
- Cache de KB en Engram: no recargar Confluence cada sesión
- Queries precisas guiadas por KB (no exploratorias)
- Batch de queries con JOINs en vez de múltiples llamadas

**Efectividad:**
- Árboles de decisión por módulo (emisión, recaudo, siniestros)
- Queries pre-armadas por patrón (templates SQL listos)
- Trazado completo obligatorio (ENTRADA → TRANSFORMACIÓN → SALIDA)
- Scoring de confianza con profundización automática si es Baja
- Feedback loop post-diagnóstico

**Learned**: El mayor ahorro de créditos viene de NO repetir trabajo (Engram-first) y de ir directo al punto (queries pre-armadas + árboles de decisión). La efectividad mejora con estructura (flowcharts) y retroalimentación (feedback loop).
