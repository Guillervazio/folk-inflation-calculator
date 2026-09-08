# To-do — Calculador de Inflación Colaborativo

> Lista de ejecución derivada de [backlog.md](backlog.md). Cada tarea referencia su épica (`E3`) o su *spike* (`S1`).
> El **qué** y el **porqué** viven en el backlog; aquí está el **cómo** y el **en qué orden**.

**Leyenda:** `[ ]` pendiente · `[~]` en curso · `[x]` hecho · 🚧 bloqueante de la fase

---

## Fase 0 — Decisiones y andamiaje

> **Objetivo comprobable:** cualquier persona clona el repositorio, ejecuta un comando y tiene front, API y base de datos corriendo en local. Los cuatro *spikes* están cerrados por escrito.

### Spikes (hacer primero: sus resultados cambian el plan)

- [x] **S1** — Investigar el QR de los comprobantes electrónicos paraguayos: si existe una vía para obtener el detalle de ítems de forma verificable y programática, y qué proporción de tickets lo trae hoy. → [S1-qr-comprobante.md](spikes/S1-qr-comprobante.md), veredicto **parcial**.
- [x] **S1** — Reevaluada la prioridad de E3: **se mantiene como camino principal**. El detalle de ítems sale del XML del Documento Electrónico, no del QR, y sólo lo tiene el receptor que además es facturador electrónico; con el cronograma de incorporación abierto hasta septiembre de 2027, seguirán llegando tickets sin XML durante toda la transición.
- [x] **S2** — Verificar qué publica el BCP sobre el IPC: serie histórica, ponderaciones de la canasta, formato, frecuencia y condiciones de uso. → [S2-ipc-oficial.md](spikes/S2-ipc-oficial.md).
- [x] **S2** — No hace falta alternativa propia de ponderación: las oficiales (EPF 2015/16, base dic-2017 = 100) son reutilizables bajo la licencia de información pública del BCP, citando fuente y fecha de actualización y sin sugerir aval oficial.
- [ ] **S3** — Comparar proveedores de almacenamiento de objetos con borrado automático por TTL: coste, latencia desde Paraguay y facilidad de operación.
- [ ] **S4** — Reunir entre 20 y 30 fotos de tickets paraguayos reales (distintas cadenas, distinto estado de conservación) y transcribirlas a mano: es el conjunto de referencia para medir precisión.
- [ ] **S4** — Evaluar modelos de visión candidatos contra ese conjunto: precisión por campo, coste y latencia por ticket. Decidir y registrar el motivo de la elección.

### Decisiones técnicas

- [ ] **E1** — Fijar versiones de .NET y Angular, y dejarlas escritas.
- [ ] **E1** — Elegir el gestor del monorepo (workspace de Angular + solución de .NET, o herramienta de monorepo) y justificar la elección.
- [ ] **E1** — Elegir motor de base de datos y proveedor de alojamiento para front, API y base de datos.
- [ ] **E1** — Definir la estrategia de pruebas: qué se prueba en unitarias, qué en integración y qué de punta a punta.

### Andamiaje

- [ ] **E1** — Inicializar el repositorio git con `.gitignore`, `.editorconfig` y convención de mensajes de commit.
- [ ] **E1** — Crear la estructura del monorepo: `apps/web` (Angular), `apps/api` (.NET), `docs/`.
- [ ] **E1** — Esqueleto de la API .NET: proyecto, endpoint de salud, Swagger, CORS.
- [ ] **E1** — Esqueleto del front Angular: proyecto, enrutado base, cliente HTTP contra la API.
- [ ] **E1** — Levantar todo el entorno con un comando (Docker Compose o equivalente), funcionando en Windows y Linux.
- [ ] **E1-3** — CI: compilación de front y API, pruebas y análisis estático en cada pull request.
- [ ] **E1-4** — Configuración por entorno mediante variables; verificar que no queda ningún secreto en el repositorio.

### Modelo de datos

