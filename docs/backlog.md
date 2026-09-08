# Backlog de producto — Calculador de Inflación Colaborativo

> Documento vivo. Recoge el **qué** y el **porqué**. Las tareas de ejecución están en [todo.md](todo.md).

---

## 1. Visión

Una aplicación web donde cualquier persona, **sin necesidad de registrarse**, adjunta la foto de un ticket de supermercado. La aplicación extrae los productos y sus precios, y con la acumulación de esos tickets construye un **índice de inflación medido con datos reales de la gente**, publicado y contrastable con el IPC oficial.

El valor no está en leer un ticket: está en que miles de tickets, agregados, produzcan una medición independiente de cómo suben los precios en la calle.

**Mercado inicial:** Paraguay. Moneda: guaraní (PYG). Índice oficial de contraste: IPC publicado por el Banco Central del Paraguay (BCP).

---

## 2. Alcance del MVP

**Dentro:**

- Subida anónima de la imagen de un ticket desde móvil o escritorio.
- Extracción automática de ítems, precios, fecha y comercio mediante un modelo de IA multimodal.
- Pantalla de revisión donde la persona corrige lo que el modelo haya leído mal, antes de guardar.
- Normalización de productos a un catálogo canónico.
- Cálculo del índice de inflación por categoría y general.
- Portal público con la evolución del índice y su comparación con el IPC oficial.
- Controles de calidad de datos y antifraude.

**Fuera (explícitamente):**

- Cuentas de usuario, perfiles, inicio de sesión.
- Aplicación móvil nativa.
- Comparador de precios entre supermercados como producto de cara al usuario (el dato existe, pero no se expone en el MVP).
- Cobertura de países más allá de Paraguay.
- Recompensas, ranking o gamificación de aportes.

---

## 3. Decisiones ya tomadas

| # | Decisión | Detalle |
|---|---|---|
| D1 | **La imagen no se conserva** | Se guarda en almacenamiento temporal, se procesa y se **borra a las 72 h** (retención configurable). Se persisten solo los datos estructurados más el `sha256` del archivo para detectar reenvíos. Los tickets llevan RUC, timbrado y a veces dígitos de tarjeta: custodiarlos crea una obligación que el MVP no necesita. |
| D2 | **Método de cálculo: índice de Jevons** | Media geométrica de los relativos de precio sobre productos emparejados entre dos periodos, agregada por categoría con ponderaciones de la canasta oficial. Es el método habitual en índices construidos con precios escaneados y tolera muestras irregulares. |
| D3 | **La normalización de productos es el núcleo** | No el OCR. `COCA COLA 2LT`, `GASEOSA COCA-COLA 2.0 L` y `COCA 2L` deben colapsar en un mismo SKU canónico con su unidad de medida, o el índice no mide nada. Tiene épica propia (E5). |
| D4 | **Sin login, la calidad del dato es el riesgo principal** | Un puñado de envíos basura envenena el índice. El antifraude entra en el MVP, no después (E8). |
| D5 | **Extracción: IA multimodal + revisión humana** | El modelo propone, la persona confirma. Nunca se guarda un dato extraído que nadie haya visto. |
| D6 | **Arranque en frío asumido** | No hay inflación calculable hasta observar el mismo producto en dos momentos distintos. Hasta superar el umbral mínimo de observaciones, la aplicación muestra **cobertura**, no inflación. Es una etapa esperada del producto, no un fallo. |

**Stack:** Angular (front) + .NET (API), en monorepo.

---

## 4. Particularidades de Paraguay

Requisitos que el modelo de datos y las validaciones deben respetar desde el primer día:

- **El guaraní no usa decimales** y el separador de miles es el punto: `₲ 15.000` son quince mil guaraníes, no quince. Todo el parseo, la validación y el formateo deben asumirlo; heredar el formato decimal de otras monedas produciría errores de tres órdenes de magnitud.
- Los comprobantes legales llevan **RUC** del emisor, **timbrado** y número de comprobante con formato `001-001-0000001`.
- Existen **dos tasas de IVA** (10 % general y una reducida), lo que condiciona la validación aritmética del ticket.
- Los comprobantes electrónicos llevan **código QR** → ver *spike* S1.

