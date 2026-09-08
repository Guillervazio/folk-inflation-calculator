<#
.SYNOPSIS
    Le da turnos a Codex para que la conversación por ARC no dependa del usuario.

.DESCRIPTION
    ARC da la espera, pero no da el turno. Un agente de línea de comandos sólo
    existe mientras dura el suyo: puede bloquearse esperando un mensaje, pero no
    puede despertar solo cuando llega uno estando parado. Alguien tiene que
    arrancarlo, y este bucle es ese alguien.

    Deliberadamente no sabe nada del canal: no lee el buzón de Codex, no parsea
    mensajes y no necesita el token. Sólo lanza `codex exec` una y otra vez. Es el
    propio Codex quien, siguiendo su AGENTS.md, se bloquea en arc_inbox hasta que
    llegue algo. Si no llega nada dentro de la ventana, el turno acaba y se abre
    otro; si llega, lo atiende hasta terminarlo.

    Esa ignorancia es lo que lo hace fiable: no hay estado que se desincronice ni
    mensajes que este proceso pueda consumir por error. El buzón sigue siendo de
    Codex y sólo Codex lo vacía.

.PARAMETER Wait
    Segundos que Codex se bloquea en arc_inbox por turno. El hub rechaza lo que
    exceda su ARC_MAX_WAIT (300 por defecto): no lo recorta, devuelve 422.

.PARAMETER FullAccess
    Levanta el sandbox del todo. Sólo si `git push` falla por red desde
    workspace-write; probá antes sin él.

.EXAMPLE
    ./scripts/arc-supervisor.ps1
    ./scripts/arc-supervisor.ps1 -Once          # un solo turno, para probar
    ./scripts/arc-supervisor.ps1 -Wait 60
#>
[CmdletBinding()]
param(
    [string]$Clone = 'C:\Users\Guille\Claude Stuff\folk-inflation-spikes',
    [ValidateRange(5, 300)]
    [int]$Wait = 300,
    [string]$LogPath,
    [switch]$Once,
    [switch]$FullAccess
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Clone)) { throw "No existe la carpeta de trabajo: $Clone" }
if (-not (Test-Path (Join-Path $Clone 'AGENTS.md'))) {
    throw "En $Clone no hay AGENTS.md. Sin el Codex no sabe que debe escuchar el canal."
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($codex) {
    $codex = $codex.Source
} else {
    $cmd = Join-Path $env:APPDATA 'npm\codex.cmd'
    if (Test-Path $cmd) { $codex = $cmd } else { throw 'No encuentro el ejecutable de codex.' }
}

# Fuera del clon a proposito: dentro serian ficheros sin seguimiento que Codex
# veria en cada `git status` y acabaria commiteando.
$fuera = Split-Path $Clone -Parent
if (-not $LogPath) { $LogPath = Join-Path $fuera 'arc-supervisor.log' }
$stopFile = Join-Path $fuera 'arc-stop'
if (Test-Path $stopFile) { Remove-Item $stopFile -Force }

$prompt = @"
Turno automatico del supervisor. Segui lo que dice AGENTS.md.

1. Llama a arc_inbox con wait=$Wait. Vas a quedarte bloqueado ahi: es normal.
2. Si vuelve vacio, termina el turno sin hacer nada y sin escribir ficheros.
3. Si llega algo, atendelo hasta el final: escribi el entregable, commitea y
   empuja a spikes/fase-0, y responde con arc_respond citando el commit.
   Si algo falla, responde igual con el error exacto en vez de callarte.
"@

$argsBase = @('exec', '--cd', $Clone, '--skip-git-repo-check')
if ($FullAccess) {
    $argsBase += '--dangerously-bypass-approvals-and-sandbox'
} else {
    $argsBase += @('--sandbox', 'workspace-write', '-c', 'sandbox_workspace_write.network_access=true')
}

function Write-Log([string]$texto) {
    $linea = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $texto
    Write-Host $linea
    Add-Content -Path $LogPath -Value $linea -Encoding utf8
}

Write-Log "Supervisor en marcha. Carpeta: $Clone"
Write-Log "Ventana de escucha: $Wait s. Para con Ctrl+C o creando $stopFile"

$turno = 0
$fallosSeguidos = 0

try {
    while ($true) {
        if (Test-Path $stopFile) { Write-Log 'Encontrado el fichero de parada. Salgo.'; break }

        $turno++
        Write-Log "--- turno $turno ---"
        $inicio = Get-Date

        & $codex @argsBase $prompt
        $codigo = $LASTEXITCODE

        $duracion = [int]((Get-Date) - $inicio).TotalSeconds
        Write-Log "turno $turno terminado en ${duracion}s (codigo $codigo)"

        if ($codigo -ne 0) {
            $fallosSeguidos++
            # Un turno que falla al instante y se repite es un problema de
            # configuracion, no una racha de mala suerte: no lo machaques.
            if ($fallosSeguidos -ge 3) {
                Write-Log 'Tres turnos seguidos fallidos. Paro para que lo mires.'
                break
            }
            $espera = 15 * $fallosSeguidos
            Write-Log "Reintento en ${espera}s"
            Start-Sleep -Seconds $espera
        } else {
            $fallosSeguidos = 0
            # Un turno que vuelve enseguida es un buzon vacio. Sin esta pausa el
            # bucle seria una espera activa cuando el hub este caido.
            if ($duracion -lt 10) { Start-Sleep -Seconds 5 }
        }

        if ($Once) { Write-Log 'Modo -Once: un turno y salgo.'; break }
    }
} finally {
    Write-Log "Supervisor detenido tras $turno turno(s). Registro en $LogPath"
}