- [ ] **E5/E6** — Diseñar el esquema inicial: `Ticket`, `TicketItem`, `Producto canónico`, `Comercio`, `ObservacionPrecio`, `Categoría`, `IndicePeriodo`.
- [ ] **E5/E6** — Modelar país y moneda desde el inicio, aunque el MVP solo cubra Paraguay: añadirlos después obliga a migrar todo.
- [ ] **E5** — Decidir la representación de importes en guaraníes (entero, sin decimales) y dejarlo documentado en el esquema.
- [ ] **E1** — Configurar el ORM y el sistema de migraciones; primera migración aplicada.

---

## Fase 1 — Camino feliz de punta a punta

> **Objetivo comprobable:** un ticket real de un supermercado paraguayo se sube desde un móvil, se extrae, se revisa, se confirma y queda persistido en la base de datos con sus ítems y precios correctos.

### Subida

- [ ] **E2-1** — Endpoint de subida de imagen: validación de tipo y tamaño en el servidor.
- [ ] **E2-1** — Integrar el almacenamiento temporal elegido en S3, con el TTL configurado.
- [ ] **E2-1** — Pantalla de subida en Angular: selección de archivo y captura desde la cámara del móvil.
- [ ] **E2-2** — Previsualización con recorte, rotación y reemplazo del archivo.
- [ ] **E2-3** — Mensajes de error concretos para cada caso de rechazo (formato, tamaño, imagen ilegible).
- [ ] **E2-4** — Indicador de estado durante subida y extracción.
- [ ] **E9-1** — Aviso visible en la pantalla de subida: la imagen se borra a las 72 h.
- [ ] **E8-2** — Calcular el `sha256` de la imagen en la subida y almacenarlo.

### Extracción

- [ ] **E3-1** — Definir el esquema JSON de salida, versionado, y sus objetos en .NET.
- [ ] **E3-1** — Servicio de extracción: envío de la imagen al modelo, recepción y validación estricta contra el esquema.
- [ ] **E3-1** — Redactar el prompt de extracción; guardarlo versionado en el repositorio, no incrustado en el código.
- [ ] **E3-3** — 🚧 Parseo de importes en guaraníes, con pruebas unitarias dedicadas al formato `15.000` y a la ausencia de decimales.
- [ ] **E3-2** — Clasificar líneas de producto frente a no-producto (descuentos, bolsas, redondeos, subtotales, total).
- [ ] **E3-1** — Extraer cabecera del ticket: comercio, RUC, número de comprobante, fecha y hora.
- [ ] **E3-4** — Reintentos con espera creciente y tope máximo.
- [ ] **E3-5** — Registrar coste, tokens y latencia de cada extracción.
- [ ] **E9-3** — Descartar en la extracción cualquier dato personal (titular, dígitos de tarjeta, número de socio) para que nunca llegue a la base.

### Revisión

- [ ] **E4-1** — Pantalla de revisión: tabla editable con todos los ítems extraídos.
- [ ] **E4-2** — Vista de la imagen junto a los datos, con ampliación.
- [ ] **E4-3** — Añadir y eliminar filas antes de confirmar.
- [ ] **E4-4** — Destacar los campos de baja confianza y ordenarlos al principio.
- [ ] **E4-5** — Fecha y comercio obligatorios; rechazar fechas futuras o fuera de un rango razonable.
- [ ] **E3-6** — Formulario de carga manual como alternativa, con lo ya extraído precargado.

### Persistencia

- [ ] **E4-1** — Endpoint de confirmación: persiste ticket, ítems y observaciones de precio en una transacción.
- [ ] **E8-3** — Validación aritmética antes de persistir: suma de ítems frente a total, dentro de tolerancia, y coherencia del IVA.
- [ ] **E8-2** — Rechazar duplicados por `sha256` y por la tupla `(RUC, número de comprobante, fecha, total)`.
- [ ] **E2** — Pantalla de agradecimiento con acceso directo a subir otro ticket.
- [ ] — Prueba de punta a punta con un ticket real de cada una de las tres cadenas más habituales.

---

## Fase 2 — Normalización e índice

> **Objetivo comprobable:** con un conjunto de tickets de prueba cargado, el sistema produce un índice de Jevons por categoría, reproducible y verificado a mano sobre una categoría pequeña.

### Catálogo

