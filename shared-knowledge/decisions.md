# Decisiones Técnicas — Engram Export

> Exportado: 2026-05-15 | Proyectos: corex-n3-power (9), simon-cotizadores-core-wl (10), tronador-oracle-db (128) | 147 observaciones totales

---

## #131 — REGLA: Producción solo vía MDSB — MCP servers NO son prod

**Tipo:** decision | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** decision/oracle-ambientes-produccion

**What**: Ninguno de los MCP servers de Oracle disponibles (oracle-readonly ni oracle-stage) apunta a producción. oracle-readonly = desarrollo, oracle-stage = pre-producción. Para consultar producción SIEMPRE se debe usar el power corex-n3 con el flujo MDSB (steering consulta-produccion-mdsb.md) que crea un request en Service Desk para el bot AIOps.
**Why**: Se asumió incorrectamente que oracle-readonly era producción, causando confusión. El usuario dejó claro que producción solo se accede vía MDSB.
**Where**: Power corex-n3, MCP servers oracle-readonly y oracle-stage
**Learned**: REGLA ABSOLUTA: Cuando el usuario pida "consultar en producción" → usar el power corex-n3 con el steering consulta-produccion-mdsb.md. NUNCA asumir que oracle-readonly u oracle-stage son producción. Son ambientes de dev y stage respectivamente.

---

## #92 — Opciones de corrección asimetría cobro/devolución exclusión Autos

**Tipo:** decision | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Se analizaron 4 opciones para evitar la diferencia entre cobro periódico y devolución por exclusión en Autos.

**Why**: El caso MDSB-992543 mostró que la asimetría es inherente al diseño (fuentes distintas, períodos distintos, CB100270 solo en devolución). Se necesita decidir qué cambiar.

**Where**: SIM_PCK299_AB100273 (prc_InsNormal), Sim_Pck299_Cb100270, SIM_PCK_ANULACIONENDOSO

**Learned**:
- Opción A (regeneración): Ya aplicada para este caso. Elimina diferencia al 100% pero es manual.
- Opción B (unificar fórmula): Riesgo alto — imp_prima_end incluye gastos expedición que prima_anu no tiene. Puede haber razón contable.
- Opción C (ajustar V_factor): Riesgo medio — devolver solo diferidos cobrados. Necesita validación contable (provisión completa vs incremental).
- Opción D (validación preventiva): Riesgo bajo — detectar inclusión/exclusión mismo día y regenerar automáticamente. Solo cubre ese escenario.
- RECOMENDACIÓN: Fix CEIL (ya hecho) + Opción D para prevenir + escalar pregunta contable sobre imp_prima_end vs prima_anu al área funcional.

---

## #53 — Política cero suposiciones en diagnóstico — precisión obligatoria

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Se estableció política de precisión absoluta (cero suposiciones) en el diagnóstico del power corex-n3. Toda afirmación debe estar respaldada por código fuente leído o datos verificados con query. El reporte final ahora exige tabla de evidencia y sección 'No Verificado'.
**Why**: Un diagnóstico incorrecto puede generar cambios innecesarios en producción, afectar pólizas de clientes, o desviar al equipo. El agente tendía a inferir comportamiento por nombres de tablas/columnas sin leer el código.
**Where**: powers/corex-n3/steering/diagnostico-eficiente.md (regla absoluta al inicio), powers/corex-n3/steering/atencion-incidente-autonomo.md (scoring + reporte)
**Learned**: La regla más efectiva es: 'Si no lo leíste en el código fuente o no lo verificaste con una query, NO LO AFIRMES'. Separar claramente VERIFICADO vs NO VERIFICADO en el reporte evita que conclusiones parciales se tomen como definitivas.

---

## #47 — Optimización de steering files para reducir consumo de créditos

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Se convirtieron 6 steering files globales (rule-tech-stack, rule-tech-libraries, rule-security, rule-code-style, rule-architecture, rule-ai-generated-code) de `inclusion: always` a `inclusion: fileMatch` con patrón `**/*.{java,py,ts,tsx,js,jsx,sql,gradle,xml,toml,yaml,yml,json,tf}`. Se simplificó el steering de Engram para no activarse automáticamente al inicio de cada sesión.
**Why**: Cada mensaje cargaba ~6000 tokens de reglas de código incluso para preguntas simples de soporte N3, consumiendo créditos innecesarios. Engram hacía 2 llamadas MCP al inicio de cada sesión sin necesidad.
**Where**: ~/.kiro/steering/rule-*.md (6 archivos), ~/.kiro/steering/engram-knowledge-sync.md
**Learned**: Los steerings con `inclusion: always` se cargan en CADA turno sin importar el contexto. Para reglas de código que solo aplican al escribir/editar código, `fileMatch` es más eficiente. Impacto estimado: ~60-70% menos tokens en sesiones de soporte.

---

## #34 — Estructura definitiva repo power: solo powers/ + shared-knowledge/, sin .kiro/

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/repo-final-structure

**What**: Se corrigió definitivamente la estructura del repo corex-n3-power. NO debe tener .kiro/ a nivel de proyecto. Todo vive dentro de powers/corex-n3/ y el install.sh lo copia a ~/.kiro/ del usuario.

