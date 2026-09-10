# Antes del primer turno

Los cuatro bloques que ARC pide rellenar antes de poner a dos agentes a hablar sobre este
proyecto. La plantilla y su porqué están en `docs/before-the-first-turn.md` del
[repositorio de ARC](https://github.com/Guillervazio/agent-relay-channel).

El motivo en una frase: el canal no tiene noción de corrección. Lo que nadie decidió lo
deciden los agentes, porque se lo preguntan, y una respuesta por el canal se parece
exactamente a un hecho. Este fichero es lo que ya no se les pregunta.

---

## 1. La costura

`codex-pc1` posee **la lectura del ticket**:

- El esquema JSON de un ticket leído.
- El prompt de extracción, versionado en el repositorio y nunca incrustado en el código.
- La medición de precisión contra el conjunto de referencia de tickets reales (`E3-7`, `S4`).

`claude-pc1` posee **todo lo que consume esa lectura**: el servicio .NET que llama al modelo
con ese prompt y valida su salida contra ese esquema, los reintentos (`E3-4`), la revisión
(`E4`), la persistencia y la subida (`E2`).

**Dónde se tocan:** el esquema. Cruza una sola cosa: un documento JSON que representa un
ticket leído, uno por ticket aunque haya llegado en varias fotos (`E2-5`).

### Qué lleva

El ticket típico **no trae QR y suele traer sólo el desglose de productos, precios y total**
— observación del usuario. El §4 del backlog dice que los comprobantes legales llevan RUC,
timbrado y número; un agente que lea eso esperaría encontrarlos, y en la mayoría de los
tickets no están.

| | Garantizado | Opcional |
|---|---|---|
| **Cabecera** | versión del esquema, total | comercio, RUC, número de comprobante, fecha, hora, subtotal, IVA 10 %, IVA 5 % |
| **Cada línea** | tipo, descripción, total de la línea | cantidad, unidad, precio unitario |

Las líneas van **en el orden del papel**, y las de un ticket de varias fotos, en el orden en
que se subieron. El tipo de línea es uno de: `producto`, `descuento`, `bolsa`, `redondeo`,
`propina`.

Cada campo leído —el tipo de línea incluido— lleva una **confianza entre 0 y 1**. Qué cuenta
como baja lo decide la revisión (`E4-4`), no la lectura.

### Reglas de forma

- **Ausente o ilegible viaja como `null`. Presente pero dudoso viaja con su valor y confianza
  baja.** Nunca se rellena un campo con un valor razonable.
- Comercio, RUC, número de comprobante, descripción y unidad viajan **tal como están
  impresos**. Normalizarlos es de `E5-3` y `E5-6`, del otro lado.
- La fecha en ISO 8601; la hora en hora local de Paraguay, sin zona horaria.
- El IVA, sólo cuando está impreso, y desglosado por tasa en la cabecera. Nunca por línea.
- **No hay campos para datos personales** (`E9-3`): titular, dígitos de tarjeta y número de
  socio no existen en el esquema, así que no hay dónde ponerlos.
- El timbrado no está: `E3-1` no lo pide.
- La versión es un entero que sube con cualquier cambio de forma, y lo guardado conserva la
  versión con que se leyó.

La **sintaxis** —nombres de campo, anidamiento, cómo se adjunta la confianza a cada valor—
la fija `codex-pc1` en el esquema, y es suya. Lo que está en este bloque es el significado,
y el esquema no puede contradecirlo.

### Lo que esta costura no cubre

- **Descartar imágenes que no son tickets** (`E8-6`) entra en la Fase 3. Cuando entre será un
  cambio de esquema, y sigue la regla del bloque 3.
- **Reintentar una lectura fallida** (`E3-4`) es del lado que consume: es fontanería del
  servicio que llama al modelo, no forma de lo que cruza.

---

## 2. Ya decidido

- **Importes enteros, cantidades decimales.** Un importe viaja como entero JSON en guaraníes
  —`15000`— y una cantidad como número decimal JSON —`1.25`—, se imprima como se imprima.
  «El guaraní no usa decimales» es una regla del dinero.
  <br>**No autoriza:** aplicar la regla de los importes a las cantidades ni al revés, ni pasar
  el formato impreso (`15.000`, `1,250`) a través de la costura. Convierte el que lee; nadie
  más.

- **Lo que no está en el papel no se supone.** Una cantidad no impresa es `null`, no `1`.
  <br>**No autoriza:** completar un campo con lo que casi siempre es cierto — cantidad 1, la
  fecha de la subida, el comercio de otro ticket. Qué significa una ausencia lo decide el lado
  que consume, que es quien puede preguntarle a la persona.

- **Un descuento es positivo, y su tipo dice que resta.**
  <br>**No autoriza:** importes negativos en ningún tipo de línea. Si el modelo lee un signo
  menos, eso es una lectura dudosa para revisar, no un dato.

- **Subtotal, IVA y total son de la cabecera, nunca líneas**, aunque en el papel aparezcan
  como una línea más. `E3-2` los nombra como líneas y `E3-1` como campos; vale lo segundo.
  <br>**No autoriza:** repetirlos en las líneas. Si estuvieran en los dos sitios, cualquier
  suma contaría el total dos veces.

- **El modelo propone y la persona confirma** (`D5`). Nunca se guarda un dato leído que nadie
  haya visto.
  <br>**No autoriza:** tratar una confianza alta como sustituto de la revisión. La confianza
  ordena lo que se revisa primero; no decide lo que se deja de revisar.

---

## 3. No les toca decidir

Van al usuario, a través de `claude-pc1`:

- **Producto y método.** Para qué sirve esto y qué cuenta como una buena respuesta.
- **Cualquier cosa que amplíe lo que un agente puede tocar** en la máquina.
- **Cuál es el próximo incremento**, y cuándo parar.
- **Cualquier cambio al esquema una vez cerrado.** Lo propone `codex-pc1` con la versión nueva,
  por iniciativa propia o a pedido de `claude-pc1`; `claude-pc1` dice si puede consumirla, y
  decide el usuario. La versión sube siempre. El
  esquema es la costura: acordarlo entre los dos por el canal es exactamente el caso donde se
  inventa, y ninguno de los dos tiene autoridad para cerrar la discusión.

---

## 4. Terminado

**El esquema** está terminado cuando está versionado en el repositorio, cubre el bloque 1
**y nada más**, y trae al menos un ticket de ejemplo que valida y uno que no. Un campo que
el bloque 1 no nombra —por razonable que parezca— es un cambio de esquema, y va por el
bloque 3.

**El prompt** está terminado cuando está versionado en el repositorio, fuera del código, y su
precisión está medida por campo contra el conjunto de referencia (`E3-7`). Sin ese conjunto
—que exige tickets reales, `S4`— un prompt no está terminado: es un borrador, y se entrega
diciéndolo así.

**Cualquier ítem**, además:

1. Se respondió por el canal diciendo qué ficheros se escribieron y cuál es el veredicto.
2. Responde **la pregunta que se hizo**, no una parecida. Si el encargo pedía dos cosas,
   están las dos.
