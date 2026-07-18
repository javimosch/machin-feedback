# machin-feedback

> **One inbox for every app's `feedback` command.**
> An agent-first feedback relay — one static machin binary. Agents send bugs/ideas/praise; you browse it all in one place, across every app.

```sh
# any tool's feedback command posts here (open, no creds):
curl -X POST https://feedback.example.com/v1/feedback \
  -d '{"app":"hart","kind":"bug","message":"publish 422 on a valid page","id":"..."}'
# {"ok":true,"id":"...","stored":true}
```

Terminal agents are the users of your CLIs, and they hit friction that evaporates silently.
`machin-feedback` gives them a channel — and gives you **one cross-app inbox** instead of eight
per-app silos. Built in [machin](https://github.com/javimosch/machin) (MFL); the daemon *and*
the CLI in a single binary.

## Design

- **Capture + browse, not a support desk.** No threads, no replies, no status workflow. The value
  is the *frequency and context* of what agents report, not ticket management.
- **Submitting is open; reading is gated.** Agents have no credentials, so `POST /v1/feedback`
  takes no auth — but it's **rate-limited + size-capped**. Reading (`GET` + dashboard) requires
  `FEEDBACK_ADMIN_TOKEN`.
- **Idempotent on a client id.** A `feedback` command that dual-writes (to its own app *and* here)
  sends the same `id` to both; `INSERT OR IGNORE` means retries and dupes collapse to one row.
- **One SQLite file, one binary.** No index to corrupt, nothing to install at runtime.

## API

| verb | route | auth | does |
|---|---|---|---|
| POST | `/v1/feedback` | open (rate-limited) | store feedback |
| GET  | `/v1/feedback?app=&limit=` | `Bearer FEEDBACK_ADMIN_TOKEN` | list, newest first (JSON) |
| GET  | `/` | admin cookie | dashboard (per-app chips + recent) |
| GET  | `/_health` | open | liveness |

**Submit payload** (all optional except `message`):
```json
{
  "app": "hart",
  "version": "0.2.9",
  "kind": "bug",
  "message": "what happened / the ask",
  "context": "the command, exit code, whatever the agent chose to attach",
  "reporter": "claude-code",
  "id": "client-generated-uuid"
}
```
> **Never put secrets in `context`.** A `feedback` command should attach a command *name* + exit
> code, not full argv (tokens live in args). Keep it minimal; let the agent opt into more.

## Run it

```sh
./build.sh                                  # needs `machin` on PATH -> ./machin-feedback
FEEDBACK_DB=~/.machin-feedback.db \
FEEDBACK_ADMIN_TOKEN=<secret> \
FEEDBACK_PUBLIC=https://feedback.example.com \
  ./machin-feedback serve 3900
```

Expose it behind any reverse proxy that terminates TLS (nginx/Caddy/Traefik/Cloudflare) and set
`FEEDBACK_PUBLIC` so links are canonical. Browse at `/` (sign in with the admin token).

| env | default | |
|---|---|---|
| `FEEDBACK_DB` | `~/.machin-feedback.db` | SQLite store |
| `FEEDBACK_ADMIN_TOKEN` | — | gates reads + dashboard (unset = reads **off**) |
| `FEEDBACK_PUBLIC` | reflects Host | canonical base for returned URLs |
| `FEEDBACK_MAX_PER_MIN` | `30` | per-IP submit cap |
| `FEEDBACK_MAX_BYTES` | `16384` | max body size |
| `FEEDBACK_COOKIE_SECRET` | random | pin to keep dashboard sessions across restarts |
| `FEEDBACK_PORT` | `3900` | listen port |

## Agent-first

JSON on stdout, structured errors on stderr, semantic exit codes. The submit endpoint answers
`{"ok":true,"id":...,"stored":true}` so a dual-writing `feedback` command can report exactly what
landed where.

## The `feedback` command contract (for adopting apps)

Any CLI adds a `feedback` command that **dual-writes, best-effort**: POST to its *own* daemon and,
independently, POST here. Both with short timeouts; neither failure should ever break the agent's
flow. A client-generated `id` shared across both writes makes it idempotent.

This is the **reference relay** for that convention. The convention itself — the normative
contract, the JSON Schema, and a copy-paste recipe for adding a `feedback` command in any
language — is written up as **[cli-feedback-spec](https://github.com/javimosch/cli-feedback-spec)**.
Adopters: hart, grepapi, crmd, remotecmd (rcmd), portier, machin-idp, chatsnip.

## Build

```sh
./build.sh    # machin encode framework/machweb.src src/feedback.src -> one static binary
```

MIT.
