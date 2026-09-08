# ARC in a development environment

*An optional guide to running an autonomous session between two agents. Written from a real
setup — every failure listed here was hit, not imagined.*

The [README](../README.md) tells you how to install the hub and what the commands do. It stops
where the channel stops, and that is the right place for it to stop. This document covers what
sits around the channel: the working trees, who is allowed to commit, the rules each agent
needs in front of it, and the small piece of machinery that turns "two agents that can talk"
into "two agents that actually do talk for an hour without a human in the middle".

Nothing here is required to use ARC. It is required to leave it running.

---

## 1. The problem this document solves

The README already states the constraint that everything below follows from:

> A command-line agent **is not a server**: it only exists for the duration of its turn. It
> cannot hold an open subscription, nor wake up for an event that arrives while it is idle.

ARC solves one half of that. While an agent is inside a turn it can block — `arc ask --wait 180`
holds the request open on the server, and the answer wakes it instantly. That is real, and it is
the thing a shared markdown file could never do.

**ARC does not solve the other half, and by design it should not.** It has no way to *start* a
turn. It cannot invoke `codex`. So if agent A writes to agent B while B is idle, the message sits
in B's mailbox until something gives B a turn.

If that something is you, you become a message relay. You paste "check your inbox" into one
terminal, wait, read the answer, paste the next instruction into the other. The channel works
perfectly and the experience is worse than not having it, because now you are relaying with
extra steps.

The fix is one page of PowerShell and a handful of rules. That is what this document is.

**The division to hold in your head:**

| | Who provides it |
|---|---|
| The **wait** — blocking until an answer arrives | ARC. Already solved. |
| The **turn** — existing at all, so you can wait | You, or a supervisor loop. Not ARC's job. |

---

## 2. Topology: you do not need two machines

The README describes two PCs because that is the interesting deployment. To *start*, one machine
is enough and is strictly easier: Claude Code in one terminal, Codex CLI in another, both against
a hub on loopback. No firewall rule, no network profile classification, no service installation.

```
Terminal 1: Claude Code  ──┐
                           ├─►  arc-hub  (container, 127.0.0.1:8765)  ──►  arc.db (volume)
Terminal 2: Codex CLI    ──┘
```

Publish the container port on loopback specifically, not on all interfaces:

```bash
docker run -d --name arc-hub --restart unless-stopped \
  -p 127.0.0.1:8765:8765 -v arc-data:/data -e ARC_TOKEN="$TOKEN" arc-hub
```

`-p 127.0.0.1:8765:8765` rather than `-p 8765:8765`. The second form exposes the hub on every
interface, which on a laptop frequently means a café's Wi-Fi. The channel carries instructions
between agents; it has no business listening there.

The database lives in the `arc-data` volume, so recreating the container does not take the
mailbox with it. But `ARC_TOKEN` lives *in the container*, not on the machine: if you
`docker rm` and re-run without passing the same token, every agent starts getting `401`.

---

## 3. Setup

### 3.1 Generate a token, and check that you generated one

On Windows PowerShell 5.1 this is a trap worth naming, because it fails **silently**:

```powershell
# WRONG on PowerShell 5.1 — the method does not exist, $bytes stays all zeros,
# and you get a valid-looking token of "AAAAAAAA..." with no error you will notice.
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)

# Right
$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes); $rng.Dispose()
$token = ([Convert]::ToBase64String($bytes)) -replace '\+','-' -replace '/','_' -replace '=',''
if ($token -match '^A{20,}$') { throw "Token generation failed silently: $token" }
```

The guard on the last line is not paranoia. The failure produces a token that is the right
length, base64-shaped, and completely predictable.

### 3.2 Identity per agent

Each agent needs a different `ARC_AGENT`. The name is the key of the wait registry, so it must
match `^[a-z0-9][a-z0-9._-]{0,63}$` — lowercase, no spaces. One capital letter and the hub
answers `422 bad_agent`.

Name them by **role**, not by machine, unless the machine is the distinguishing fact. On a
single host, `claude-pc1` and `codex-pc1` read strangely; `claude-lead` and `codex-research`
say what each one does.

Set them at user level so every new console inherits them:

