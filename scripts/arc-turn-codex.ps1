<#
.SYNOPSIS
    Le abre a codex-pc1 exactamente un turno, y vuelve cuando ese turno termina.

.DESCRIPTION
    El comando de turno de P024. La contraparte no existe entre turno y turno: cuando
    claude-pc1 necesita una respuesta, encola con --wait 0, ejecuta esto, y sólo
    entonces se bloquea en arc await. El orden importa — bloquear primero aparca al
    líder antes de que nadie haya abierto un turno, y esa espera sólo puede vencer.

    Esto no es un supervisor. No hay bucle, no hay intervalo, no hay fichero de parada
    y no hay nada que acordarse de apagar: cuesta un turno exactamente cuando hace
    falta uno. La versión en bucle sólo tiene sentido si ambos lados necesitan iniciar
    conversaciones, y acá sólo inicia el líder.

    Tampoco lee el buzón de nadie. Leer un buzón reclama lo que encuentra, así que un
    proceso que mirase antes de lanzar estaría acusando recibo por un agente que
    todavía no vio nada.

    Dos propiedades que el comando tiene que cumplir, sea cual sea el CLI:
    un turno y salir, nunca una sesión interactiva; y no interactivo, porque un turno
    que se para a pedir aprobación vuelve a poner al usuario en el medio.

    Observado con Codex CLI v0.153.4 el 8 de septiembre de 2026. Los flags, las claves
    de configuración y el sandbox son de otro proyecto y pueden cambiar sin aviso: si
    esto deja de funcionar, sospechá de la versión antes que del canal.

.EXAMPLE
    ./scripts/arc-turn-codex.ps1
    ./scripts/arc-turn-codex.ps1 -Clone 'C:\otra\ruta'
#>
[CmdletBinding()]
param(
    [string]$Clone = (Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'folk-inflation-spikes'),
    [ValidateRange(5, 300)]
    [int]$Wait = 30
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Clone)) { throw "No existe la carpeta de trabajo: $Clone" }
if (-not (Test-Path (Join-Path $Clone 'AGENTS.md'))) {
    throw "En $Clone no hay AGENTS.md. Sin el, la contraparte no sabe por que esta corriendo."
}

# El .cmd y no el .ps1 que Get-Command encuentra antes en el PATH: el envoltorio de
# PowerShell mete otra capa que convierte la salida de error de codex en
# NativeCommandError y ensucia el codigo de salida.
$codex = Join-Path $env:APPDATA 'npm\codex.cmd'
if (-not (Test-Path $codex)) { throw "No encuentro codex.cmd en $codex" }

$prompt = @"
Turno abierto por claude-pc1. Segui AGENTS.md.

Ya tenes algo en el buzon y claude-pc1 esta bloqueado esperando tu respuesta.

1. arc_inbox con wait=$Wait. Lo que hay ya esta ahi: la espera corta es un margen.
2. Atende lo que llego y responde con arc_respond, diciendo que ficheros escribiste
   y cual es el veredicto.
3. Termina el turno. No te quedes esperando mas trabajo.

No commitees y no crees ficheros temporales: de git se encarga claude-pc1. Si algo
falla, responde igual con el error exacto en vez de callarte.
"@

# El prompt entra por stdin y no como argumento. Pasandolo como argumento, codex se
# queda leyendo la entrada estandar ("Reading additional input from stdin...") en
# cuanto no hay una consola detras, que es justo el caso desde el que se invoca esto.
# Con '-' la lee a proposito y no hay ambiguedad.
$prompt | & $codex exec `
    --cd $Clone `
    --skip-git-repo-check `
    --sandbox workspace-write `
    -c 'sandbox_workspace_write.network_access=true' `
    '-'

exit $LASTEXITCODE