**Why**: Los hooks/scripts/steering a nivel de proyecto (.kiro/) solo funcionan si abres ESE repo en Kiro. El power se instala globalmente y funciona en cualquier workspace. Poner cosas en .kiro/ del repo no aporta nada.

**Where**: ~/Documents/tronador/corex-n3-power/ — estructura final: README.md + CHANGELOG.md + shared-knowledge/ + powers/corex-n3/ (todo adentro).

**Learned**: El repo del power tiene exactamente 2 cosas: (1) powers/corex-n3/ con todo lo que install.sh distribuye, (2) shared-knowledge/ para Engram compartido. NADA MÁS. No .kiro/, no hooks de proyecto, no steering de proyecto. El install.sh es el responsable de poner todo en ~/.kiro/ donde funciona globalmente.

---

## #31 — Separación de concerns: repo power vs repo de trabajo

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/repo-separation

**What**: Se clarificó la separación de concerns del repo corex-n3-power. El repo solo tiene 2 propósitos: (1) instalar el power, (2) compartir conocimiento Engram. Los hooks, scripts, steering de proyecto y agentes a nivel proyecto pertenecen al workspace donde se trabaja (tronador-oracle-db), NO al repo del power.

**Why**: Se habían copiado hooks y scripts al repo del power por error. Esos son de proyecto — se activan cuando trabajas en un repo específico. El power es portable y se instala globalmente.

**Where**: ~/Documents/tronador/corex-n3-power/ — limpio: .kiro/shared-knowledge/ + powers/corex-n3/ solamente.

**Learned**: Separación clara:
- Repo del power (corex-n3-power): power source + shared-knowledge. Nada más.
- Repo de trabajo (tronador-oracle-db): hooks, scripts, metrics, steering de proyecto, agentes a nivel proyecto.
- El install.sh del power copia agentes/skills/steering-global a ~/.kiro/ (nivel usuario), no al proyecto.

---

## #28 — Decisión: migrar power a repo dedicado (separar de tronador-oracle-db)

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** decision/power-dedicated-repo

**What**: Se decidió migrar el power corex-n3 a un repositorio dedicado (separado de tronador-oracle-db). El repo contendrá: el power completo, shared-knowledge de Engram, hooks, scripts, y documentación.

**Why**: Actualmente el power vive en una rama del repo de BD Oracle. Mezcla concerns: PRs de conocimiento/agente se confunden con PRs de código PL/SQL. Un repo dedicado permite versionamiento independiente, onboarding más simple (un solo clone), y shared-knowledge junto al power.

**Where**: Pendiente de crear. Estructura propuesta: powers/corex-n3/ (power), shared-knowledge/ (Engram), .kiro/ (hooks, scripts, metrics).

**Learned**: Los powers de Kiro se instalan desde un directorio local — no importa en qué repo vivan. Moverlo a un repo dedicado no rompe nada, solo cambia el path que se usa en 'Install Power from local directory'. El install.sh y update.sh siguen funcionando igual.

---

## #21 — Roadmap estratégico post-D: triaje automático, duplicados, GitHub MCP, onboarding

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/strategic-roadmap

**What**: Roadmap estratégico de mejoras post-Bloques B/C/D para potenciar al equipo Corex.

**Inteligencia colectiva:**
- Score de patrones (contador de uso, los más frecuentes suben al top)
- Detección de duplicados proactiva al crear MDSB

**Automatización ciclo completo:**
- Bot de triaje: clasificar MDSB nuevos automáticamente (módulo, severidad, patrón probable)
- Pre-diagnóstico nocturno: cron que genera borradores para MDSB sin asignar
- Auto-link de casos con misma causa raíz

**Visibilidad:**
- Dashboard de salud del equipo (casos/semana, tiempo promedio, patrones frecuentes)
- Reporte semanal automático para líder técnico
- Detección de deuda técnica (3+ repeticiones → HU automática)

**Integraciones:**
- GitHub MCP (PRs, branches, colisiones en tiempo real)
- Datadog/Observabilidad (correlacionar errores prod con MDSB)
- Slack/Teams notifications post-diagnóstico

**Onboarding:**
- Modo tutorial por módulo
- Simulador de incidentes con datos ficticios
- Certificación interna

**Prioridad recomendada post-D:** Detección duplicados proactiva, Reporte semanal, GitHub MCP.

**Where**: No implementado. Propuesto como Bloque E+.

**Learned**: El mayor salto de productividad viene de automatizar lo repetitivo (triaje, duplicados, reportes) y dar visibilidad sin esfuerzo (dashboard, notificaciones).

---

## #17 — Bloque D: Estrategias de eficiencia — menos créditos, mejor diagnóstico

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/efficiency-roadmap

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

**Where**: Propuesto como Bloque D. No implementado aún.

**Learned**: El mayor ahorro de créditos viene de NO repetir trabajo (Engram-first) y de ir directo al punto (queries pre-armadas + árboles de decisión). La efectividad mejora con estructura (flowcharts) y retroalimentación (feedback loop).

