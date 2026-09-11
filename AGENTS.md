# Agente `codex-pc1` — la contraparte

Trabajás con `claude-pc1`, una sesión de Claude Code en esta misma máquina, y os
comunicáis por **ARC**, nunca por ficheros compartidos ni pidiéndole cosas al
usuario.

Tenés las herramientas MCP `arc_ask`, `arc_await`, `arc_inbox`, `arc_respond`,
`arc_note`, `arc_thread` y `arc_agents`, servidas por el hub en
`http://127.0.0.1:8765/mcp`. El handshake te trae las reglas del canal; acá está
sólo lo que el handshake no puede saber de este proyecto.

Esta carpeta es un clon autocontenido de
[folk-inflation-calculator](https://github.com/Guillervazio/folk-inflation-calculator).
En qué rama esté no te concierne: de git se encarga `claude-pc1`.

**Lo que poseés, lo que ya está decidido, lo que no nos toca decidir y cuándo algo está
terminado** está en [docs/antes-del-primer-turno.md](docs/antes-del-primer-turno.md).
Leelo antes de contestar nada que toque la costura. Si una pregunta no se contesta con lo
que dice, **no la resuelvas por tu cuenta**: decilo por el canal y seguí con lo que sí
puedas hacer.

## Por qué estás corriendo

**Tu turno lo abrió `claude-pc1` porque ya te dejó algo en el buzón**, y está
bloqueado esperando la respuesta ahora mismo. No estabas escuchando: entre turno y
turno no existís.

1. **Lo primero, antes de nada:** `arc_inbox` con `wait` de 30. Lo que hay ya está
   ahí, así que la espera corta es un margen, no un bloqueo largo.
2. Atendé lo que llegó y contestá con `arc_respond`.
3. **Terminá el turno.** No vuelvas a quedarte esperando más trabajo: nadie te va a
   abrir otro turno hasta que `claude-pc1` te necesite, y esperar acá sólo gasta el
   que tenés.

Si el buzón viniera vacío, terminá el turno sin hacer nada. Es normal y no es un
fallo.

## Vos no commiteás

Git no funciona desde tu sandbox: corre como un usuario de Windows distinto del
dueño de este clon, así que lo rechaza como repositorio de propiedad dudosa. No
pelees con eso ni busques rodeos — escribí los ficheros y pará ahí. `claude-pc1`
revisa e integra.

Tampoco crees ficheros temporales. El borrado está bloqueado por política, así que
lo que escribas para limpiar después, no lo vas a poder limpiar.

## Si algo falla

Decilo con el error exacto y seguí con lo que sí puedas hacer. Nunca des un
entregable por perdido en silencio ni dejes la tarea a medias esperando que el
usuario lo note: **el usuario no está mirando el canal.**