---

## 5. Épicas

Prioridad en notación MoSCoW · Estimación relativa: **S** (días) · **M** (1–2 semanas) · **L** (3–4 semanas) · **XL** (más de un mes)

---

### E1 · Fundaciones del monorepo — `Must` · **M**

**Objetivo:** que cualquier persona clone el repositorio y tenga front y API corriendo en un comando, con integración continua desde el primer commit.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E1-1 | Como desarrollador quiero un monorepo con el front Angular y la API .NET para trabajar en ambos sin saltar entre repositorios. | Estructura de carpetas documentada; `apps/web` y `apps/api` compilan de forma independiente; existe un README de arranque. |
| E1-2 | Como desarrollador quiero levantar todo el entorno con un comando para no perder tiempo en configuración manual. | Un único comando levanta front, API y base de datos; funciona en Windows y Linux. |
| E1-3 | Como desarrollador quiero CI en cada push para detectar roturas antes de mezclar. | La CI compila front y API, ejecuta pruebas y falla el pull request si algo se rompe. |
| E1-4 | Como desarrollador quiero configuración por entorno para no mezclar claves de desarrollo y producción. | Ningún secreto en el repositorio; los tres entornos (local, staging, producción) leen su configuración de variables de entorno. |

---

### E2 · Captura del ticket — `Must` · **M**

**Objetivo:** que subir un ticket desde el móvil, de pie en la puerta del supermercado, sea trivial. Cada segundo de fricción cuesta datos.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E2-1 | Como persona quiero adjuntar la foto de mi ticket sin registrarme para colaborar en dos toques. | Se puede subir sin cuenta; acepta JPG, PNG, HEIC y PDF; funciona con la cámara del móvil. |
| E2-2 | Como persona quiero ver la imagen antes de enviarla para comprobar que se lee. | Previsualización con opción de recortar, rotar y reemplazar el archivo. |
| E2-3 | Como persona quiero un límite claro de tamaño y un mensaje útil si falla para no quedarme adivinando. | Límite de tamaño validado en cliente y servidor; mensajes de error concretos, nunca un código genérico. |
| E2-4 | Como persona quiero ver el progreso mientras se procesa mi ticket para saber que no se colgó. | Indicador de estado durante la subida y la extracción; si tarda más de lo previsto, se avisa en pantalla. |
| E2-5 | Como persona quiero subir un ticket muy largo en varias fotos para que entre completo. | Se admiten varias imágenes como un único ticket, procesadas en orden. |

---

### E3 · Extracción con IA multimodal — `Must` · **L**

**Objetivo:** convertir la foto en JSON estructurado con la máxima precisión posible, con coste y latencia acotados.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E3-1 | Como sistema quiero enviar la imagen a un modelo de visión y recibir los ítems en un esquema JSON fijo para procesarlos sin ambigüedad. | Esquema JSON versionado (comercio, RUC, fecha, hora, ítems con descripción/cantidad/unidad/precio unitario/precio total, subtotal, IVA, total); toda respuesta se valida contra el esquema antes de usarse. |
| E3-2 | Como sistema quiero distinguir líneas de producto de líneas que no lo son para no contaminar el índice. | Descuentos, bolsas, redondeos, propinas, subtotales y totales se marcan como no-producto y quedan fuera del cálculo. |
| E3-3 | Como sistema quiero interpretar correctamente los importes en guaraníes para no equivocarme en tres órdenes de magnitud. | `15.000` se interpreta como 15000; existen pruebas específicas de este formato; cualquier importe con decimales se marca como sospechoso para revisión. |
| E3-4 | Como sistema quiero reintentar de forma acotada cuando la extracción falla para no perder el envío por un error transitorio. | Reintentos con espera creciente y tope; tras agotarlos, la persona pasa a carga manual sin perder lo ya subido. |
| E3-5 | Como responsable del producto quiero conocer el coste y la latencia por ticket para saber si el modelo es viable a escala. | Se registra coste, tokens y duración por extracción; hay un panel con la media y la cola alta de latencia. |
| E3-6 | Como persona quiero poder cargar los datos a mano si la foto no se deja leer para no quedarme sin aportar. | Formulario manual disponible siempre como alternativa; los ítems que sí se leyeron llegan precargados. |
| E3-7 | Como responsable del producto quiero medir la precisión de la extracción para saber si mejora o empeora al cambiar el prompt o el modelo. | Conjunto de tickets de referencia con su transcripción correcta; se calcula precisión por campo; el resultado se compara entre versiones del prompt. |

