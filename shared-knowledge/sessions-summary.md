# Resúmenes de Sesión — Engram Export

> Exportado: 2026-05-12 | Proyecto: tronador-oracle-db | 17 sesiones totales

---

## #64 — Sesión: Diagnóstico completo MDSB-992543 (RESUELTO)

**Fecha:** 2026-05-13

### Goal
Reproducir y documentar completamente el caso MDSB-992543: diferencia de $15,332 entre factura de cobro y devolución por exclusión de riesgo.

### Discoveries
- **CAUSA RAÍZ ENCONTRADA**: Sim_Pck299_Cb100270.Prc_Proceso hace UPDATE a A2000163 DESPUÉS del INSERT, sumando diferidos (C1000270) × V_factor
- Fórmula completa: `IMP_PRIMA = ROUND(IMP_PRIMA_END × CoefFact, 0) + (IMP_PRIMA_163 × V_factor)`
- V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) = 13 meses restantes
- El sistema devuelve 13 meses de diferidos ($35,256) cuando solo cobró 1 mes ($2,712)
- Neto para el cliente: +$12,884 a favor — se devuelve más de lo cobrado
- Es una FALLA LÓGICA: CB100270 no valida cuántos diferidos se cobraron antes de devolver
- Ya hubo corrección manual en prod (facturas 20 y 21 del endoso 16)

### Accomplished
- ✅ Reproducido numéricamente: -197,949 + 35,256 = -162,693 ✓
- ✅ Identificado paquete causante: Sim_Pck299_Cb100270 (Prc_upd163, línea 303)
- ✅ Documentado flujo completo desde Form hasta INSERT+UPDATE
- ✅ Creado documento ANALISIS_MDSB-992543.md con análisis completo
- ✅ Ejecutado script PL/SQL en dev via SQL Developer para confirmar valores

### Next Steps
- Documentar en Confluence como hallazgo técnico
- Crear HU para corregir la lógica de CB100270 (V_factor debe considerar solo diferidos cobrados)
- Responder al caso MDSB-992543 con la explicación
- Análisis de impacto: ¿cuántas pólizas se afectan por este patrón?

### Relevant Files
- `ANALISIS_MDSB-992543.md` — documento completo del análisis
- `Base Datos/Packages/SIM_PCK299_CB100270.pkb` — paquete causante (Prc_upd163 línea 303, Prc_lee270)
- `Base Datos/Packages/SIM_PCK299_AB100273.pkb` — llamada a CB100270 en línea 820
- `test_mdsb992543.sql` — script de prueba ejecutado en dev

---

## #57 — Sesión: Optimización del power corex-n3

**Fecha:** 2026-05-12

### Goal
Optimizar el power corex-n3: reducir consumo de créditos, mejorar precisión de diagnósticos, corregir bug de credenciales, y asegurar compatibilidad cross-platform.

### Discoveries
- Steering files con `inclusion: always` cargan ~6000 tokens innecesarios en sesiones de soporte
- `get_source` del MCP Oracle trunca packages grandes; el repo local no tiene ese límite
- Las credenciales en Kiro powers viven en `~/.kiro/settings/.env` (macOS/Linux) o en mcp.json directo (Windows). NO están en variables de entorno del shell
- En Windows el install.ps1 pone las credenciales directo en mcp.json env, no usa .env
- El flujo de diagnóstico anterior hacía queries de datos ANTES de leer código fuente, generando consultas exploratorias sin fundamento

### Accomplished
- ✅ 6 steering files globales convertidos a `inclusion: fileMatch` (~60-70% menos tokens en sesiones de soporte)
- ✅ Engram simplificado (no se activa automáticamente al inicio)
- ✅ Regla "repo primero, Oracle después" en diagnostico-eficiente.md y fuentes-codigo-repositorios.md
- ✅ Flujo diagnóstico reestructurado: Engram → Confluence/Jira → Repo Oracle DB → Repo COBOL → Repo Forms → Oracle (solo datos)
- ✅ Política "CERO SUPOSICIONES" — toda afirmación respaldada por código leído o datos verificados
- ✅ Tabla de evidencia obligatoria y sección "No Verificado" en reporte final
- ✅ Fix credenciales consulta-produccion-mdsb: lee de .env (macOS/Linux) o mcp.json (Windows)
- ✅ Creado update.ps1 para Windows
- ✅ Script consulta producción cross-platform (busca en ambas ubicaciones)
- ✅ Pushed to remote: 3 commits (500cc4a, 62b2ff9, a72fd36)
- ✅ Power local actualizado con update.sh

### Next Steps
- Validar en próximo diagnóstico real que el agente sigue el nuevo flujo
- Considerar actualizar el sub-agente corex-incident-diagnostics con las mismas reglas
- Pedir a un compañero en Windows que pruebe install.ps1 + update.ps1

### Relevant Files
- `powers/corex-n3/steering/diagnostico-eficiente.md` — regla absoluta + repo-first + cero suposiciones
- `powers/corex-n3/steering/atencion-incidente-autonomo.md` — Fase 1 reestructurada + scoring con evidencia
- `powers/corex-n3/steering/fuentes-codigo-repositorios.md` — Oracle DB como fuente de verdad
- `powers/corex-n3/steering/consulta-produccion-mdsb.md` — fix credenciales cross-platform
- `powers/corex-n3/update.ps1` — nuevo script Windows
