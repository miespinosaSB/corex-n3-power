---
inclusion: manual
---

# Escritura y Creación de Historias de Usuario en Jira

## Trigger

Cuando el usuario diga **"crea una HU"**, **"escribe una historia de usuario"**, **"nueva HU"**, **"historia de usuario para..."**, o cualquier variante que implique redactar y/o crear una Historia de Usuario en Jira, seguir este steering.

También aplica cuando durante el ciclo de atención de incidentes (Fase 3) se necesite crear la HU con descripción estructurada.

---

## Estructura de la Historia de Usuario

### Formato obligatorio de la descripción

Toda HU debe seguir la estructura BDD (Behavior-Driven Development) con el formato **"Como... quiero... para..."** y escenarios **Dado-Cuando-Entonces (Given-When-Then)**:

```
**Yo**, como [perfil/rol del usuario], **quiero** [acción o funcionalidad deseada], **para** [beneficio o valor de negocio].

**Alcance:**
[Descripción del contexto, pantallas afectadas, flujo actual y cambio solicitado]

---

**Escenario 1:** [Nombre descriptivo del escenario]
- **Dado** [contexto o precondición inicial]
- **Cuando** [acción específica del usuario o del sistema]
- **Entonces** [resultado esperado o respuesta del sistema]

**Escenario 2:** [Nombre descriptivo del escenario]
- **Dado** [contexto o precondición inicial]
- **Cuando** [acción específica del usuario o del sistema]
- **Entonces** [resultado esperado o respuesta del sistema]

[Agregar tantos escenarios como sea necesario para cubrir el comportamiento]
```

### Reglas de redacción

1. **Perfil/Rol**: Usar el rol real del usuario (ej: "usuario del portal", "COP", "proveedor", "analista de siniestros", "administrador"). NO usar nombres genéricos como "usuario" a menos que aplique a todos.

2. **Quiero**: Describir la intención, NO la implementación técnica. Correcto: "quiero ver el estado de mis pagos". Incorrecto: "quiero que se ejecute el SP PCK_CONSULTA_PAGOS".

3. **Para**: El beneficio debe ser claro y orientado al valor de negocio. Correcto: "para hacer seguimiento a mis facturas pendientes". Incorrecto: "para que funcione".

4. **Alcance**: Sección obligatoria que describe:
   - Pantalla(s) o flujo(s) afectados
   - Comportamiento actual (si es corrección)
   - Comportamiento esperado
   - Limitaciones o exclusiones del alcance

5. **Escenarios GWT**: Mínimo 2 escenarios por HU:
   - Al menos 1 escenario del **camino feliz** (happy path)
   - Al menos 1 escenario **alternativo o de error** (edge case, validación, error)
   - Cada escenario debe ser **independiente y comprobable**
   - Usar lenguaje de negocio, no técnico

6. **Y / Pero**: Se pueden usar para extender cualquier sección:
   - "Dado que estoy en la página de pagos **y** tengo facturas pendientes"
   - "Entonces se muestra el mensaje de confirmación **pero** no se envía correo"

---

## Criterios de Aceptación (campo Jira)

Los criterios de aceptación en Jira (`customfield_10332`) se derivan directamente de los escenarios GWT. Cada escenario se convierte en un criterio numerado.

### Formato ADF para Jira

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "CA1: Dado [precondición], cuando [acción], entonces [resultado]"
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "CA2: Dado [precondición], cuando [acción], entonces [resultado]"
        }
      ]
    }
  ]
}
```

### Ejemplo real

Para la HU "Ocultar botón de detalle de pago para proveedores":

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "CA1: Dado que un proveedor accede a la Consulta de Documentos de Pago y tiene documentos en estado 'En proceso', cuando se carga la pantalla, entonces el botón de verificación de pago NO debe ser visible."
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "CA2: Dado que un proveedor accede a la Consulta de Documentos de Pago y tiene documentos en estado 'Recibido' o 'Devuelto proveedor', cuando se carga la pantalla, entonces la visualización de esos estados no debe verse afectada por el cambio."
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "CA3: Dado que el botón fue ocultado temporalmente, cuando se requiera reactivar la funcionalidad, entonces solo debe ser necesario cambiar la configuración sin modificar código fuente."
        }
      ]
    }
  ]
}
```

---

## Flujo de Creación de HU

### Paso 0: Recopilar información

Preguntar al usuario (si no se tiene ya):

> Para crear la Historia de Usuario necesito:
> 1. **Tu email** (para asignar el issue)
> 2. **Proyecto y epic** donde crearla (ej: GD986 epic GD986-824)
> 3. **¿Qué necesidad o problema resuelve?** (descripción en lenguaje de negocio)
> 4. **¿Quién es el usuario/rol afectado?**
> 5. **¿Hay casos MDSB relacionados?** (opcional)

Si el usuario ya proporcionó contexto suficiente (por ejemplo, viene de un diagnóstico de incidente), no repetir preguntas innecesarias.

### Paso 1: Redactar la HU

Construir la descripción con la estructura BDD:

1. Identificar el **rol/perfil** del usuario
2. Definir el **quiero** (intención, no implementación)
3. Definir el **para** (valor de negocio)
4. Escribir el **alcance** con contexto completo
5. Redactar **escenarios GWT** (mínimo 2)
6. Derivar **criterios de aceptación** de los escenarios