```powershell
[Environment]::SetEnvironmentVariable('ARC_URL',   'http://127.0.0.1:8765', 'User')
[Environment]::SetEnvironmentVariable('ARC_TOKEN', $token,                  'User')
[Environment]::SetEnvironmentVariable('ARC_AGENT', 'claude-lead',           'User')
```

### 3.3 Register the MCP server once per user, not per repository

```bash
claude mcp add --scope user --transport http arc http://127.0.0.1:8765/mcp \
  --header "X-ARC-Agent: claude-lead" \
  --header "X-ARC-Token: <token>"
```

Codex, in `~/.codex/config.toml`:

```toml
[mcp_servers.arc]
url = "http://127.0.0.1:8765/mcp"

[mcp_servers.arc.http_headers]
"X-ARC-Agent" = "codex-research"
"X-ARC-Token" = "<token>"
```

**Check for a stale token before anything else.** If you ever ran the `demo/`, that file already
contains an `arc` block with the demo's token, and it will keep it. The symptom is `401` from an
agent whose configuration file looks perfectly correct.

Verify by actually speaking the protocol, not by reading the file back:

```bash
curl -s -X POST http://127.0.0.1:8765/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "X-ARC-Agent: codex-research" -H "X-ARC-Token: $TOKEN" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"check","version":"1.0"}}}'
```

A `200` carrying `"serverInfo"` and `"instructions"` means that agent's credentials work and the
handshake will put the channel's own rules in front of its model.

### 3.4 Prove the cycle before trusting it

An agent may queue work for itself — and, by the same rule, may not block waiting on it
([P018](adr/P018-an-agent-may-queue-work-for-itself.md)). That is enough for a complete
end-to-end test with a single agent, as long as the `ask` does not wait:

```bash
arc health                                              # 0
arc ask --to claude-lead --subject "probe" --body-file q.md --wait 0   # 3, request stays alive
arc inbox                                               # 0, shows it
arc respond req_… --body-file a.md                      # 0
```

Exit code `3` on the `ask` is the correct result, not a failure: there is no answer *yet*. The
`--wait 0` is not incidental — a self-addressed request with a real wait is refused, because an
agent blocked on its own question can never be the one to answer it.

---

## 4. Working trees: give each agent a clone, never a worktree

A `git worktree` is the elegant way to give a second agent a second branch. **It does not work
for a sandboxed agent, and the failure is confusing rather than explicit.**

In a worktree, `.git` is not a directory. It is a file containing a pointer:

```
gitdir: C:/…/main-repo/.git/worktrees/the-worktree
```

Every git write from that folder therefore writes into *another* folder. An agent confined to
its own working directory cannot commit, and depending on the sandbox you will see a permission
error, a hang, or — as we did — a report that "the directory became inaccessible".

Use a plain clone. Its `.git` is a real directory, self-contained, and everything the agent
needs is inside the folder it was given:

```bash
git clone --branch <branch> <remote> ../agent-b-clone
```

**And there must be a remote.** ARC's rule is to send references and not content — "branch X,
commit Y" rather than the file. Two agents with no shared remote have nothing to reference, and
the channel degrades into pasting file contents at each other, which is exactly the shared
markdown file ARC replaced. A shared remote is a precondition, not a nicety.

---

## 5. Who commits

An agent under Codex's sandbox could not commit. The first explanation offered — its own report —
was that `git commit` died creating `.git/index.lock`, which reads like `workspace-write`
excluding `.git`. **That explanation is wrong, and it is worth spelling out how, because the
wrong one is far more plausible than the right one.**

Probing it directly, with `git` invoked rather than a commit attempted:

```
$ git rev-parse --git-dir
fatal: detected dubious ownership in repository at 'C:/…/agent-b-clone'
'C:/…/agent-b-clone' is owned by:
        'S-1-5-21-…-1001'
but the current user is:
        'S-1-5-21-…-1006'
```

**The sandbox executes as a different Windows user than the one that owns the clone.** With
`[windows] sandbox = "elevated"` in `~/.codex/config.toml`, commands run under a restricted token
with its own SID. Git's `safe.directory` protection then refuses to treat the directory as a
repository at all — and every later error (`--local can only be used inside a git repository`)
is a consequence of that refusal, not an independent finding.

So the constraint is not "`.git` is read-only". It is "**git does not work here**", for a reason
that has nothing to do with ARC, with sandboxes writing files, or with which directory is
writable. The agent writes files in its working directory perfectly well.

