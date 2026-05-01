# mc-tui

A small TUI (terminal UI) manager for a local Minecraft Paper / Purpur server.

> This file is the canonical project doc. `README.md` and `AGENTS.md` are symlinks to it — humans, Claude, and other coding agents all read the same source of truth.

## What it does

Manages the boring parts of running a friend-group Minecraft server without leaving the terminal. Eight tabs:

- **1 Worlds** — list every world directory under your server dir, see which is current, switch the active level by writing `level-name`. `N` creates a new world (writes the new name; the server generates the dir on next start).
- **2 Players** — unified roster merged from `whitelist.json`, `ops.json`, `world/playerdata/*.dat`, and the rolling log corpus (`logs/latest.log` + `logs/*.log.gz`). Toggle whitelist with Enter, op state with `o`, op level 1–4 with `←/→`, purge with `d`, add a new name with `a`. `w` flips the `white-list` setting in `server.properties` (whitelist column hides while disabled). Names that got rejected with "not whitelisted" surface a `denied YYYY-MM-DD` marker so admitting a friend is one keystroke.
- **3 Config** — browse `server.properties`, edit any value with `Enter`. In Chinese mode each row shows a 中文 annotation; the right-side detail panel shows default + range + restart-required + bilingual description.
- **4 Logs** — tail `logs/latest.log`.
- **5 YAML** — pick a Paper/Purpur YAML (`paper-global.yml`, `purpur.yml`, etc.), enter the file, navigate the flattened tree, edit leaf scalars in place.
- **6 Backups** — list archives in `<server-dir>/backups`, `../backups`, `../mc-backups`, `../<name>-backups`. Newest-first with size + age columns.
- **7 Server (运维)** — restart now, run `backup.sh`, schedule a daily restart / backup as a `systemd --user` timer, pre-generate chunks via `tmux send-keys` to the server console (`chunky` plugin), show the `tmux attach` command. The top of this tab also lists every IPv4 interface.
- **8 SakuraFrp** — pull the user's account header + tunnel list directly from `api.natfrp.com/v4`. Enter on a row copies the public address; `t` opens the token prompt; `r` re-fetches; `c`/`m`/`d` create/migrate/delete tunnels via the API; `e`/`x` enable/disable a tunnel through mc-tui's directly-managed `frpc` subprocess (v0.15 — replaces the docker launcher path).

Plus an always-visible **join address bar** between the status row and the tab bar — click the chip to copy `<ip>:<port>` to the clipboard via `wl-copy`.

It's intentionally a thin layer over the same files Paper/Purpur already write. Stop using `mc-tui` at any time and your server keeps working.

## Install

### One-line install (recommended)

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/NihilDigit/mc-tui/main/scripts/install.sh | sh

# Windows (PowerShell)
irm https://raw.githubusercontent.com/NihilDigit/mc-tui/main/scripts/install.ps1 | iex
```

The script detects your platform, fetches the latest release, and drops `mc-tui` into `~/.local/bin` (Linux/macOS) or `%LOCALAPPDATA%\mc-tui` (Windows). Override the install dir with `MC_TUI_INSTALL_DIR=...`; pin a version with `MC_TUI_VERSION=v0.7.0`.

### Pre-built binaries (manual)

GitHub Releases ship binaries for Linux / macOS / Windows on x86_64 and aarch64. Download the archive for your platform, extract, run.

### From source

```bash
cargo install --git https://github.com/NihilDigit/mc-tui
```

Or clone and build:

```bash
git clone https://github.com/NihilDigit/mc-tui
cd mc-tui
cargo build --release
./target/release/mc-tui --server-dir /path/to/your/server
```

## Usage

```bash
mc-tui --server-dir /path/to/server
# or via env var
MC_SERVER_DIR=/path/to/server mc-tui
# without either, mc-tui falls back to the last server-dir it remembers
# in $XDG_CONFIG_HOME/mc-tui/state.toml
mc-tui
```

The directory must contain `server.properties`. `whitelist.json` and `ops.json` will be created if missing.

### Subcommands

```bash
mc-tui new <dir>          # scaffold a fresh server: detect Java, fetch jar, write eula + start.sh
mc-tui screenshot --tab worlds --lang zh --width 130 --height 32
                          # render one TUI frame to stdout (used for visual QA)
