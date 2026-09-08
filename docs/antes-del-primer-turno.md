# Antes del primer turno

Los cuatro bloques que ARC pide rellenar antes de poner a dos agentes a hablar sobre este
proyecto — la plantilla y el porqué están en `docs/before-the-first-turn.md` del
[repositorio de ARC](https://github.com/Guillervazio/agent-relay-channel).

El motivo, en una frase: **el canal no tiene noción de corrección.** Garantiza la entrega
y garantiza una espera real, no que lo que viajó fuera verdad. Una respuesta equivocada
dicha con seguridad se mueve igual de bien que una correcta, y más rápido de lo que nadie
la atraparía, porque el montaje quitó a la persona del medio a propósito. Lo que nadie
decidió, lo deciden ellos — no por descuido, sino porque se lo preguntan.

Las reglas del canal **no están aquí**: llegan solas en el handshake. Lo que cada agente
es y si commitea está en [AGENTS.md](../AGENTS.md) y [CLAUDE.md](../CLAUDE.md).

---

## 1. La costura

`claude-pc1` posee **todo lo que consume el contrato de extracción**: el servicio .NET que
llama al modelo y valida su salida, la persistencia, la API y el front.

`codex-pc1` posee **el contrato de extracción**:

- El esquema JSON de salida y su versión.
- El prompt de extracción, versionado en el repositorio y nunca incrustado en el código.
- La medición de precisión contra el conjunto de referencia de tickets reales (`S4`).

**Dónde se tocan:** el esquema JSON de extracción. Es lo único que cruza.

**Qué cruza, y con qué forma.** Un documento JSON versionado que representa un ticket
leído, y que lleva:

| | |
|---|---|
| Versión | del esquema, explícita, para poder cambiarlo sin romper lo persistido |
| Cabecera | comercio, RUC, número de comprobante, fecha y hora |
| Líneas | cada una clasificada como **producto** o **no-producto** (descuento, bolsa, redondeo, subtotal, total) |
| Importes | en guaraníes — **forma concreta pendiente, ver bloque 3** |
| Confianza | por campo, para que la pantalla de revisión ordene por ella |

> **Esta costura está identificada pero no cerrada.** La prueba de ARC es si un agente
> podría contestar una pregunta en la costura sin preguntarte: hoy, ante «¿cómo viaja
> `15.000`?», tendría que adivinar. Se cierra cuando se resuelvan las dos decisiones
> abiertas del bloque 3, y **hasta entonces no se abre el canal para la Fase 1**.

---

## 2. Ya decidido

Sólo lo que toca esta costura. El resto de decisiones del proyecto viven en
[backlog.md](backlog.md); éstas se repiten aquí porque son las que un agente inventaría
si se las preguntaran.

- **Extracción con IA multimodal y revisión humana** (`D5`). El modelo propone, la persona
  confirma. Nunca se guarda un dato extraído que nadie haya visto.
  <br>**No autoriza:** tratar una confianza alta del modelo como sustituto de la revisión,
  ni persistir nada por una vía que se la salte.

- **E3 sigue siendo el camino principal** (`S1`). El detalle de ítems se puede obtener del
  XML del Documento Electrónico, pero sólo lo tiene el receptor que además es facturador
  electrónico, y el cronograma de incorporación llega a septiembre de 2027.
  <br>**No autoriza:** diseñar la extracción asumiendo que habrá XML, ni prometer una
  cobertura que ese cronograma desmiente. El parser de XML es una mejora aparte.

- **El guaraní no usa decimales, y el punto es separador de miles.** `₲ 15.000` son quince
  mil, no quince.
  <br>**No autoriza:** heredar el formato decimal de otras monedas en ningún punto del
  recorrido — parseo, validación, almacenamiento o formateo. Un error aquí es de tres
  órdenes de magnitud y pasa desapercibido.

- **Ningún dato personal llega a la base** (`E9-3`). Titular, dígitos de tarjeta y número
  de socio se descartan **en la extracción**, no después.
  <br>**No autoriza:** guardarlos «temporalmente» para depurar, ni dejarlos en un registro
  de la llamada al modelo.

---

## 3. No les toca decidir

Van al usuario, a través de `claude-pc1`:

- **Producto y método.** Para qué sirve esto y qué cuenta como una buena respuesta.
- **Cualquier cosa que amplíe lo que un agente puede tocar** en la máquina.
- **Cuál es el próximo incremento**, y cuándo parar.

Y dos decisiones concretas que hoy están abiertas. **Bloquean la costura**, porque son
exactamente lo que un agente contestaría con algo plausible si se lo preguntaran:

1. **La representación de los importes en guaraníes.** Que no llevan decimales ya está
   decidido; falta la forma: entero de qué anchura, y si en el JSON viaja como número o
   como cadena. Cruza el esquema de extracción, la base de datos y el cálculo del índice,
   así que cambiarla después es migrar todo.

2. **El ámbito geográfico del índice.** El IPC del BCP cubre **sólo el Área Metropolitana
   de Asunción** (`S2`); si el nuestro recoge tickets de todo el país, `E7-3` estaría
   superponiendo dos cosas que no miden lo mismo. Tres salidas: acotar nuestra cobertura,
   acotar la comparación, o publicarla con la advertencia. Cambia lo que el portal promete.

---

## 4. Terminado

Un ítem está hecho cuando:

1. **El fichero existe** en el clon de quien lo escribió, con sus fuentes citadas por URL y
   fecha de consulta cuando las tenga.
2. **Se respondió por el canal** con `arc_respond`, diciendo qué ficheros se escribieron y
   cuál es el veredicto.
3. **El fichero responde la pregunta que se hizo**, no una parecida. Si el encargo pedía
   dos cosas, están las dos.

Que `codex-pc1` haya contestado no es que el ítem esté hecho: una buena respuesta se
parece a trabajo terminado hasta que alguien abre el fichero. Integrar —revisar,
commitear, empujar— es de `claude-pc1`, porque git no funciona desde el sandbox de la
contraparte.