---

### E4 · Revisión y confirmación — `Must` · **M**

**Objetivo:** el humano es la última red de seguridad. Ningún dato entra en la base sin que alguien lo haya mirado.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E4-1 | Como persona quiero revisar lo que la IA leyó de mi ticket antes de enviarlo para corregir sus errores. | Tabla editable con todos los ítems; cada campo es modificable; nada se persiste hasta la confirmación explícita. |
| E4-2 | Como persona quiero ver la imagen junto a los datos extraídos para comparar sin cambiar de pantalla. | Vista lado a lado; al seleccionar un ítem se resalta su zona en la imagen (o, como mínimo, la imagen queda visible y ampliable). |
| E4-3 | Como persona quiero borrar líneas que no me interesan para no enviar lo que no corresponde. | Se pueden eliminar y volver a añadir filas antes de confirmar. |
| E4-4 | Como persona quiero que se me avisen las lecturas dudosas para revisar primero lo importante. | Los campos con baja confianza aparecen destacados y ordenados al principio de la revisión. |
| E4-5 | Como persona quiero confirmar la fecha y el comercio del ticket porque son la clave de todo el cálculo. | Fecha y comercio son obligatorios; si la extracción no los obtuvo, se piden expresamente; una fecha futura o anterior a un límite razonable se rechaza. |

---

### E5 · Catálogo y normalización de productos — `Must` · **XL**

**Objetivo:** que el mismo producto sea el mismo producto entre tickets, comercios y meses. Es la épica que decide si el índice significa algo.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E5-1 | Como sistema quiero un catálogo de productos canónicos para agrupar las descripciones libres de los tickets. | Entidad de producto canónico con nombre, marca, presentación, unidad de medida y categoría; una descripción de ticket apunta a un único canónico. |
| E5-2 | Como sistema quiero emparejar automáticamente descripciones nuevas con productos ya conocidos para no depender de trabajo manual. | Emparejado por similitud textual y de precio; cada emparejado guarda su nivel de confianza; por debajo del umbral queda pendiente de revisión, nunca se asume. |
| E5-3 | Como sistema quiero normalizar unidades de medida para poder comparar presentaciones distintas. | `2L`, `2.0 LT` y `2000 ML` se resuelven a la misma unidad base; se calcula y almacena el precio por unidad normalizada. |
| E5-4 | Como analista quiero clasificar cada producto en la categoría de la canasta oficial para poder agregar y comparar con el IPC. | Cada producto canónico tiene categoría; la jerarquía sigue la de la canasta oficial (ver *spike* S2); ningún producto activo queda sin clasificar. |
| E5-5 | Como administrador quiero una herramienta interna para resolver emparejados dudosos y fusionar duplicados para mantener el catálogo sano. | Bandeja de emparejados pendientes; acciones de confirmar, reasignar, crear canónico y fusionar; toda acción queda registrada y es reversible. |
| E5-6 | Como sistema quiero normalizar también el comercio para no tratar dos sucursales como cadenas distintas. | Entidad de comercio con cadena y sucursal, resuelta por RUC cuando esté disponible. |

---

### E6 · Motor de cálculo del índice — `Must` · **L**

