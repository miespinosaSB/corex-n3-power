# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y este proyecto adhiere a [Versionamiento Semántico](https://semver.org/lang/es/).

## [No publicado]

### Agregado
- Se migró el power corex-n3 a repositorio dedicado (antes vivía en rama de tronador-oracle-db)
- Se incluyeron 3 sub-agentes: diagnóstico, implementación, retrospectiva
- Se incluyeron 4 skills globales: oracle-diagnostics, jira-workflow, confluence-docs, adapter-v3
- Se incluyeron 17 hooks de protección y automatización
- Se incluyeron 3 scripts: engram-sync, metrics-report, generate-source-index
- Se integró Engram (memoria persistente) como MCP del power
- Se integró Context7 (documentación actualizada) como MCP del power
- Se creó steering `diagnostico-eficiente.md` con árboles de decisión y templates SQL
- Se creó steering `context7-microservices.md` para consulta automática de docs
- Se creó GUIA-USO.md para onboarding del equipo
- Se creó update.sh para actualización sin reinstalar
