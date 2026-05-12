# Guía de Uso — Power corex-n3

Guía práctica para el día a día con el power y sus agentes.

## Tu primer día

Después de instalar (`install.sh` + Install Power + reiniciar Kiro):

1. **Verifica** que los 5 servidores MCP estén conectados (panel Powers → corex-n3)
2. **Prueba** con: "Diagnostica el caso MDSB-XXXXX" (usa un caso reciente)
3. **Importa** conocimiento del equipo: `bash .kiro/scripts/engram-sync.sh import`

## Flujos de trabajo diarios

### Atender un incidente (ciclo completo)

```
Tú: "Atiende el caso MDSB-123456"
```

El agente ejecuta automáticamente:
1. Busca diagnósticos previos en Engram
2. Carga la KB de Confluence
3. Lee el caso Jira completo
4. Consulta Oracle (guiado por árboles de decisión)
5. Documenta en Confluence
6. Crea HU en Jira + vincula todo
7. Registra tiempos
8. Guarda el diagnóstico en Engram para el equipo

### Solo diagnosticar (sin documentar)

```
Tú: "Diagnostica el caso MDSB-123456"
```

O usa el shortcut `Ctrl+Shift+D` para cambiar al agente de diagnóstico.

### Implementar un fix

```
Tú: "Implementa el fix para GD986-1234"
```

El agente:
1. Lee la HU y el diagnóstico
2. Crea rama desde master
3. Hace cambios PUNTUALES (nunca reemplaza archivos completos)
4. Verifica colisiones con otros devs
5. Genera commit y descripción de PR

### Crear una Historia de Usuario

```
Tú: "Crea una HU para corregir el cálculo de prima en renovación"
```

El agente te pregunta proyecto/epic, redacta con estructura BDD, y te muestra para aprobación antes de crear en Jira.

### Consultar producción

```
Tú: "Consulta en prod: SELECT * FROM OPS$PUMA.A2000030 WHERE num_poliza = '123456'"
```

El agente genera el MDSB con el SQL formateado para el bot AIOps.

### Retrospectiva

```
Tú: "Retrospectiva"
```

Analiza los últimos 30 días y propone mejoras a la KB y al power.

## Skills — Cómo funcionan

Las skills se activan automáticamente cuando tu request coincide con su dominio. No necesitas hacer nada especial:

- Mencionas "póliza", "factura", "Oracle" → se activa `corex-oracle-diagnostics`
- Mencionas "HU", "tiempo", "backlog" → se activa `corex-jira-workflow`
- Mencionas "documenta", "Confluence" → se activa `corex-confluence-docs`
- Mencionas "microservicio", "endpoint" → se activa `corex-adapter-v3`

También puedes invocarlas manualmente con `/` en el chat.

## Engram — Memoria del equipo

### Qué se guarda automáticamente

- Diagnósticos resueltos (causa raíz + solución)
- Patrones Oracle descubiertos
- Decisiones técnicas
- Queries útiles

### Compartir conocimiento

```bash
# Después de resolver algo importante
bash .kiro/scripts/engram-sync.sh export
git add .kiro/shared-knowledge/
git commit -m "docs: sync engram knowledge"
git push

# Al inicio del día (importar lo nuevo)
git pull
bash .kiro/scripts/engram-sync.sh import
```

### Buscar en la memoria

```
Tú: "¿Ya hemos visto un caso de factura no generada en ramo 201?"
```

El agente busca automáticamente en Engram antes de consultar Oracle.

## Hooks — Protecciones automáticas

No necesitas hacer nada — los hooks trabajan en segundo plano:

| Situación | Qué pasa |
|---|---|
| Intentas ejecutar un DELETE/UPDATE | Hook bloquea y te avisa |
| Query sin ROWNUM | Hook agrega ROWNUM <= 50 automáticamente |
| Diagnóstico nuevo | Hook busca en Engram primero (ahorra créditos) |
| Caso menciona COBOL/Forms | Hook busca en el índice de fuentes |
| Sesión termina | Hook registra métricas de uso |

## Métricas — Visibilidad del equipo

```bash
# ¿Cuántos diagnósticos hicimos esta semana?
bash .kiro/scripts/metrics-report.sh --period week

# ¿Qué herramientas usamos más?
bash .kiro/scripts/metrics-report.sh --period month
```

## Context7 — Documentación actualizada

Cuando generas microservicios o trabajas con Spring Boot, el agente consulta automáticamente la documentación más reciente. No necesitas hacer nada — el steering `context7-microservices.md` lo activa cuando detecta que estás en ese contexto.

## Tips para ser más eficiente

1. **Sé específico**: "Diagnostica MDSB-123456" es mejor que "hay un error"
2. **Usa el ciclo completo**: "Atiende el caso" hace todo de una vez
3. **Confía en Engram**: Si ya resolvimos algo similar, el agente lo encuentra
4. **Exporta al final del día**: `engram-sync.sh export` para que el equipo se beneficie
5. **Pide retrospectiva mensual**: Mantiene la KB actualizada y el power mejorando

## Estructura de archivos (para referencia)

```
~/.kiro/
├── settings/
│   ├── mcp.json          # Config MCP (powers section)
│   └── .env              # Credenciales (JIRA, Oracle)
├── agents/               # Sub-agentes globales
├── skills/               # Skills globales (4)
├── steering/             # Steering globales (Engram, Context7, etc.)
├── powers/installed/corex-n3/
│   ├── server.py         # Servidor Oracle MCP
│   ├── mcp.json          # Referencia (Kiro usa settings/mcp.json)
│   ├── POWER.md          # Documentación del power
│   └── steering/         # 26 steering files
└── .local/bin/
    └── engram            # Binario de memoria persistente

~/.engram/
└── engram.db             # Base de datos de memoria (SQLite)

<proyecto>/.kiro/
├── hooks/                # 17 hooks de protección
├── scripts/              # Sync, métricas, índice
├── shared-knowledge/     # Memorias exportadas (Git)
└── metrics/              # Datos de uso
```

## FAQ

**¿Puedo usar el power en cualquier proyecto?**
Sí. El power se instala globalmente. Funciona en cualquier workspace.

**¿Qué pasa si no tengo VPN?**
Oracle no conectará, pero Jira, Confluence, Engram y Context7 siguen funcionando.

**¿Cómo actualizo el power?**
`bash powers/corex-n3/update.sh` — actualiza todo sin pedir credenciales.

**¿Puedo modificar los steering?**
Sí. Los steering en `.kiro/steering/` del proyecto son editables. Los cambios aplican inmediatamente.

**¿Engram se llena?**
La DB SQLite crece con el uso pero es muy eficiente. Miles de observaciones ocupan pocos MB.

**¿Qué pasa si dos personas editan el mismo package Oracle?**
El hook de detección de colisiones te avisa antes de que hagas cambios.