**Objetivo:** convertir observaciones de precio en un índice defendible, con su metodología escrita.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E6-1 | Como analista quiero calcular la variación de precio de cada producto entre dos periodos para tener la base del índice. | Relativo de precio por producto canónico entre periodos consecutivos, usando la mediana de las observaciones del periodo para amortiguar valores extremos. |
| E6-2 | Como analista quiero agregar esas variaciones con media geométrica por categoría para obtener el índice de cada categoría. | Índice de Jevons por categoría; solo entran productos observados en ambos periodos; el número de productos emparejados se publica junto al resultado. |
| E6-3 | Como analista quiero un índice general ponderado por la canasta oficial para que sea comparable con el IPC. | Agregación ponderada de las categorías; las ponderaciones son configurables y versionadas, con su fuente documentada. |
| E6-4 | Como responsable del producto quiero que el índice no se publique sin datos suficientes para no difundir una cifra sin respaldo. | Umbral mínimo configurable de productos emparejados y observaciones por categoría; por debajo del umbral la categoría se muestra como *sin datos suficientes*, nunca con una cifra. |
| E6-5 | Como analista quiero recalcular el histórico completo cuando cambie la metodología o se corrijan datos para mantener la serie coherente. | El recálculo es idempotente y reproducible; cada versión de la serie guarda la versión de metodología con la que se generó. |
| E6-6 | Como lector quiero leer la metodología del índice para juzgar si me fío. | Documento público que explica fórmula, fuentes, umbrales y limitaciones conocidas, enlazado desde el portal. |

---

### E7 · Portal público de resultados — `Must` · **M**

**Objetivo:** que el dato se vea. Sin esto el proyecto no tiene cara visible ni motivo para que nadie suba un ticket.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E7-1 | Como visitante quiero ver la inflación medida del último mes para saber en qué anda el proyecto. | Cifra del índice general del último periodo cerrado, con su fecha y su número de observaciones. |
| E7-2 | Como visitante quiero ver la evolución en el tiempo para entender la tendencia. | Gráfico de la serie histórica con selector de periodo. |
| E7-3 | Como visitante quiero comparar con el IPC oficial para ver si coinciden. | Serie oficial superpuesta a la propia, con su fuente y fecha de actualización citadas (ver *spike* S2). |
| E7-4 | Como visitante quiero ver el detalle por categoría para saber qué es lo que sube. | Desglose por categoría, ordenable; las categorías sin datos suficientes se muestran como tales. |
| E7-5 | Como visitante quiero saber cuántos datos hay detrás para calibrar mi confianza. | Panel de cobertura: tickets procesados, productos con seguimiento, comercios y periodo cubierto, visible junto al índice. |
| E7-6 | Como visitante quiero entender qué es esto en diez segundos para decidir si colaboro. | Página de inicio con la propuesta en una frase y un acceso directo a subir un ticket. |

---

### E8 · Calidad de datos y antifraude — `Must` · **L**

**Objetivo:** sin login, cualquiera puede intentar envenenar el índice. Estos controles son parte del MVP, no un endurecimiento posterior.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E8-1 | Como sistema quiero limitar los envíos por origen para frenar la carga masiva automatizada. | Límite por IP y ventana temporal, configurable; al superarlo se responde con un mensaje claro, no con un error opaco. |
| E8-2 | Como sistema quiero detectar el mismo ticket enviado dos veces para no contar un precio dos veces. | Deduplicación por `sha256` de la imagen y por la tupla `(RUC, número de comprobante, fecha, total)`; el duplicado se rechaza informando el motivo. |
| E8-3 | Como sistema quiero verificar que el ticket cuadra aritméticamente para descartar datos inventados o mal leídos. | La suma de ítems debe aproximarse al total dentro de una tolerancia; el IVA debe ser coherente; lo que no cuadra va a revisión, no al índice. |
| E8-4 | Como sistema quiero detectar precios atípicos para que un error de un dígito no distorsione la categoría. | Detección de atípicos contra la distribución histórica del producto; los valores extremos quedan retenidos para revisión antes de entrar en el cálculo. |
| E8-5 | Como administrador quiero una cola de moderación para resolver lo que quedó retenido. | Bandeja con motivo de la retención; acciones de aprobar, rechazar y corregir; el efecto sobre el índice se recalcula tras la decisión. |
| E8-6 | Como sistema quiero descartar imágenes que no son tickets para no gastar llamadas al modelo. | Validación temprana de que la imagen es un comprobante; si no lo es, se informa sin consumir el presupuesto de extracción. |

