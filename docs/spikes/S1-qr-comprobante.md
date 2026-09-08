# S1 — Verificación de comprobantes electrónicos por QR

Fecha de consulta: 8 de septiembre de 2026.

## Hallazgo

En Paraguay, un comprobante electrónico se puede contrastar contra el Sistema
Integrado de Facturación Electrónica Nacional (SIFEN) mediante la consulta
pública de e-Kuatia. El punto de entrada comunicado por la DNIT es
`https://ekuatia.set.gov.py/consultas/`: admite el Código de Control (CDC) o
la lectura del QR de la representación gráfica (KuDE). La DNIT indica que con
ello el receptor puede corroborar existencia, coincidencia, estado y validez
del DTE en SIFEN.

La inspección manual de la consulta pública el 8 de septiembre de 2026 mostró
un desafío reCAPTCHA antes de enviar la búsqueda. Por tanto, el QR sirve para
llevar a una comprobación pública humana, pero el flujo web no es una API
anónima apta para automatizar en bloque. Tampoco prueba por sí solo que la
operación comercial sea verdadera: la propia DNIT aclara que la aprobación del
SIFEN no limita sus posteriores facultades de fiscalización.

## Qué contiene y qué permite verificar

- El **KuDE** es la representación gráfica del documento electrónico. El QR o
  el CDC suministran el criterio de búsqueda pública; el manual técnico
  describe además un código de seguridad aleatorio para resguardar la
  confidencialidad de esa consulta.
- La consulta pública contrasta que el DTE existe en SIFEN, su estado y su
  validez. Un DTE es el documento electrónico transmitido, validado y aprobado
  por SIFEN; la DNIT le reconoce efectos jurídicos, probatorios y tributarios
  en las condiciones normativas aplicables.
- Para una persona usuaria, la secuencia práctica es escanear el QR del KuDE
  (o introducir el CDC), completar el reCAPTCHA y comparar el resultado con el
  comprobante presentado: emisor, receptor cuando corresponda, fecha, importe
  y estado.

## Alcance y límites para el proyecto

La consulta resulta útil como evidencia de validación del comprobante y como
control de coherencia de un caso individual. No debe presentarse como una
verificación automática, continua ni masiva: el reCAPTCHA es una barrera
observada en la interfaz pública y la regulación prevé, aparte, servicios web
para actores habilitados. Además, la validación tributaria no sustituye la
revisión de la realidad económica subyacente.

## Fuentes

1. Dirección Nacional de Ingresos Tributarios (DNIT), [Preguntas frecuentes:
   «¿Cómo se comprueba la validez de un KuDE?»](https://www.dnit.gov.py/en/web/e-kuatia/preguntas-frecuentes/-/categories/2705546?p_r_p_categoryId=2705546), consultada el 8 de septiembre de 2026.
2. DNIT, [Resolución General N.º 05/2018, art. 20](https://www.dnit.gov.py/en/web/portal-institucional/w/resolucion-general-n-05-18-1), consultada el 8 de septiembre de 2026.
3. DNIT, [Manual Técnico SIFEN, versión 1.5.0](https://www.dnit.gov.py/documents/20123/420592/Manual%2BT%C3%A9cnico%2BVersi%C3%B3n%2B150.pdf/e706f7c7-6d93-21d4-b45b-5d22d07b2d22?t=1687351495907), consultado el 8 de septiembre de 2026.
4. DNIT, [Preguntas frecuentes: validez de los DTE](https://www.dnit.gov.py/en/web/e-kuatia/preguntas-frecuentes?_com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_idba_cur=3&_com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_idba_delta=10&_com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_idba_redirect=%2Fen%2Fweb%2Fe-kuatia%2Fpreguntas-frecuentes%2F-%2Fcategories%2F915139&p_p_id=com_liferay_asset_publisher_web_portlet_AssetPublisherPortlet_INSTANCE_idba&p_p_lifecycle=0&p_p_mode=view&p_p_state=normal&p_r_p_categoryId=915139&p_r_p_resetCur=false), consultada el 8 de septiembre de 2026.

