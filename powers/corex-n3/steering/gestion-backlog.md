# Gestión de Backlog - Tribu Corex

## Workflow de reducción

### 1. Extracción
Usar `jira_search` con JQL. Máximo 45 keys por query.

### 2. Categorización
Agrupar por tipo de problema y caso padre.

### 3. Cierre de duplicados
1. `jira_add_comment` — explicar relación con caso padre
2. `jira_transition_issue` — cerrar
3. Crear link "Relacionado" al padre si no existe

### 4. Generar CSV de seguimiento
Columnas: Grupo, Caso, Resumen, Estado, Caso Padre, Confirmado, Acción

## Casos padre conocidos

| Caso Padre | Tema | Hijos |
| --- | --- | --- |
| MDSB-942185 | Servicio Deuda / Pago en Línea | 20+ |
| MDSB-892939 | Comisiones erradas | 10+ |
| MDSB-1008463 | P&G / Reportes Tronador | 7+ |
| MDSB-817599 | PYMES anuladas con deuda | 3+ |