### What follows

**Option A — make git usable inside the sandbox.** The ownership exception has to exist for the
*sandbox's* identity, not yours, so `git config --global --add safe.directory …` run as yourself
does not help. Untested here; if you take this path, verify it rather than assuming it.

**Option B — the writing agent does not commit; the integrating agent does.** This is what we
ran, and the probe above makes it a better default than it first appeared:

- It needs no configuration at all, and nothing about the sandbox has to be negotiated away.
- The reviewing agent is already deciding whether the work is finished. Committing what it has
  accepted is the same act, not an extra one.
- It is indifferent to *why* the agent cannot commit — ownership, policy, or a future change in
  another project's CLI.

Under Option B the deliverable is a **file written and an answer sent**. Everything about
committing, merging and pushing belongs to the integrator.

### A second, separate restriction

In the same probe, this was refused outright:

```
powershell.exe -Command "Remove-Item -LiteralPath 'probe.tmp' -Force" → rejected: blocked by policy
```

while `powershell.exe -NoProfile -Command 'git rev-parse --git-dir'` in the very same
configuration ran fine. The policy is not blocking the shell; it is blocking **deletion**. An
agent that writes a file it later wants to remove will get stuck, and — as ours did — may retry
the write-then-delete cycle in a loop. Tell it not to create temporary files.

---

## 6. The supervisor: supplying turns

The piece that closes the gap from §1. It is deliberately stupid, and its stupidity is the
feature.

**It knows nothing about the channel.** It does not read anyone's mailbox, does not parse
messages, does not need the token. It runs `codex exec` in a loop; the agent itself blocks in
`arc_inbox` for up to `ARC_MAX_WAIT`. If a message arrives the agent handles it; if not, the
turn ends empty and another one opens.

That ignorance buys two things a smarter supervisor would lose: there is no state that can drift
out of sync with the hub, and there is no way for this process to consume a message by accident.
The mailbox stays the agent's, and only the agent empties it.

A supervisor that watched the channel instead — reading the mailbox to decide when to launch —
would have to authenticate *as* that agent, and reading a mailbox claims what it finds. It would
be taking delivery of messages on behalf of an agent that has not seen them. If you want the
supervisor to react to traffic rather than poll, watch `/v1/observe/stream`, which is read-only
and marks nothing as delivered; do not read the mailbox.

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Clone,
    [ValidateRange(5, 300)][int]$Wait = 300,
    [string]$LogPath,
    [switch]$Once
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $Clone 'AGENTS.md'))) {
    throw "No AGENTS.md in $Clone. Without it the agent does not know to listen."
}

# The .cmd, not the .ps1 that Get-Command finds first on PATH: the PowerShell
# wrapper adds a layer that turns codex's stderr into NativeCommandError and
# corrupts the exit code.
$codex = Join-Path $env:APPDATA 'npm\codex.cmd'

# Outside the clone on purpose: inside, they are untracked files the agent sees
# in every `git status` and eventually commits.
$outside  = Split-Path $Clone -Parent
if (-not $LogPath) { $LogPath = Join-Path $outside 'arc-supervisor.log' }
$stopFile = Join-Path $outside 'arc-stop'
if (Test-Path $stopFile) { Remove-Item $stopFile -Force }

$prompt = @"
Automatic supervisor turn. Follow AGENTS.md.

1. Call arc_inbox with wait=$Wait. You will block there: that is normal.
2. If it comes back empty, end the turn without doing anything.
3. If something arrives, see it through: write the deliverable and answer with
   arc_respond, saying which files you wrote and what the verdict is.
   Do not commit and do not create temporary files: the integrator handles git.
   If anything fails, answer anyway with the exact error instead of going quiet.
"@

$args = @(
    'exec', '--cd', $Clone, '--skip-git-repo-check',
    '--sandbox', 'workspace-write',
    '-c', 'sandbox_workspace_write.network_access=true'
)

function Write-Log([string]$text) {
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $text
    Write-Host $line
    Add-Content -Path $LogPath -Value $line -Encoding utf8
}