- [ ] **E5-1** — Entidad de producto canónico: nombre, marca, presentación, unidad de medida y categoría.
- [ ] **E5-3** — Normalizador de unidades: `2L`, `2.0 LT` y `2000 ML` resuelven a la misma unidad base; cálculo del precio por unidad normalizada.
- [ ] **E5-6** — Entidad de comercio con cadena y sucursal, resuelta por RUC cuando esté disponible.
- [ ] **E5-4** — Cargar la jerarquía de categorías según lo resuelto en S2.
- [ ] **E5-2** — Emparejado automático de descripciones con productos canónicos, por similitud textual y de precio.
- [ ] **E5-2** — Umbral de confianza: por debajo de él, el emparejado queda pendiente en lugar de asumirse.
- [ ] **E5-5** — Herramienta interna de curación: bandeja de pendientes, confirmar, reasignar, crear canónico y fusionar duplicados.
- [ ] **E5-5** — Registro de auditoría de las acciones de curación, con posibilidad de revertir.
- [ ] **E5** — Métrica de porcentaje de emparejado automático, para vigilar el riesgo R6.

### Cálculo

- [ ] **E6-1** — Cálculo del precio representativo de cada producto por periodo (mediana de sus observaciones).
- [ ] **E6-1** — Cálculo del relativo de precio entre periodos consecutivos.
- [ ] **E6-2** — Índice de Jevons por categoría sobre productos emparejados en ambos periodos.
- [ ] **E6-3** — Agregación ponderada a índice general, con ponderaciones configurables y versionadas.
- [ ] 🚧 **E6-3 (S2)** — Decidir el ámbito geográfico del índice propio. El IPC del BCP cubre **sólo el Área Metropolitana de Asunción** (Asunción, Luque, Fernando de la Mora, Lambaré, San Lorenzo, Capiatá, Ñemby, Mariano Roque Alonso y Limpio). O acotamos nuestra cobertura a lo mismo, o acotamos la comparación de E7-3 a los tickets de esa zona, o publicamos la superposición con la advertencia explícita. Decidir antes de escribir `docs/metodologia.md`: cambia lo que el portal promete.
- [ ] **E6-3 (S2)** — Etiquetar cada serie con la versión de canasta y la base del IPC usadas. La **EPF 2025-2026** terminó su recogida en septiembre de 2026 y va a cambiar ponderaciones y estructura: cuando el BCP difunda la nueva canasta habrá que empalmar, y sin la etiqueta no se sabrá qué se está comparando.
- [ ] **E6-4** — 🚧 Umbrales mínimos de observaciones: por debajo de ellos la categoría se marca *sin datos suficientes* y no publica cifra.
- [ ] **E6-5** — Proceso de recálculo del histórico, idempotente y reproducible, con versión de metodología asociada a cada serie.
- [ ] **E6** — Persistir el índice calculado por periodo, con su número de observaciones y productos emparejados.
- [ ] **E6** — Verificar el cálculo a mano sobre una categoría pequeña, contrastando contra una hoja de cálculo independiente.
- [ ] **E6-6** — Redactar `docs/metodologia.md`: fórmula, fuentes, umbrales y limitaciones conocidas. Entre las limitaciones, la que S2 dejó por escrito: el IPC es una canasta fija y nuestros tickets son compras concretas, así que la comparación contextualiza pero no prueba que nuestra muestra reproduzca la canasta oficial.

---

## Fase 3 — Portal público y antifraude

> **Objetivo comprobable:** el índice es visible en público junto a su cobertura y al IPC oficial, y un intento deliberado de inyectar precios falsos queda retenido y no altera la serie.

### Portal

- [ ] **E7-6** — Página de inicio: la propuesta en una frase y acceso directo a subir un ticket.
- [ ] **E7-1** — Cifra del índice general del último periodo cerrado, con fecha y número de observaciones.
- [ ] **E7-2** — Gráfico de la serie histórica con selector de periodo.
- [ ] **E7-3** — Superponer la serie oficial del IPC, citando fuente y fecha de actualización. La licencia de información pública del BCP lo permite, pero exige citar y **no sugerir aval ni patrocinio oficial**: nada de logos del BCP ni de presentación que insinúe respaldo. Conservar el fichero descargado con su URL y fecha, no depender de la página dinámica.
- [ ] **E7-4** — Desglose por categoría, ordenable, con las categorías sin datos suficientes marcadas como tales.
- [ ] **E7-5** — Panel de cobertura: tickets procesados, productos con seguimiento, comercios y periodo cubierto.
- [ ] **E7** — Enlazar `docs/metodologia.md` desde el portal.
- [ ] **E7** — Diseño adaptable a móvil y revisión de accesibilidad.

