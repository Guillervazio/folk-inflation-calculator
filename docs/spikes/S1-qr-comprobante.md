# S1 — Verificación y detalle de ítems de comprobantes electrónicos por QR

Fecha de consulta: 8 de septiembre de 2026.

## Veredicto: parcial

**Sí es viable obtener programáticamente el detalle de ítems, pero no a partir
del QR público por sí solo.** Para un receptor que también es facturador
electrónico, el emisor debe enviar o poner a disposición el XML del Documento
Electrónico (DE), que el receptor puede descargar. Ese XML es la fuente
estructurada y firmada que un parser debe consumir; el Manual Técnico define su
estructura, incluidos los grupos de ítems. En cambio, el QR/CDC lleva a la
consulta pública de validez del DTE, no a una API pública anónima de extracción
masiva de ítems.

## Qué aporta cada vía

- **XML del DE: detalle utilizable.** El Decreto N.º 872, art. 25, obliga al
  emisor a enviar al receptor facturador electrónico el archivo XML y KuDE por
  web service, mensajería, correo o portal para descarga. El sistema define XML
  como la representación electrónica del comprobante; su Manual Técnico publica
  la estructura XML y los campos de detalle. Por ello el proyecto puede extraer
  líneas, cantidades, precios e impuestos del XML que le entregue o habilite el
  emisor, preservando XML original, CDC, fecha de descarga y resultado de
  validación como evidencia.
- **QR/CDC: autenticidad y contraste.** e-Kuatia permite consultar públicamente
  existencia, estado y validez del DTE mediante CDC o QR del KuDE. La inspección
  manual de la consulta pública el 8 de septiembre de 2026 mostró un reCAPTCHA;
  es apropiada para la comprobación humana de un caso, no para automatización
  continua o masiva sin una habilitación específica.
- **Límite material.** El XML prueba el contenido del documento tributario
  aprobado, no por sí mismo que la compra o entrega real haya ocurrido. Además,
  para receptores que no son facturadores electrónicos la obligación ordinaria
  es entregar el KuDE (impreso, PDF o disponible en portal), no el XML. Por eso
  la adquisición de ítems es completa sólo donde se obtenga el XML por el canal
  del emisor/receptor o mediante servicios SIFEN habilitados.

## Cobertura y evolución

La Memoria Anual 2025 de la DNIT informa **19.658 contribuyentes activos en
SIFEN al 15 de noviembre de 2025**. No equivale a la totalidad de comercios ni
a la cobertura de todas las compras: describe emisores electrónicos activos.
La incorporación sigue ampliándose: la RG N.º 52 prevé seis grupos adicionales
con inicios entre junio de 2026 y **1 de septiembre de 2027**, para cerca de
3.000 contribuyentes. La cobertura potencial crecerá, pero durante la transición
seguirán coexistiendo comprobantes no electrónicos y receptores sin XML.

## Recomendación para el proyecto

Mantener **E3** —la extracción con IA a partir de la foto— como camino principal,
y sumar una mejora separada: ingreso/recepción autorizada del XML, parser
versionado contra el XSD
de SIFEN, normalización de ítems y conservación del XML y su hash. El QR debe
registrarse como evidencia de contraste, no como la fuente programática de las
líneas de compra ni como una promesa de cobertura universal.

## Fuentes

1. Dirección Nacional de Ingresos Tributarios (DNIT), [Decreto N.º 872, art. 25](https://www.dnit.gov.py/documents/20123/1259326/DECRETO_872.pdf/10a38d31-769f-388d-103f-6f5de177730d?t=1731348014754), consultado el 8 de septiembre de 2026.
2. DNIT, [Información e-Kuatia](https://www.dnit.gov.py/en/web/e-kuatia/informacion), consultada el 8 de septiembre de 2026.
3. DNIT, [Manual Técnico SIFEN, versión 1.5.0](https://www.dnit.gov.py/documents/20123/420592/Manual%2BT%C3%A9cnico%2BVersi%C3%B3n%2B150.pdf/e706f7c7-6d93-21d4-b45b-5d22d07b2d22?t=1687351495907), consultado el 8 de septiembre de 2026.
4. DNIT, [Consulta pública de validez de DTE/KuDE](https://www.dnit.gov.py/en/web/e-kuatia/preguntas-frecuentes/-/categories/2705546?p_r_p_categoryId=2705546), consultada el 8 de septiembre de 2026.
5. DNIT, [Memoria Anual 2025](https://www.dnit.gov.py/documents/20123/1426452/MEMORIA%2BANUAL%2B2025%2Bactualizado%2B29-01.pdf/7e6274eb-9e84-6da4-542a-99cf827a1928?t=1769696936360), consultada el 8 de septiembre de 2026.
6. DNIT, [Nuevos facturadores electrónicos y cronograma RG N.º 52](https://www.dnit.gov.py/en/web/portal-institucional/w/dnit-designa-nuevos-facturadores-electr%C3%B3nicos), consultada el 8 de septiembre de 2026.