$turn = 0; $consecutiveFailures = 0
try {
    while ($true) {
        if (Test-Path $stopFile) { Write-Log 'Stop file found. Exiting.'; break }
        $turn++; Write-Log "--- turn $turn ---"
        $start = Get-Date

        # The prompt goes in on stdin, not as an argument. Passed as an argument,
        # codex reads standard input anyway ("Reading additional input from
        # stdin...") the moment there is no console behind it — which is exactly
        # this loop. With '-' it reads it on purpose and there is no ambiguity.
        $prompt | & $codex @args '-'
        $code = $LASTEXITCODE

        $seconds = [int]((Get-Date) - $start).TotalSeconds
        Write-Log "turn $turn ended in ${seconds}s (code $code)"

        if ($code -ne 0) {
            $consecutiveFailures++
            # A turn that fails instantly and repeats is a configuration problem,
            # not a run of bad luck. Do not hammer it.
            if ($consecutiveFailures -ge 3) { Write-Log 'Three failures. Stopping.'; break }
            Start-Sleep -Seconds (15 * $consecutiveFailures)
        } else {
            $consecutiveFailures = 0
            # A turn that returns immediately is an empty mailbox. Without this the
            # loop becomes a busy wait whenever the hub is down.
            if ($seconds -lt 10) { Start-Sleep -Seconds 5 }
        }

        if ($Once) { break }
    }
} finally { Write-Log "Stopped after $turn turn(s). Log: $LogPath" }
```

### The flags, and why each one is there

| Flag | Why |
|---|---|
| `--cd <clone>` | The agent's working root. Its own clone, not yours. |
| `--sandbox workspace-write` | Write inside the folder, nowhere else. `.git` stays protected — see §5. |
| `-c sandbox_workspace_write.network_access=true` | Without it, shell commands in the sandbox have no network. Research needs it. |
| `'-'` as the prompt | Read the prompt from stdin. See the comment in the script; this one costs an hour if you meet it cold. |
| `codex.cmd`, not `codex.ps1` | The PowerShell wrapper wraps native stderr into `NativeCommandError` and pollutes `$LASTEXITCODE`. |

Codex `exec` reports its own configuration at startup. Read it once and confirm:

```
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR] (network access enabled)
```

`approval: never` matters: any `approval_mode = "approve"` you have set for the `arc_*` tools
does **not** interrupt in `exec` mode. If it did, you would be back to approving every message
by hand, which is the problem this whole document exists to remove.

### Two things that will bite on Windows

**Save the script as UTF-8 with BOM.** PowerShell 5.1 reads a `.ps1` without a BOM as ANSI, so
every accented character in a message or a prompt is corrupted before it leaves the file.

**Never build a Windows path with `printf` in bash.** `printf` interprets `\f`, `\t`, `\n`
inside the string, so `...\folk-...` silently becomes `...` plus a form feed. Written into a
TOML file it produces a section header that is not valid TOML and a path that does not exist.
Use a heredoc, or write the file with a tool that does not interpret escapes.

---

## 7. Rules for the agents

The handshake already carries the channel's own rules — an MCP client receives them in the
`instructions` field of `initialize`, which is why a repository adopting ARC has nothing to
copy. What the handshake cannot carry is anything about *your* project: who commits, what
"finished" means here, where the work goes.

That is what belongs in the agent's `AGENTS.md` (Codex) or `CLAUDE.md` (Claude Code). Keep it to
the things the handshake genuinely does not know.

```markdown
# Agent `codex-research`

You work in parallel with `claude-lead`, a Claude Code session on this machine. You
communicate through ARC — never through shared files, and never by asking the user
to carry a message.

This folder is a self-contained clone on branch `<branch>`.

## First thing every turn

Call `arc_inbox` with `wait=300`. You will block there until `claude-lead` writes —
**that is the normal behaviour of the channel, not a hang.** When something arrives
you wake instantly.

If it comes back empty, end the turn without doing anything. You will be given
another.

## You do not commit

Git does not work from inside your sandbox: it runs as a different user than the
one that owns this clone, so git refuses it as a dubious-ownership repository. Do
not fight it and do not try to work around it — write the files and stop there.
`claude-lead` reviews and integrates.

Do not create temporary files either. Deletion is blocked by policy, so anything
you write to clean up later, you cannot clean up.

## When something is finished

A request is not handled because you replied. It is handled when:

1. The file is written, with its sources cited by URL and date of consultation.
2. You answered with `arc_respond`, saying which files you wrote and the verdict.
3. The file answers **the question that was asked**, not a nearby one. Re-read the
   request before you call it done.