### Antifraude

- [ ] **E8-1** — Límite de envíos por IP y ventana temporal, configurable, con mensaje claro al superarlo.
- [ ] **E8-6** — Validación temprana de que la imagen es un comprobante, antes de gastar una llamada al modelo.
- [ ] **E8-4** — Detección de precios atípicos contra la distribución histórica del producto.
- [ ] **E8-4** — Retener los atípicos fuera del cálculo hasta que se revisen.
- [ ] **E8-5** — Cola de moderación: motivo de retención y acciones de aprobar, rechazar y corregir.
- [ ] **E8-5** — Recalcular el índice afectado tras cada decisión de moderación.
- [ ] **E8** — Prueba adversaria: intentar envenenar deliberadamente una categoría y comprobar que los controles lo detienen.

---

## Fase 4 — Endurecimiento y lanzamiento

> **Objetivo comprobable:** el sistema aguanta la carga prevista, cumple lo que promete sobre privacidad y está listo para recibir tráfico real.

### Privacidad

- [ ] **E9-2** — 🚧 Proceso programado de borrado de imágenes vencidas, con registro auditable de cada borrado.
- [ ] **E9-2** — Verificar en un entorno real que la imagen ya no existe pasado el plazo.
- [ ] **E9-4** — Redactar y publicar la política de privacidad en lenguaje llano, enlazada desde el flujo de subida.
- [ ] **E9-3** — Auditar la base de datos para confirmar que no se coló ningún dato personal.

### Observabilidad

- [ ] **E10-1** — Identificador de correlación de punta a punta, presente en todos los registros.
- [ ] **E10-2** — Métricas del embudo: subidas iniciadas, extracciones completadas, confirmaciones y persistidas, con sus tasas de abandono.
- [ ] **E10-3** — Panel de coste de IA por día y por ticket, con alerta por umbral.
- [ ] **E10-4** — Alertas por tasa de error de extracción, caída de la API y crecimiento anómalo de la cola de moderación.
- [ ] **E3-7** — Automatizar la medición de precisión contra el conjunto de referencia de S4 y comparar entre versiones del prompt.

### Rendimiento y lanzamiento

- [ ] — Prueba de carga sobre la subida y la extracción; fijar el objetivo de tickets simultáneos que se debe soportar.
- [ ] — Revisar los tiempos del cálculo del índice sobre un volumen realista de datos.
- [ ] — Revisión de seguridad: validación de entradas, límites de subida, cabeceras y exposición de la API.
- [ ] — Copias de seguridad de la base de datos y prueba real de restauración.
- [ ] — Términos de uso y aviso legal.
- [ ] — Definir el plan de captación inicial: concentrar los primeros tickets en pocas cadenas y productos de alta rotación, para conseguir emparejados cuanto antes (riesgo R2).
- [ ] — Definir qué se comunica mientras no haya datos suficientes: cobertura, nunca una cifra de inflación sin respaldo.

---

## Notas de secuencia

- **~~S1 antes que E3~~ — resuelto: E3 sigue en pie.** El QR no da el detalle de ítems; lo da el XML del Documento Electrónico, y sólo al receptor que además es facturador electrónico. Admitir ese XML es una mejora que vale la pena —ahorra la llamada al modelo y trae el dato firmado en origen— pero es una vía paralela, no un sustituto: hasta 2027 seguirán llegando tickets sin él. Construir E3.
- **E5 es la épica larga.** La normalización de productos condiciona todo lo que viene después: conviene empezarla en cuanto haya tickets reales en la base, incluso en paralelo con el final de la Fase 1.
- **El antifraude no se pospone.** Está en la Fase 3 porque necesita datos y portal, pero las piezas baratas — deduplicación y validación aritmética — ya entran en la Fase 1.
- **Sin datos no hay índice.** Las fases 2 y 3 necesitan tickets reales acumulados; conviene empezar a recolectarlos en cuanto la Fase 1 funcione, aunque el portal aún no exista.