---

## #10 — Config limpia: mcpServers vacío, todo vive en el power

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** decision/mcp-single-source

**What**: Se limpió settings/mcp.json eliminando todos los servidores duplicados de mcpServers (usuario). Ahora mcpServers: {} está vacío y TODO vive exclusivamente en la sección powers.mcpServers del power corex-n3 (5 servidores: atlassian, oracle-readonly, oracle-stage, engram, context7).

**Why**: Tener servidores en ambos lugares (usuario + power) causaba procesos duplicados, confusión visual en Kiro, y la misma DB de Engram se abría dos veces.

**Where**: ~/.kiro/settings/mcp.json — mcpServers vacío, todo en powers.mcpServers.

**Learned**: La configuración más limpia es mcpServers: {} + todo dentro de powers.mcpServers. El install.sh para compañeros NO necesita generar mcpServers de usuario — solo el .env y los prerrequisitos (server.py, engram, agente). Kiro genera la sección powers al instalar el power desde el mcp.json del source.

---

## #9 — Flujo definitivo de instalación del power corex-n3

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/power-install-flow

**What**: Kiro al instalar un power solo copia POWER.md, mcp.json y steering/. NO copia archivos adicionales como server.py. El install.sh es OBLIGATORIO para poner server.py en ~/.kiro/powers/installed/corex-n3/. Además, el one-liner de auto-copy con python3+json en el comando sh -c es frágil y falla silenciosamente — mejor usar un comando directo simple.

**Why**: Cada reinstalación del power perdía server.py y Oracle no conectaba. El fallback de auto-copy con comillas anidadas y python3 inline no funcionaba en la práctica.

**Where**: ~/.kiro/powers/installed/corex-n3/server.py — debe existir ANTES de que Kiro intente levantar los servidores Oracle. powers/corex-n3/mcp.json — simplificado a comando directo sin auto-copy.

**Learned**: 
1. Kiro al instalar power solo copia: POWER.md, mcp.json, steering/. NADA MÁS.
2. server.py, agentes, engram, .env — todo eso lo pone install.sh (paso previo obligatorio).
3. Los comandos sh -c en mcp.json deben ser simples y directos. One-liners con python3 inline y comillas anidadas fallan silenciosamente.
4. Kiro NO sobrescribe mcpServers de usuario al instalar un power — solo agrega/actualiza la sección powers.
5. Context7 aparece dentro del power correctamente si estaba en el mcp.json del source al momento de instalar.
6. Flujo definitivo: (a) bash install.sh → (b) Install Power desde Kiro UI → (c) Reiniciar Kiro.

---

## #6 — Power mcp.json portable: credenciales via .env, sin hardcode ni placeholders

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/power-mcp-portable

**What**: Se rediseñó el mcp.json del power para que sea 100% portable. Todos los servidores (Atlassian, Oracle, Engram) usan `sh -c` con `set -a; . "$HOME/.kiro/settings/.env"; set +a` para cargar credenciales en runtime. Ya no hay hardcoded credentials ni variables placeholder en el mcp.json.

**Why**: Al reinstalar el power desde Kiro UI, el mcp.json se copia literal del source. Si tenía placeholders ($ORACLE_USER) no funcionaba. Si tenía credenciales hardcoded no era portable. La solución es que el mcp.json sea autocontenido y resuelva todo desde el .env.

**Where**: powers/corex-n3/mcp.json — ahora portable, sin credenciales ni placeholders. ~/.kiro/settings/.env — fuente única de credenciales (JIRA_USERNAME, JIRA_API_TOKEN, ORACLE_USER, ORACLE_PASSWORD, ORACLE_CLIENT_DIR).

**Learned**: El patrón correcto para powers con credenciales en Kiro es: mcp.json usa `sh -c` con source del .env, el install.sh solo crea el .env pidiendo credenciales. Así el mcp.json es idéntico para todos los compañeros y sobrevive reinstalaciones sin romperse. Atlassian también necesita el wrapper sh -c para leer JIRA_USERNAME y JIRA_API_TOKEN del .env.

---

## #1 — Integración MCPKiroKit - Context7 + Engram

**Tipo:** decision | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/knowledge-management

**What**: Se integró Context7 (documentación actualizada de librerías) y Engram (memoria persistente) al entorno Kiro, inspirado en el mcp-kiro-kit de Anderson Lugo.

**Why**: Necesitamos memoria entre sesiones para diagnósticos N3 y documentación actualizada para generación de microservicios. Engram actúa como caché local de la KB de Confluence.

**Where**: ~/.kiro/settings/mcp.json — servidores context7 y engram agregados. ~/.engram/engram.db — base SQLite local. .kiro/steering/rule-knowledge-sync.md — política de sincronización Engram↔Confluence.

**Learned**: Engram es un binario Go nativo (Gentleman-Programming/engram v1.15.10), no un paquete npm. Se instala en ~/.local/bin/engram. La estrategia de KB es: Confluence = fuente canónica, Engram = caché rápida local. Hook sync-knowledge-base creado para automatizar persistencia post-diagnóstico.

---
