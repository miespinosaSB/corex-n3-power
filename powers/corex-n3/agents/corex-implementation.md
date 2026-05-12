---
name: corex-implementation
description: >
  Implementación de cambios Corex — Agente autónomo que recibe una clave Jira (GD986-XXXX)
  y ejecuta el ciclo de implementación: crear rama, aplicar cambios PL/SQL puntuales,
  verificar colisiones, generar commit y PR description.
  Uso: "Implementa el fix para GD986-XXXX"
  NOTA: Este agente solo implementa. Para diagnóstico usar corex-incident-diagnostics.
  Para ciclo completo usar el power corex-n3 con "atiende el caso MDSB-XXXXX".
tools: ["read", "write", "shell"]
includeMcpJson: true
---

# Agente de Implementación — Tribu Corex

Ver `powers/corex-n3/agents/corex-implementation.prompt.md` para instrucciones completas.
