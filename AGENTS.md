# AGENTS.md — rusto

> Cross-platform quick launcher. Tauri v2 + Svelte 5 + Tailwind v4.
> Git repo folder: `ahko`. Product / crate / config dir name: `rusto`.

## Agent Instructions (Read First)

**Every agent working in this repo MUST:**

1. **Read this file** before making substantive changes (architecture, IPC, deps, behavior, workflow).
2. **Treat this document as the source of truth** for project structure, conventions, and commands.
3. **Update this file in the same change** whenever a substantive edit would make any section stale. Do not leave AGENTS.md out of sync with the codebase.
4. **Before finishing**, scan the diff against the triggers in [Critical Self-Sync Rule](#critical-self-sync-rule) and update affected sections.

If unsure whether a change is substantive, update AGENTS.md anyway — stale docs cost more than a one-line fix.

## Project DNA

- **Purpose**: 4×4 keyboard-driven grid launcher scanning a user-configured watch folder. Supports subfolders, custom openers, AppImage spawn on Linux.
- **Backend**: Rust single-file (`src-tauri/src/lib.rs`, ~436 lines). All types, config, scanning, launch logic, window management, and tray in one module.
- **Frontend**: SvelteKit SPA (SSR disabled, `adapter-static`). Two routes: main launcher (`+page.svelte`) and setup window (`setup/+page.svelte`).
- **IPC**: Tauri `invoke()` for commands (`load_config`, `save_config`, `scan_launcher`, `launch_item`, `hide_window`, `open_setup_window`). Tauri events (`config-changed`, `reload-request`, `show-request`) for push notifications Rust → frontend.
- **Config**: JSON at `{OS_config_dir}/rusto/config.json`. Types mirror between Rust structs and TypeScript (camelCase serde).

## Architecture

```
src/
├── routes/+page.svelte          # Main launcher UI (4×4 grid, keyboard, stagger layout)
├── routes/+layout.svelte        # Root layout shell
├── routes/+layout.ts            # SSR disabled (SPA mode for Tauri)
├── routes/setup/+page.svelte    # Config window (watch folder, hotkeys, openers)
├── routes/setup/+page.ts        # Setup route config
├── lib/default-openers.ts       # Default CustomOpener presets
├── app.css                      # Tailwind v4 import + global resets
└── app.html                     # HTML shell

src-tauri/
├── src/lib.rs                   # ALL backend logic (types, config, scan, launch, tray, window)
├── src/main.rs                  # Entry → lib::run()
├── tauri.conf.json              # Tauri v2 config (frameless transparent window, tray)
├── capabilities/default.json    # Permissions for main + setup windows
└── icons/                       # Bundle icons
```

## Key Design Decisions

- **Single-file backend**: No Rust module splitting. Keep all logic in `lib.rs`.
- **Error handling**: `Result<T, String>` with `.map_err(|e| e.to_string())`. No custom error types.
- **Window model**: Main launcher is a frameless transparent webview sized to the cursor monitor's `work_area` (Kando-style). Setup opens as a separate frameless transparent window with in-app title bar (drag + close). Tiles are opaque DOM elements.
- **Svelte 5 runes only**: Use `$state`, `$derived`, `$derived.by`. No legacy reactive `$:` syntax.
- **Naming**: Rust `snake_case`, TypeScript `camelCase`, CSS/Tailwind `kebab-case`.

## Commands

```bash
npm run check          # Svelte type/a11y check (ALWAYS run after frontend changes)
npm run build          # Static frontend build → build/
npm run tauri dev      # Dev mode with hot reload
npm run tauri build    # Full release build + platform bundle
cargo check            # Rust type check (run after Rust changes, in src-tauri/)
```

## Coding Rules

- **No comments** unless explicitly requested.
- **No test framework** is set up. Validation is via `npm run check` + `cargo check`.
- **Minimal changes**: Prefer focused, surgical edits. Avoid refactoring unrelated code.
- **Frontend validation**: Run `npm run check` after any `src/` change.
- **Backend validation**: Run `cargo check` (in `src-tauri/`) after any Rust change.
- **Config sync**: Rust `AppConfig`/`CustomOpener`/`LauncherItem` structs must stay in sync with TypeScript type definitions in Svelte files.
- **Key assignment**: Folder items use `[key]name` naming convention. Keys are from `ITEM_KEYS` array in `lib.rs`.
- **Window behavior**: Main window hides on blur. `current` folder state resets before hide. Pointerdown outside filled tiles triggers hide.
- **Platform awareness**: Linux skips wake hotkey in setup UI. AppImage gets direct detached spawn. Tray creation failure is non-fatal.

## Dependencies (Do Not Assume Availability)

- **Always verify** a crate/package exists in `Cargo.toml` or `package.json` before importing.
- Tauri plugins: `tauri-plugin-opener`, `tauri-plugin-single-instance` (registered in `lib.rs`).
- Rust crates: `serde`, `serde_json`, `dirs`, `open`, `mouse_position`.
- Frontend: `@tauri-apps/api`, `@tauri-apps/plugin-opener`, Tailwind v4 via `@tailwindcss/vite`.

## Critical Self-Sync Rule

**When any agent makes substantive changes to the project's architecture, core logic, dependencies, directory structure, commands, or development workflow — it MUST evaluate and update the corresponding sections of this AGENTS.md in the same change.** The document must always reflect the project's true current state.

### Triggers (update when any apply)

| Change | Section(s) to update |
|--------|----------------------|
| Add/remove/rename source files | `Architecture` |
| New/removed Tauri commands or events | `Project DNA` (IPC) |
| Add/remove deps (npm or Cargo) | `Dependencies` |
| Build/dev script changes | `Commands` |
| User-visible behavior changes | `Coding Rules`, `Project DNA` |
| Error-handling or naming convention changes | `Coding Rules`, `Key Design Decisions` |
| Backend grows/shrinks significantly | `Project DNA` (line count) |
| Product/config identifier rename | `Project DNA`, header, repo note |

### Sync checklist (run before marking work done)

- [ ] Does `Architecture` tree match actual files?
- [ ] Are all Tauri commands/events listed correctly?
- [ ] Do `Commands` still match `package.json` / workflow?
- [ ] Are dependencies accurate vs `Cargo.toml` and `package.json`?
- [ ] Do coding rules still match how the code behaves?

**Never** defer AGENTS.md updates to a follow-up task. Stale AGENTS.md misleads the next agent and compounds errors.