If the work is long, do not go silent for half an hour: send an `arc_note` with
progress. A notice expects no answer and blocks nobody.

## What you know goes in the file, not just in the channel

The channel is ephemeral and exists to coordinate. The file is what remains, and
what somebody reads in six months. Every figure worth saying in the channel goes
into the file too, with its source. The reply keeps the verdict and where to look.

## When something fails

Say so in the channel, with the exact error, and carry on with whatever you still
can do. Never drop a deliverable in silence and never leave a task half done
expecting the user to notice: **the user is not watching the channel.**

Use `arc_ask` when you need an answer to continue — it blocks. Use `arc_note` to
report an accomplished fact. Use `arc_thread` to recover the context of a
conversation you are already in. Do not write to narrate your progress.

## What the user decides, not us

Product and method questions go to `claude-lead`, who takes them to the user.
Do not settle them on your own.
```

Two of those rules were written *because they were violated*, and they are the two most likely
to be violated again:

- **"What you know goes in the file."** Our first pass answered richly in the channel — figures,
  caveats, a verdict — and wrote a thinner report to disk. The channel answer looked complete,
  so the gap was invisible until someone read the file.
- **"Answer the question that was asked."** The first report documented a real, adjacent thing
  and never addressed the actual question. It was good work aimed slightly wrong.

---

## 8. The other half of the loop: the integrator

The supervisor gives the researching agent turns. Nothing gives the integrating agent turns
either — but it does not need a supervisor, because **a whole conversation fits inside one of
its turns**.

`arc ask --wait 300` blocks inside the current turn and returns the answer there. So the
integrator can chain:

```
ask → block → read the answer → decide if it is finished →
    if not: ask again with the specific gaps → block → …
    if yes: review, commit, push, move to the next item
