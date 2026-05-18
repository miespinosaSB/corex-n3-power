# Guía de Uso — Power corex-n3

Guía práctica para el día a día con el power y sus agentes.

## Tu primer día

1. **Clona** el repo: `git clone git@github.com:miespinosaSB/corex-n3-power.git`
2. **Instala**: `bash powers/corex-n3/install.sh`
3. **En Kiro**: Command Palette → "Install Power from local directory" → `powers/corex-n3/`
4. **Reinicia** Kiro
5. **Importa conocimiento**: Di "actualiza conocimiento" en el chat

Verifica que los 5 servidores MCP estén conectados (panel Powers → corex-n3).

## Comandos del día a día

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
8. Guarda el diagnóstico en Engram

### Solo diagnosticar

```
Tú: "Diagnostica el caso MDSB-123456"
```

O usa `Ctrl+Shift+D` para cambiar al agente de diagnóstico.

### Implementar un fix

```
Tú: "Implementa el fix para GD986-1234"
```

Crea rama, hace cambios puntuales, verifica colisiones, genera commit y PR.

### Crear una Historia de Usuario

```
Tú: "Crea una HU para corregir el cálculo de prima en renovación"
```

Estructura BDD con escenarios Dado-Cuando-Entonces. Te muestra para aprobación antes de crear.

### Consultar producción

```
Tú: "Consulta en prod: SELECT * FROM OPS$PUMA.A2000030 WHERE num_poliza = '123456'"
```

Genera el MDSB con SQL formateado para el bot AIOps.

### Actualizar conocimiento

```
Tú: "Actualiza conocimiento"
```

El agente:
1. Exporta tus memorias de Engram
2. Hace commit y push al repo
3. Propone actualizar Confluence si hay patrones nuevos

Nota: debes estar en el directorio del repo corex-n3-power para que el script funcione.

### Retrospectiva

```
Tú: "Retrospectiva"
```

Analiza los últimos 30 días y propone mejoras a la KB y al power.

### Generar JSON de emisión

```
Tú: "Genera un JSON de emisión para cumplimiento cia 3 secc 4 prod 450"
```

O usa `Ctrl+Shift+E` para cambiar al agente de emisión.

El agente:
1. Identifica el producto y consulta Oracle (campos obligatorios, coberturas)
2. Te guía con preguntas en lenguaje de negocio (o usa póliza de referencia)
3. Genera el JSON listo para `POST /api/v1/expgenerica/procesar`
4. Guarda memoria en Confluence para futuras emisiones del mismo producto

Modos disponibles:
- **Conversacional**: "Necesito emitir una póliza de cumplimiento" → te guía paso a paso
- **Express**: Das todos los datos de una vez → genera directo
- **Referencia**: "Emisión para cia 3, secc 4, prod 450 — busca póliza de referencia" → usa datos de una póliza existente
- **Cotización**: "Cotiza una póliza de..." → mismo JSON pero con proceso 241/240

## Skills — Cómo funcionan

Se activan automáticamente cuando tu request coincide:

- Mencionas "póliza", "factura", "Oracle" → `corex-oracle-diagnostics`
- Mencionas "HU", "tiempo", "backlog" → `corex-jira-workflow`
- Mencionas "documenta", "Confluence" → `corex-confluence-docs`
- Mencionas "microservicio", "endpoint" → `corex-adapter-v3`

También puedes invocarlas con `/` en el chat.

## Hooks — Protecciones automáticas

Trabajan en segundo plano:

| Situación | Qué pasa |
|---|---|
| Intentas ejecutar DELETE/UPDATE | Bloquea y avisa |
| Query sin ROWNUM | Agrega ROWNUM <= 50 |
| Diagnóstico nuevo | Busca en Engram primero (ahorra créditos) |
| Caso menciona COBOL/Forms | Busca en el índice de fuentes |
| Sesión termina | Registra métricas |

## Engram — Memoria del equipo

### Se guarda automáticamente

- Diagnósticos resueltos
- Patrones Oracle descubiertos
- Decisiones técnicas
- Queries útiles

### Compartir con el equipo

```
Tú: "Actualiza conocimiento"
```

O manualmente:
```bash
bash powers/corex-n3/scripts/engram-sync.sh export
git add shared-knowledge/
git commit -m "docs: sync engram"
git push
```

### Recibir conocimiento de compañeros

```bash
git pull
bash powers/corex-n3/scripts/engram-sync.sh import
```

O usa el botón "Importar Engram" en hooks.

## Context7 — Docs actualizadas

Cuando generas microservicios, el agente consulta automáticamente documentación actualizada de Spring Boot, MapStruct, JUnit, etc. No necesitas hacer nada.

## Métricas

```bash
bash powers/corex-n3/scripts/metrics-report.sh --period week
bash powers/corex-n3/scripts/metrics-report.sh --period month
```

## Tips de eficiencia

1. **Sé específico**: "Diagnostica MDSB-123456" > "hay un error"
2. **Usa el ciclo completo**: "Atiende el caso" hace todo de una vez
3. **Confía en Engram**: Si ya resolvimos algo similar, lo encuentra
4. **Actualiza conocimiento** al final del día
5. **Pide retrospectiva** mensual para mantener la KB viva

## FAQ

**¿Puedo usar el power en cualquier proyecto?**
Sí. Se instala globalmente. Pero los hooks y scripts solo funcionan si abres este repo en Kiro.

**¿Qué pasa si no tengo VPN?**
Oracle no conecta, pero Jira, Confluence, Engram y Context7 siguen funcionando.

**¿Cómo actualizo?**
`git pull && bash powers/corex-n3/update.sh`

**¿Engram se llena?**
La DB SQLite es muy eficiente. Miles de observaciones ocupan pocos MB.

**¿Qué pasa si dos personas editan el mismo package Oracle?**
El hook de detección de colisiones te avisa antes de hacer cambios.