---

### E9 · Privacidad y retención de datos — `Must` · **S**

**Objetivo:** cumplir la decisión D1 y poder explicarla en público sin rodeos.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E9-1 | Como persona quiero saber qué pasa con la foto que subo antes de subirla. | Aviso visible en la pantalla de subida: la imagen se borra a las 72 h y solo se conservan los datos de precios. |
| E9-2 | Como sistema quiero borrar automáticamente las imágenes vencidas para cumplir lo prometido. | Proceso programado de borrado; el plazo es configurable; queda registro auditable de cada borrado ejecutado. |
| E9-3 | Como sistema quiero no persistir datos personales del ticket para reducir la superficie de riesgo. | Nombres de titular, dígitos de tarjeta y números de socio se descartan en la extracción y nunca llegan a la base. |
| E9-4 | Como persona quiero leer una política de privacidad clara para saber a qué atenerme. | Política publicada y enlazada desde el flujo de subida, redactada en lenguaje llano. |

---

### E10 · Observabilidad y operación — `Should` · **M**

**Objetivo:** saber si el sistema funciona y cuánto cuesta, antes de que lo pregunte un usuario.

| ID | Historia | Criterios de aceptación |
|---|---|---|
| E10-1 | Como operador quiero trazabilidad de punta a punta de cada ticket para diagnosticar un envío concreto. | Identificador de correlación desde la subida hasta la persistencia, presente en todos los registros. |
| E10-2 | Como operador quiero métricas del embudo para saber dónde se pierde la gente. | Métricas de subidas iniciadas, extracciones completadas, confirmaciones y tickets persistidos, con sus tasas de abandono. |
| E10-3 | Como responsable del producto quiero vigilar el coste de IA para que no se dispare sin aviso. | Coste acumulado por día y por ticket; alerta al superar un umbral configurable. |
| E10-4 | Como operador quiero alertas ante fallos para enterarme antes que los usuarios. | Alertas por tasa de error de extracción, caída de la API y crecimiento anómalo de la cola de moderación. |

---

### E11 · Post-MVP — `Could` / `Won't (ahora)` · **XL**

Ideas registradas para no perderlas. Ninguna entra en el MVP.

- Cuentas de usuario opcionales: historial propio de tickets y seguimiento del gasto personal.
- Gamificación: ranking de aportes, insignias, medición del impacto de cada colaborador sobre el índice.
- API pública de la serie del índice, con datos abiertos descargables.
- Aplicación móvil nativa con cámara integrada y envío en segundo plano.
- Comparador de precios por comercio de cara al usuario.
- Alertas personalizadas por producto seguido.
- Extensión a otros países: el modelo de datos ya contempla país y moneda, pero la canasta y las validaciones son específicas de cada mercado.
- Corpus consentido de imágenes para evaluar y ajustar la precisión del modelo (requiere consentimiento explícito y revisar D1).

---

## 6. Riesgos