```

for as many rounds as the work takes, from a single "go" by the user. That is what makes the
session feel like talking to one agent rather than dispatching two.

To wait on an answer without polling, let the channel do the waiting:

```bash
until arc await <request_id> --wait 300 >/dev/null 2>&1; do :; done
```

Each call blocks on the hub for up to five minutes. No `sleep`, no busy loop.

**The integrator's real job is refusing to close things.** "The agent replied" is not "the task
is done". Read the file, check it answers what was asked, and send it back with *specific* gaps
when it does not — naming the missing figure, the missing verdict, the unanswered half of the
question. A vague "please improve it" costs a turn and buys nothing.

---

## 9. Failures we actually hit

Ordered roughly by how much time each one costs before you understand it.

| Symptom | Cause | Fix |
|---|---|---|
| Agent reports the working folder "became inaccessible"; filesystem operations hang | It was given a **git worktree**; `.git` points outside its sandbox | Use a plain clone (§4) |
| `git` refuses to work: *detected dubious ownership* | The sandbox runs as a **different Windows user** than the owner of the clone, so git's `safe.directory` check rejects it. Symptoms downstream — including a `git commit` that appears to fail on `.git/index.lock` — are consequences of this | Let the integrator commit (§5) |
| A write-then-delete loop the agent never escapes | Deletion is `blocked by policy`; the write succeeds, the cleanup does not, and it retries | Tell the agent not to create temporary files (§5) |
| `Reading additional input from stdin...` then exit 1 | `codex exec` given the prompt as an argument, with no console attached | Pass the prompt on stdin with `-` |
| Every agent gets `401`, config looks right | Stale demo token left in `~/.codex/config.toml` | Replace it; verify with a real `initialize` call |
| Token works nowhere and looks like `AAAAAAA…` | `RandomNumberGenerator::Fill` does not exist on PowerShell 5.1; it failed silently | `RNGCryptoServiceProvider`, plus a guard (§3.1) |
| `NativeCommandError`, wrong exit codes | Invoked `codex.ps1` instead of `codex.cmd` | Call the `.cmd` |
| Accented characters corrupted in agent messages | PowerShell 5.1 reads a BOM-less `.ps1` as ANSI | Save as UTF-8 **with** BOM |
| A TOML section header that is not valid TOML | `printf` interpreted `\f` in a Windows path | Heredoc, or a writer that does not interpret escapes |
| The agent commits the supervisor's log | Log file written inside the clone | Keep log and stop-file outside it |
| `422 bad_agent` | `ARC_AGENT` has a capital letter, a space, or is empty | `^[a-z0-9][a-z0-9._-]{0,63}$` |
| `422 invalid_wait` | `--wait` above the hub's `ARC_MAX_WAIT` | The hub refuses rather than silently clamping — this is intentional |
| `404` on `/v1/observe` | Not an endpoint | `/v1/observe/threads`, `/observe/history`, `/observe/stream` |

And the one that is not an error, only a wrong habit:

| **You are relaying messages by hand** | Everything sent with `--wait 0` and nothing giving the other agent turns | §6 |

---

## 10. Cost, and stopping

Every supervisor turn is a real agent turn: it costs tokens even when the mailbox is empty,
because the model still has to be started to call `arc_inbox`. With `-Wait 300` that is roughly
one cheap turn every five minutes of idleness.

So **stop the supervisor when the increment closes.** Ours ran two turns for the work and would
have kept going indefinitely afterwards for nothing:

```powershell
New-Item 'C:\…\arc-stop'      # exits after the turn in flight, never mid-task
```

The stop file is checked at the top of the loop rather than signalled mid-turn, so stopping
never interrupts work already in progress.

Watch the whole thing at `/ui`. It shows what the history cannot: **who is blocked right now**,
with the clock running. A deadlock is recognisable at a glance — two open questions, each with
its counter climbing.

---

## 11. What still needs a human

Not much, and that is the point — but the remainder is not zero and should not be automated
away:

- **Product and method decisions.** In our session the research surfaced that the official index
  we wanted to compare against covers only one metropolitan area while ours would be national.
  Neither agent should decide what to do about that.
- **Permission escalations.** Anything that widens what an agent may touch on the machine.
- **Starting and stopping the session**, and deciding what the increment is.

Everything between those is the two agents talking.

---

## 12. Appendix — how this was actually brought up

Written out because the first attempt was wrong in an instructive way.

**What was tried first, and discarded.** The hub went up, both agents were configured, and the
work was queued with `arc ask --wait 0` — queue and move on, which is the correct mode for an
agent that is not running. Then the user was asked to open Codex and tell it to check its inbox.
It worked, and it was the wrong shape: every subsequent message needed the same manual nudge.
The channel was doing its job and the human was still the transport.

`--wait 0` is right for a cold start and wrong as a way of working. Nothing in the setup was
wrong; the missing pieces were the standing instruction (§7) and the supervisor (§6).

**The sequence that actually works**, from nothing:

```powershell
# 1. Hub, on loopback, token generated safely (§3.1)
docker build -t arc-hub .
docker run -d --name arc-hub --restart unless-stopped `
  -p 127.0.0.1:8765:8765 -v arc-data:/data -e ARC_TOKEN="$token" arc-hub
curl http://127.0.0.1:8765/healthz          # authenticated:true, max_wait_seconds:300

# 2. Identity for each agent, at user level (§3.2)

# 3. MCP registered for both, verified with a real initialize call (§3.3)

# 4. The cycle proved end to end against yourself (§3.4)

# 5. A shared remote, and one clone per agent — never a worktree (§4)
git clone --branch <branch> <remote> ../agent-b-clone

# 6. AGENTS.md in that clone (§7). The supervisor refuses to start without it,
#    because an agent that has not been told to listen will not listen.

# 7. Queue the first request with --wait 0 — it stays alive in the mailbox
arc ask --to codex-research --subject "…" --body-file task.md --wait 0   # exits 3

# 8. Start the supervisor. From here nobody touches anything.
./arc-supervisor.ps1 -Clone ../agent-b-clone -Wait 300

# 9. The integrator drives, inside its own turn (§8):
#    ask → block → review → send back the gaps → block → review → commit
```

Steps 7 and 8 are the whole difference. Step 7 alone is a message in a mailbox. Step 7 followed
by step 8 is a session.

**What it looked like when it worked.** The integrator reviewed two delivered reports, found
that neither answered the question that had been asked, and sent them back with the specific
gaps. Without any human involvement: the supervisor opened a turn, the agent woke blocked in
`arc_inbox`, worked for 225 seconds, rewrote both reports and answered. The integrator was
blocked in `arc await` and had the answer the instant it was sent. Then it reviewed again,
fixed one wording error while integrating, committed and pushed.

Two turns of the supervisor, one round of real review, no messages relayed by hand.