### Paso 2: Presentar al usuario para revisión (⚠️ OBLIGATORIO)

⚠️ **NUNCA crear la HU en Jira sin confirmación explícita del usuario.** Mostrar la HU completa y esperar aprobación:

```markdown
## Historia de Usuario propuesta

**Título:** [título conciso y descriptivo]

**Descripción:**
[descripción completa con formato BDD]

**Criterios de Aceptación:**
- CA1: [criterio derivado del escenario 1]
- CA2: [criterio derivado del escenario 2]
- ...

**Proyecto:** [PROJECT_KEY] | **Epic:** [EPIC_KEY]

⚠️ **¿Apruebas esta HU para crearla en Jira?** (Responde sí/no. Puedo ajustar cualquier sección antes de crearla.)
```

### Paso 3: Crear en Jira (solo después de aprobación)

⚠️ **Solo ejecutar este paso si el usuario confirmó explícitamente.** Si el usuario pide cambios, volver al Paso 1 y ajustar.

```
jira_create_issue(
  project_key="<PROJECT_KEY>",
  summary="<Título de la HU>",
  issue_type="Historia",
  assignee="<email del usuario>",
  description="<Descripción completa en markdown con formato BDD>",
  additional_fields='{
    "parent": {"key": "<EPIC_KEY>"},
    "customfield_13801": {"value": "Funcional"},
    "customfield_10332": <ADF con criterios de aceptación>,
    "customfield_31136": [{"workspaceId": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4", "id": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4:419497", "objectId": "419497"}]
  }'
)
```

### Paso 4: Vincular artefactos (si aplica)

- Vincular casos MDSB relacionados con `jira_create_issue_link` (tipo "Relacionado")
- Vincular página de Confluence con `jira_create_remote_issue_link` (si existe documentación)
- Agregar labels relevantes si el usuario los indica

### Paso 5: Confirmar al usuario

```markdown
✅ Historia creada: **[HU_KEY]** - [título]
- Proyecto: [PROJECT_KEY] | Epic: [EPIC_KEY]
- Criterios de aceptación: [N] criterios
- Vínculos: [lista de MDSB vinculados, si aplica]
- URL: https://jirasegurosbolivar.atlassian.net/browse/[HU_KEY]
```

---

## Ejemplo Completo

### Input del usuario
> "Crea una HU para ocultar el botón de detalle de pago en la consulta de documentos de pago para proveedores. Va en GD930 epic GD930-XXX."

### HU generada

**Título:** EO-FE-EV : Proveedores - Consulta Documentos de Pagos - Ocultar Botón Detalle Pago

**Descripción:**

```
**Yo**, como COP, **quiero** que el botón de verificación de pago en la Consulta de Documentos
de Pago esté oculto, **para** que la funcionalidad de ver el estado y detalle del pago no esté
disponible para los proveedores temporalmente.

**Alcance:**

La pantalla de Consulta de Documentos de Pago muestra los documentos clasificados en tres
estados: "Recibido", "En proceso" y "Devuelto proveedor".

Actualmente, cuando un documento está en estado "En proceso", se presenta un botón que permite
a los proveedores verificar el estado de pago y, si ya fue pagado, ver el detalle del mismo.

Se solicita deshabilitar temporalmente la visibilidad de este botón para los usuarios, sin
eliminarlo permanentemente del código, de modo que la funcionalidad asociada no sea accesible.

---

**Escenario 1:** Ocultar botón de verificación de pago
- **Dado** que un proveedor accede a la Consulta de Documentos de Pago y tiene documentos
  en estado "En proceso"
- **Cuando** se carga la pantalla de consulta
- **Entonces** el botón de verificación de pago NO debe ser visible

**Escenario 2:** No afectar otros estados de documentos
- **Dado** que un proveedor accede a la Consulta de Documentos de Pago
- **Cuando** visualiza documentos en estado "Recibido" o "Devuelto proveedor"
- **Entonces** la presentación de esos documentos no debe verse afectada por el cambio

**Escenario 3:** Reactivación futura del botón
- **Dado** que el botón fue ocultado mediante configuración
- **Cuando** se requiera reactivar la funcionalidad en el futuro
- **Entonces** debe ser posible habilitarlo sin modificar código fuente
```

---

## Integración con el Ciclo de Incidentes

Cuando se crea una HU como parte del ciclo de atención de incidentes (`atencion-incidente-autonomo.md`, Fase 3), la descripción debe incluir además:

- Referencia al problema detectado en el diagnóstico
- Datos relevantes encontrados en Oracle (sin exponer datos sensibles)
- Link a la documentación en Confluence

El formato BDD se mantiene igual. Los escenarios deben cubrir:
1. **Corrección del defecto** (comportamiento esperado después del fix)
2. **No regresión** (comportamiento que NO debe cambiar)
3. **Caso borde** (si aplica, basado en los hallazgos del diagnóstico)

---

## Referencia

- [Historias de usuario - Atlassian](https://www.atlassian.com/es/agile/project-management/user-stories)
- [Given-When-Then - Agile Alliance](https://www.agilealliance.org/glossary/given-when-then/)
- Ejemplo real en Jira: [GD930-1563](https://jirasegurosbolivar.atlassian.net/browse/GD930-1563)