| # | Riesgo | Impacto | Mitigación |
|---|---|---|---|
| R1 | **Envenenamiento del índice.** Sin login, un actor decidido puede inyectar precios falsos. | Crítico — destruye la credibilidad del producto | Épica E8 completa dentro del MVP; umbrales de publicación (E6-4); moderación de atípicos. |
| R2 | **Arranque en frío.** Sin masa crítica de tickets no hay índice publicable durante los primeros meses. | Alto | Comunicar cobertura en lugar de inflación (D6, E7-5); concentrar la captación en pocas cadenas y productos de alta rotación para emparejar antes. |
| R3 | **Coste de IA por ticket a escala.** El gasto crece linealmente con el éxito. | Alto | Medición desde el día uno (E3-5, E10-3); descarte temprano de imágenes inválidas (E8-6); admitir el XML del comprobante electrónico cuando el usuario pueda aportarlo, que ahorra la llamada al modelo — pero S1 lo deja como mejora parcial y no como salida del riesgo: hasta 2027 seguirán llegando tickets sin XML. |
| R4 | **Sesgo de muestra.** Quien sube tickets probablemente compra en cadenas grandes del área metropolitana: el índice mediría esa realidad, no la del país. | Alto — afecta a la validez de la conclusión | Publicar siempre la composición de la muestra; declarar la limitación en la metodología (E6-6); ponderar por canasta oficial, no por volumen de tickets. |
| R5 | **Precisión sobre papel térmico degradado.** Tickets arrugados, descoloridos o cortados. | Medio | Revisión humana obligatoria (E4); medición continua de precisión (E3-7); alternativa manual siempre disponible (E3-6). |
| R6 | **La normalización no escala.** Si cada producto nuevo exige intervención manual, el catálogo se convierte en un cuello de botella permanente. | Alto | Emparejado automático con umbral de confianza (E5-2); medir el porcentaje de emparejado automático como métrica de salud del sistema. |
| R7 | **Divergencia con el IPC oficial mal interpretada.** Una diferencia grande puede leerse como error del proyecto o como polémica pública. | Medio | Metodología pública y explícita sobre qué mide y qué no (E6-6); mostrar la cobertura junto a cada cifra. |

---

## 7. *Spikes*

Investigaciones a cerrar antes de comprometer diseño. Las de la primera tabla ya están respondidas y su informe está en `docs/spikes/`; las de la segunda **siguen sin verificar**.

### Cerrados

| # | *Spike* | Respuesta | Qué decide |
|---|---|---|---|
| S1 | **QR de comprobante electrónico** | **Parcial.** El detalle de ítems sí se obtiene programáticamente, pero del **XML del Documento Electrónico** que el emisor entrega al receptor —no del QR, que sólo lleva a una consulta pública de validez con reCAPTCHA, sin API de lectura masiva. 19.658 emisores activos al 15-11-2025 y cronograma de incorporación hasta el 01-09-2027. | **E3 se mantiene como camino principal.** El parser de XML entra como mejora aparte, no como sustituto: durante toda la transición seguirán llegando tickets sin XML. Ver [S1-qr-comprobante.md](spikes/S1-qr-comprobante.md). |
| S2 | **Datos oficiales del IPC** | **Sí, como referencia agregada y con atribución.** El BCP publica el IPC mensual, anexos en hoja de cálculo y PDF, y una serie empalmada desde 1950; las ponderaciones de la EPF 2015/16 (base dic-2017 = 100) son reutilizables bajo su licencia de información pública, citando fuente y fecha y sin sugerir aval oficial. | Decae la alternativa de ponderación propia. Aparecen dos límites nuevos: la cobertura es **sólo el Área Metropolitana de Asunción**, y la **EPF 2025-2026** cambiará la canasta. Ver [S2-ipc-oficial.md](spikes/S2-ipc-oficial.md). |

### Pendientes

**Ninguna de estas afirmaciones está verificada todavía.**

| # | *Spike* | Pregunta a responder | Por qué importa |
|---|---|---|---|
| S3 | **Almacenamiento temporal** | ¿Qué proveedor cumple el borrado automático por TTL, con coste razonable y latencia aceptable desde Paraguay? | Condiciona E2, E9-2 y el coste operativo. |
| S4 | **Elección del modelo de visión** | Precisión, coste y latencia sobre un conjunto de tickets paraguayos reales. | Decide la viabilidad económica de E3. Debe resolverse con tickets reales, no con ejemplos sintéticos. |

---

## 8. Glosario

- **Producto canónico:** entrada única del catálogo a la que apuntan todas las descripciones de ticket que designan el mismo producto.
- **Relativo de precio:** cociente entre el precio de un producto en el periodo actual y en el anterior.
- **Índice de Jevons:** media geométrica de los relativos de precio de los productos emparejados.
- **Emparejado (*matching*):** proceso de asociar la descripción libre de un ticket con un producto canónico.
- **Cobertura:** volumen y variedad de datos que respaldan un índice en un periodo dado.
