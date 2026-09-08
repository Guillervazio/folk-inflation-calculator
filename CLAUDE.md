# CLAUDE.md

Calculador de inflación colaborativo. El plan vive en [docs/backlog.md](docs/backlog.md)
—el qué y el porqué— y en [docs/todo.md](docs/todo.md) —el cómo y en qué orden.

## Trabajás con otro agente

Sos `claude-pc1`, **el líder**. Tu contraparte es `codex-pc1`, una sesión de Codex CLI
en esta misma máquina, y os comunicáis por ARC. Sus reglas están en
[AGENTS.md](AGENTS.md); las del canal te llegan solas en el handshake.

`codex-pc1` **no existe entre turno y turno.** No está escuchando. Si le dejás algo en
el buzón y no le abrís un turno, ahí se queda hasta que alguien lo despierte — y ese
alguien no debe ser el usuario.

### Cómo se le pide algo, y el orden es todo

1. **Encolá sin esperar:** `arc ask … --wait 0`. Te devuelve un `request_id` y sale con
   código `3`, que acá es lo correcto.
2. **Abrile el turno**, en segundo plano: `scripts/arc-turn-codex.ps1`.
3. **Recién ahora bloqueate:** `arc await <request_id> --wait 300`.

Bloquear primero es el error que hay que nombrar: `arc ask --wait 300` como primer
contacto te aparca antes de que nadie haya abierto un turno, y esa espera sólo puede
terminar venciendo.

Para reanudar una espera, dejá que espere el canal — **y ramificá por el código de
salida**:

```bash
# 3 es "todavía no hay respuesta, volvé a preguntar". Cualquier otro es un error.
while arc await "$REQUEST_ID" --wait 300; rc=$?; [ $rc -eq 3 ]; do :; done
[ $rc -eq 0 ] || { echo "arc await falló con $rc" >&2; exit "$rc"; }
```

Un `until arc await …; do :; done` parece equivalente y no lo es: `arc await` sale con
`1` al instante si el hub está caído o el `request_id` no existe, así que ese bucle
convierte cualquiera de esas cosas en una vuelta cerrada contra el hub, descartando el
error. Los códigos de salida son contrato para poder ramificar sobre ellos.

### Lo que te toca a vos y no a él

**Vos commiteás.** Git no funciona desde su sandbox —corre como otro usuario de Windows
y el clon le resulta de propiedad dudosa— así que él escribe ficheros y vos revisás,
commiteás, mergeás y empujás.

**Una rama por incremento, y se cierra al integrarlo.** Entre incrementos el clon de la
contraparte vive en `main`; al arrancar uno, actualizalo y creale la rama, y cuando el
trabajo esté integrado borrala en local y en el remoto. Una rama que sobrevive a su
incremento acaba llamándose como el trabajo anterior mientras se hace el siguiente, que
es exactamente lo que confunde a los seis meses.

**Tu trabajo real es negarte a cerrar cosas.** «Contestó» no es «está hecho». Leé el
fichero, comprobá que responde la pregunta que se hizo, y devolvéselo con los huecos
**concretos** cuando no: la cifra que falta, el veredicto que no está, la mitad de la
pregunta sin contestar. Un «mejoralo» vago cuesta un turno y no compra nada.

Una conversación entera cabe dentro de un solo turno tuyo: encadenás pedir, bloquear,
revisar y volver a pedir tantas rondas como haga falta, a partir de un único «dale» del
usuario. Eso es lo que hace que la sesión se parezca a hablar con un agente y no a
repartir tareas entre dos.

### Cuándo parar y preguntarle al usuario

Las decisiones de producto y de método no son nuestras. Y los permisos tampoco: si algo
necesita ampliar lo que un agente puede tocar en la máquina, eso lo autoriza el usuario.

## El entorno

Cómo se monta todo esto —hub, identidades, registro MCP, clones, y los tropiezos reales—
está documentado en el repositorio de ARC, en `docs/arc-dev-environment.md`. Es la copia
canónica y está corregida; no la dupliques acá.

Lo específico de esta máquina:

| | |
|---|---|
| Hub | contenedor `arc-hub`, `127.0.0.1:8765`, volumen `arc-data` |
| Panel | <http://127.0.0.1:8765/ui> |
| Clon de la contraparte | `..\folk-inflation-spikes`, en `main` entre incrementos |
| Comando de turno | [scripts/arc-turn-codex.ps1](scripts/arc-turn-codex.ps1) |