```

`mc-tui new` flags: `--server-type paper|purpur` (default purpur), `--mc-version 1.21.4` (default: latest), `--first-boot` (run the server once to generate `server.properties`), `--force` (allow non-empty target dir).

### Keys

| Key | Action |
|---|---|
| `1` … `8` | Jump to tab |
| `1`…`5` | Jump to tab (Overview / Players / Worlds / Settings / Network) |
| `Tab` / `Shift+Tab` | Cycle tabs |
| `↑` / `↓` | Move selection (or scroll the Logs overlay) |
| `PgUp` / `PgDn` / `Home` / `End` | Page / boundary scroll inside the Logs overlay |
| `Enter` | Switch world / Toggle whitelist (Players) / Edit setting / Copy tunnel address (Network) |
| `Esc` | Close any overlay; back to file picker from Settings sub-views |
| `a` | Add player (Players tab — opens whitelist-add prompt) |
| `d` | Purge player from whitelist + ops (Players); delete tunnel (Network) |
| `o` | Toggle op for selected player (Players); open natfrp.com (Network) |
| `←` / `→` | Cycle op level for selected player (Players tab — wraps 1↔4) |
| `w` | Toggle `white-list` setting (Players tab) |
| `e` / `x` | Enable / disable selected tunnel (Network); also recovers the forwarder if it crashed |
| `c` / `m` | Create / migrate tunnel (Network) |
| `i` | One-key SakuraFrp setup wizard (Network) |
| `t` | Set SakuraFrp API token (Network) |
| `A` | Manual SakuraFrp address override (Network) |
| `n` | Toggle the (collapsed by default) NIC list (Network) |
| `Y` | Copy share-text to clipboard (any tab) |
| `N` | New world (Worlds tab) |
| `S` / `X` / `R` | Start / stop / restart the server (any tab) |
| `B` | Run `backup.sh` now (any tab) |
| `L` | Open fullscreen log overlay (any tab) |
| `?` | Open help overlay (legend + every shortcut) |
| `:` | Open command palette (advanced ops: schedule, pre-gen chunks, tmux attach, systemd paths) |
| `D` | Switch `--server-dir` at runtime |
| `T` | Toggle 中 / EN (was `L` pre-v0.16; `L` is now logs) |
| `r` | Refresh from disk (and from SakuraFrp API on the Network tab) |
| `q` | Quit |
| Mouse | Click tab bar, list rows, or the join chip (chip → wl-copy) |

When a prompt is open: type the value, `Enter` to confirm, `Esc` to cancel.

## Behavior contracts (so you can predict what it touches)

- **Worlds tab — switching**: refuses while server is running. Writes `level-name=<chosen>` to `server.properties`. **Drops comments** in `server.properties` (Java properties is quirky and round-tripping comments isn't worth the complexity). Key/value order is preserved.
- **Worlds tab — N (new)**: refuses while server is running. Validates the name (no `/`, `\`, `.`, `..`). Writes `level-name=<name>` only — the world directory + `level.dat` are generated on next server start. The list shows a placeholder entry for the pending world so you can see the state took.
- **Players tab — toggle whitelist (Enter)**: rewrites `whitelist.json` as pretty-printed JSON. UUID for new entries is the offline UUID (Java/Paper offline mode). No-op when `white-list` is disabled in `server.properties`. **Refuses to write if `whitelist.json` failed to parse on read** (would clobber user's broken-but-recoverable file). Same guard for `ops.json`.
- **Players tab — toggle op (`o`)**: rewrites `ops.json`. New ops default to level 4, `bypassesPlayerLimit=false`. `←/→` cycles the level 1↔4 (wraps). `d` purges the selected player from both `whitelist.json` and `ops.json` in one shot.
- **Players tab — `w`**: writes `white-list=true|false` into `server.properties`. mc-tui does **not** push a `/whitelist reload` to the running server; the change applies on next restart or after a manual reload.
- **Players tab — name discovery**: `whitelist.json` ∪ `ops.json` ∪ `world/<level>/playerdata/*.dat` (UUIDs) ∪ all `logs/latest.log` and `logs/YYYY-MM-DD-N.log.gz`. The log scan harvests `UUID of player NAME is UUID` lines (name↔UUID mapping) and `Disconnecting NAME (...): You are not whitelisted on this server!` lines (denied attempts, dated by the log filename).
- **Config tab — edit**: same `server.properties` write path as Worlds.
- **Logs tab — read-only**: tails `logs/latest.log`.
- **YAML tab — edit leaf**: full read → mutate `serde_yaml::Value` → write the file. Keeps key order. Preserves nested structure.
- **Backups tab**: read-only display; restore is intentionally not automated (do it by hand to avoid surprises).
- **Server tab — Restart now**: `tmux send-keys stop Enter` → poll for pid disappearance up to 30 s → `tmux new-session` to start.
- **Server tab — Pre-gen chunks**: refuses if the tmux session is not alive; otherwise sends `chunky world <level>` / `chunky center 0 0` / `chunky radius <r>` / `chunky start` to the server console via `tmux send-keys`. Watch progress by attaching to the session.
- **Server tab — Schedule daily restart/backup**: writes a pair of `~/.config/systemd/user/mc-tui-<kind>-<slug>.{service,timer}` files. mc-tui does **not** run `systemctl --user daemon-reload` for you; the status bar shows the exact command to copy.

## Server lifecycle

mc-tui starts the server inside a detached tmux session: `tmux new-session -d -s mc-tui-<slug> -c <server-dir> 'bash start.sh'`. Stopping uses `tmux send-keys -t <session> stop Enter` — Minecraft's own console `stop` command, which runs the synchronous shutdown handler on the main thread. **This is the only reliable shutdown path.** Sending SIGTERM to the JVM races with startup and can leave a half-dead process (port closed, world ticking, no progress). If `tmux` is missing, mc-tui falls back to `setsid bash start.sh` for start and SIGTERM for stop.

You can `tmux attach -t mc-tui-<slug>` from another terminal at any time to watch console output or run admin commands directly. The `9 Server` tab has a "show tmux attach command" action that copies the command to the clipboard.

## Detecting whether the server is running

`server_running_pid()` walks the process list (via `sysinfo`) for any Java process whose argv mentions a `paper` / `purpur` / `spigot` jar and whose CWD is the canonical server dir. **It's sticky**: once a pid matches, mc-tui keeps using it across refreshes as long as the process exists and still looks like our server — this stops the status bar from flickering between pids when `cwd` is briefly unreadable. If the previous pid is gone, mc-tui re-scans and picks the lowest matching pid for stability. Multiple matches (e.g. you're running two Minecraft servers from the same dir) is unsupported.

## Project layout

```
src/
├── main.rs    App state machine, run loop, mouse / event handlers, main(), screenshot subcommand.
├── cli.rs     Cli + Cmd + ServerType + scaffold_new + Java/curl/Aikar/first-boot helpers.
├── data.rs    Data structs + filesystem / network IO (worlds, whitelist, ops, properties, backups, YAML walker, NIC discovery, sticky pid detection).
├── i18n.rs    Lang + Strings struct + EN/ZH consts + fmt_* parametric helpers + property_zh annotations + PropertyMeta lookup table.
├── natfrp.rs  Blocking REST client for api.natfrp.com/v4 (UserInfo / Tunnel / Node) + parse helpers — feeds the SakuraFrp tab.
├── sys.rs     state.toml + natfrp.token (0600) persistence, tmux session helpers, POSIX shell quote, path/tilde helpers.
└── ui.rs      Every ratatui draw_* function + ui() dispatcher + layout helpers.

Cargo.toml     Deps: ratatui, crossterm, clap, serde, serde_json, serde_yaml, md-5, chrono, sysinfo, unicode-width, ureq.
.github/workflows/release.yml   Tag-triggered release builds for 6 targets.
```

Module dependency rule: **ui ← app/main ← {i18n, data, sys, cli}**. UI reads `App` fields (they're `pub`) but never mutates business state — disk writes go through `App::*` methods in `main.rs`. Tests live at the bottom of each module under `#[cfg(test)] mod tests`.

## Development

```bash
cargo run -- --server-dir /path/to/your/server
cargo test       # 60 unit tests across all modules
cargo build --release
```

### Visual QA

```bash
cargo run -- --server-dir /mnt/data/mc-server screenshot \
    --tab server --lang zh --width 130 --height 32 --select 0 \
    > /tmp/mc-tui-shot.txt
```

The `screenshot` subcommand dumps one rendered frame to stdout as plain text using `ratatui::backend::TestBackend`. Each module's `cargo test` block plus a `screenshot` pass for the touched tab is the standard QA flow before committing UI work.

### Style

- Multi-module since v0.6. Add a new module when a logical unit grows past ~500 lines or has clear cross-cutting users; otherwise keep it in `main.rs`.
- No `unsafe`, no `unwrap()` on user-facing paths (use `?` and `anyhow::Context`). `unwrap()` in tests is fine.
- Errors bubble to `main` via `anyhow::Result`. No `Box<dyn Error>` decay.
- All UI strings route through `Strings` + `EN`/`ZH` consts in `i18n.rs`, or `fmt_<event>(lang, args...)` for parametric ones. Inline `t(lang, "en", "zh")` is allowed for one-off cases but `Strings` is preferred — keep new translations colocated with old.
- `App` fields are `pub` so `ui.rs` can read them; only `main.rs`'s `impl App` should write them.

### Tests

43 unit tests across:

- Offline UUID format / version bits / determinism (`data.rs`)
- `server.properties` round-trip (`data.rs`)
- `whitelist.json` / `ops.json` round-trip + parse-error propagation + corruption guard (`data.rs`, `main.rs`)
- `scan_worlds` placeholder behavior for pending `level-name` (`data.rs`)
- Backup file recognition + scan (`data.rs`)
- YAML flatten / set / scalar parser (`data.rs`)
- NIC classification + ZeroTier-first ordering (`data.rs`)
- Java version parser + Aikar flags + Purpur URL builder + heap sizing (`cli.rs`)
- Lang code roundtrip + property_zh coverage + PropertyMeta coverage + detail strings non-empty + fmt_* helpers (`i18n.rs`)
- `parse_hh_mm` + `server_dir_slug` + `tmux_session_name` + `shell_quote_sh` + `expand_tilde` + persisted_state roundtrip (`sys.rs`)
- `split_list_detail` collapse + `op_level_meaning` localization + `fmt_age` + op-level cycle wrap (`ui.rs`, `main.rs`)
- `rect_contains` (`main.rs`)

If you add a write path to a new file format, add a round-trip test. They're cheap and catch the dumb bugs.

## For coding agents (Claude, Cursor, etc.)

If you're an LLM working on this repo:

1. **Module boundaries are real now.** Adding to `i18n.rs`? Use the `Strings` + EN/ZH pattern. Adding a new tab? UI render goes in `ui.rs`, App state in `main.rs`, persistence in `sys.rs` or `data.rs`. Don't dump everything in `main.rs`.
2. **Don't add features the user didn't ask for.** No "while we're here" cleanups, no extra tabs, no daemons that watch the server. Keep PRs scoped.
3. **Run `cargo test` before claiming done.** UI changes need manual QA — render a screenshot via the `screenshot` subcommand and inspect it. Say so explicitly when you can't verify visually.
4. **Don't hardcode paths or user-specific values.** The whole CLI is parameterized via `--server-dir` for a reason; preserve that.
5. **Never commit binaries**, `target/`, `~/.minecraft`, or anything under user server dirs. We DO commit `Cargo.lock` since this is a binary crate.
6. **`tmux` is the start/stop path.** Don't add SIGTERM as a primary mechanism — we tried, it raced with Paper's startup and left half-dead processes. tmux + console `stop` is what works.
7. **App fields are pub for `ui.rs`, not for free editing.** Keep mutation paths funneled through `impl App` methods so they can update `App::status` and run `refresh_all()` consistently.

## Roadmap

Tracked here instead of GitHub issues for now. Mark with date when shipped; keep oldest at the bottom.

### v0.2 — interactivity (shipped 2026-05-01)

- [x] **Server lifecycle from TUI**: `S` to start (tmux session), `X` to stop (tmux send-keys `stop`).
- [x] **Create new world**: `N` in Worlds tab → prompt → write `level-name`. Placeholder shown in list until generated.
- [x] **Mouse support**: tab bar clicks, list row clicks, join-bar chip clicks.
- [x] **Server-dir switcher**: `D` opens a prompt; validates `server.properties` exists.
- [x] **Persist last-good server-dir** in `$XDG_CONFIG_HOME/mc-tui/state.toml`.

### v0.3 — i18n (shipped 2026-05-01)

- [x] `Lang::{En, Zh}` enum, `T` toggles (was `L` until v0.16, when `L` was reassigned to the logs overlay), persisted across runs.
- [x] All UI strings, hint bar, prompt labels, status messages route through `Strings` + EN/ZH consts.
- [x] Common `server.properties` keys get a Chinese annotation in the Config tab; raw key still visible.

### v0.4 — server scaffolder (shipped 2026-05-01)

- [x] `mc-tui new <dir>`: Java check, version resolution via Paper / Purpur APIs, jar download via `curl`, `eula.txt` + `start.sh` (Aikar's flags + RAM-aware heap), optional `--first-boot`.
- [x] Refuses non-empty target without `--force`.

### v0.5 — beyond (shipped 2026-05-01)

- [x] Edit `paper-global.yml` / `paper-world-defaults.yml` / `purpur.yml` (file picker → flat row editor).
- [x] Backup tab — list archives in candidate directories, sorted newest-first.
- [x] Hover-detail panels for Worlds / Whitelist / Ops / Config (lists split 70/30, right side describes the selection).
- [x] ~~RCON bridge — `i` to send a command, history pane.~~ Dropped post-v0.6 — `tmux attach` covers ad-hoc commands; pre-gen-chunks moved to `tmux send-keys`.

### v0.6 — server ops (shipped 2026-05-01)

- [x] Restart-now action.
- [x] Run-`backup.sh`-now action.
- [x] Schedule daily restart / backup via `systemd --user` timer.
- [x] Pre-generate chunks via `tmux send-keys` to the server console (`chunky`).
- [x] Always-visible join-address bar (ZeroTier-aware) + click-to-copy.
- [x] `tmux attach` command exposed as a Server-tab action.

### v0.7 — release (pending tag push)

- [x] `scripts/install.sh` + `scripts/install.ps1`: platform-detect, GH-API tag resolve, extract to `~/.local/bin` (or `%LOCALAPPDATA%\mc-tui`). Honors `MC_TUI_INSTALL_DIR` and `MC_TUI_VERSION`.
- [x] README one-liner pointing at the raw scripts on the `main` branch.
- [ ] **`git tag v0.7.0 && git push --tags`** — triggers `.github/workflows/release.yml`, which builds 6 archives and creates the GH release. Run this when you're ready; mc-tui doesn't auto-push.

### v0.8 — SakuraFrp join-bar (shipped 2026-05-01)

- [x] Persist `sakurafrp_address` in `state.toml`; surface as a chip in the join-bar with click-to-copy.

### v0.9 — SakuraFrp launcher container (shipped 2026-05-01)

- [x] Probe the `natfrp-service` Docker container via `docker inspect`; surface state marker (●/○/✗/?) on the SakuraFrp join-bar row.
- [x] Server-tab actions: start / stop / restart / show-logs for the launcher container.
- [x] Drop the dedicated ZeroTier classification — fold `zt*` into the generic VPN/TUN bucket.

### v0.10 — SakuraFrp REST API (shipped 2026-05-01)

- [x] Blocking `ureq`-based client for `api.natfrp.com/v4` (`/user/info`, `/tunnels`, `/nodes`, `/tunnel/traffic`).
- [x] New `9 SakuraFrp` tab: user header (name / token / plan / traffic) + tunnels list (id / name / node / type / public address) + actions hint.
- [x] Token stored at `~/.config/mc-tui/natfrp.token` (`0600`); never written to logs or `state.toml`.
- [x] Server-tab join-bar SakuraFrp row prefers the API-derived public address; falls back to the v0.8 manual `sakurafrp_address` when the token is unset.
- [x] `Enter` on a tunnel row copies its `host:port` to the clipboard via `wl-copy`; `t` opens the token prompt; `r` re-fetches.
- [x] API never fires from `refresh_all()`; only on first SakuraFrp tab visit and explicit `r`.

### v0.12 — SakuraFrp onboarding & error diagnostics (shipped 2026-05-01)

- [x] Numbered 3-step onboarding when no token is set (`o` to open natfrp.com, `t` to paste).
- [x] Empty-tunnels guidance branch (forwards-references v0.13's `c` create command + browser fallback + launcher GUI fallback).
- [x] `NatfrpError` enum (`Unauthorized` / `Forbidden` / `ServerError(u16)` / `HttpError(u16)` / `Network(String)` / `Parse(String)`) replacing raw anyhow strings; centralized `translate_natfrp_error` reusable by v0.13 write paths.
- [x] Sparkle/mihomo presence detector (`mihomo_running()` via `pgrep -f sparkle`); dim warning line on tab when running. Never auto-kills.
- [x] Traffic plan % usage with ≥80% yellow / ≥95% red color gradient; launcher-down hint surfaced on the actions row when applicable.

### v0.13 — SakuraFrp tunnel write operations (shipped 2026-05-01)

- [x] `Client::create_tunnel` / `migrate_tunnel` / `delete_tunnels` over `application/x-www-form-urlencoded` (SakuraFrp v4 expects forms, not JSON).
- [x] Full-screen node picker overlay; game-friendly nodes float to top, then VIP ascending. Esc cancels, Enter picks. `c` opens picker with `CreateTunnel` purpose; `m` with `MigrateTunnel`.
- [x] Three-step create flow: name → node picker → port. Default name = `mc_<server-dir-slug>` (hyphens normalized to `_`); `validate_tunnel_name` mirrors server-side rules (alnum + `_`, ≤32 chars).
- [x] `d` on SakuraFrp tab fires a confirm prompt that requires typing the tunnel name verbatim (not just "yes") — extra friction for ADHD users with `d`-press muscle memory from the Players tab.
- [x] Non-game-friendly node selection appends a dim warning to status (long-idle TCP can drop after ~30s).
- [x] `screenshot --picker create|migrate` for QA without firing destructive ops.

### v0.15.1 — One-key setup wizard (shipped 2026-05-01)

- [x] `i` on the SakuraFrp tab opens a confirm prompt summarizing the planned migration: download frpc → enable every visible tunnel → start frpc. User types `yes` to commit, anything else cancels.
- [x] Download path: `data::download_frpc(url, target)` streams the official binary in 64 KiB chunks via the existing ureq agent, atomically renames the temp file into place, and chmod 0755. Url + md5 come from the `/v4/system/clients` manifest (host arch resolved via `data::host_target_for_manifest`).
- [x] Md5 verification (`data::verify_md5`) — corrupted downloads are deleted before the wizard can use them, so a half-fetched binary never gets executed.
- [x] No docker-removal step: by design, the wizard doesn't touch any pre-existing launcher container. If the user has one running it'll fight with mc-tui's frpc; the migration step (`docker stop natfrp-service`) is a deliberate manual op.

### v0.15 — Direct frpc subprocess (shipped 2026-05-01)

- [x] mc-tui now runs the SakuraFrp `frpc` binary itself via tmux instead of routing through the launcher container. Sub-second restart on tunnel toggle (vs ~10 s container restart).
- [x] `find_frpc_binary` walks `$PATH` then `~/.config/mc-tui/frpc`. We never auto-download — keeps redistribution off the table. When missing, the SakuraFrp tab status surfaces the official download URL (resolved live from `api.natfrp.com/v4/system/clients`) and copies it to the clipboard.
- [x] `frpc -f "TOKEN:id1,id2" -n` lets frpc pull tunnel config from SakuraFrp directly — no local `frpc.toml` to manage.
- [x] `e` / `x` add/remove the selected tunnel id from `frpc_enabled_ids` (persisted in state.toml), then bounce the frpc tmux session. Restart is sub-second.
- [x] Server tab actions: `Start frpc (tmux)` / `Stop frpc (tmux)` / `Restart frpc` / `Copy tmux attach command for frpc`. Replaces the v0.9 docker-launcher actions, which are gone.
- [x] Join-bar `frp` marker reflects the frpc subprocess: ● running, ○ configured but not running, ✗ no binary, ? no config.

> **Migration from v0.14.1**: stop the launcher container (`docker stop natfrp-service`) before pressing `e` to avoid two frpc instances fighting for the same tunnel. v0.15 keeps `state.toml::sakurafrp_container` parseable so existing state files don't error, but mc-tui no longer touches docker.

### v0.14 / v0.14.1 — SakuraFrp launcher single-tunnel lifecycle (shipped 2026-05-01)

- [x] Read-side: `read_launcher_auto_start` pulls `/run/config.json::auto_start_tunnels` from the container and the SakuraFrp tab renders ▶/■/? markers per tunnel.
- [x] Write-side (v0.14.1): `e` adds the selected tunnel id to `auto_start_tunnels`; `x` removes it. Both paths edit the config via `docker exec python3` and restart the launcher container (~10 s). Idempotent — no-ops a second `e` on an already-enabled tunnel.
- [x] `parse_launcher_password` finds `webui_pass` (current 3.1.x), with fallbacks to older field names. Plaintext password — feeds `launcher_challenge_response` (HMAC-SHA256 of the `ilsf-1-challenge` token), validated against an RFC 4231 test vector and a stable-output test.
- [x] `LauncherClient` exists as a future seam for v0.14.2 websocket / gRPC-Web bring-up; rustls + `NoVerifier` plumbed but currently unused (config-file approach makes the websocket optional). Deliberately marked `#[allow(dead_code)]` to make the v0.14.2 follow-up obvious.

> **Why config-file instead of websocket-RPC:** the launcher's local control protocol is gRPC-Web protobuf with a private `.proto` schema (`UpdateTunnel` / `ReloadTunnels` / `StreamTunnels` are confirmed method names; field tags aren't documented). Reverse-engineering would have shipped a brittle client. Editing the durable on-disk state + container restart matches the user's existing `docker restart natfrp-service` muscle memory and works without a schema.

### Backlog (no version yet)

- [ ] v0.14.2 — wire the websocket bring-up: `wss://127.0.0.1:7102/launcher/control`, subprotocol `natfrp-launcher-grpc`, ilsf-1 handshake, then gRPC-Web protobuf. Avoids the 10 s container restart on `e`/`x`. Requires reverse-engineering the `.proto` (or upstream documentation).
- [ ] Backup restore action (with confirmation prompt + extract into a sibling dir, never overwrite the live world).
- [ ] More YAML schema awareness for `paper-global.yml` (right-side panel showing what each key does, mirrored from upstream docs).

## License

MIT. See `LICENSE`.
