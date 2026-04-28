# AGENT.md — rusto coding-agent context

This file is the compact project map for coding agents. **Any agent that changes code, config, dependencies, commands, behavior, or directory structure must update this file in the same change.** Keep it concise and accurate.

## Project

- Name: `rusto`
- Purpose: cross-platform quick launcher for Windows and Ubuntu, rebuilt from the AHK `ahko` reference in `https://github.com/Nigh/ahko`.
- Stack: Rust + Tauri v2 backend, Svelte 5 + SvelteKit + TypeScript frontend, Tailwind CSS 4 via Vite. Uses `tauri-plugin-single-instance` to ensure only one app instance runs.
- Root is now the app root.

## Important paths

- `package.json`: npm scripts/deps. App package name is `rusto`.
- `src/routes/+page.svelte`: main launcher (16-key grid only), keyboard handling, Tauri invokes.
- `src/lib/default-openers.ts`: default `custom_openers` for the frontend (mirrors Rust defaults: Python only).
- `src/routes/setup/+page.svelte`, `src/routes/setup/+page.ts` (`prerender`): Setup window UI (static `build/setup.html` for release; dev uses `devUrl` + `/setup`). Styling aligned with main launcher (**zinc** + **pink** accent). On **Linux** builds, the **Show (wake) hotkey** field is omitted (not effective in-app); see README for OS-level shortcuts.
- `src/routes/+layout.svelte`, `src/app.css`: global layout/styles.
- `src-tauri/src/lib.rs`: Rust app logic and Tauri commands.
- `src-tauri/tauri.conf.json`: Tauri v2 config. `productName = rusto`, identifier `com.xianii.rusto`, frontend dist is `../build`. Main window label `main` (frameless, **transparent**, no shadow; **inner size/position** are set in Rust to the cursor monitor’s **`work_area`** on startup and whenever the window is shown — Kando-style full work-area shell; tiles are **opaque** DOM).
- `src-tauri/capabilities/default.json`: Tauri permissions for `main` and `setup` (includes dev-server remote URLs for setup webview in development).
- `src-tauri/icons/`: bundle icons used by Tauri.

## Current behavior

- Launcher shows a fixed **4×4 slot matrix** (16 cells): keys `1 2 3 4` / `q w e r` / `a s d f` / `z x c v`. A **breadcrumb** bar above the grid shows `root` or `root/<folder>` while inside one folder level. Slots without an item render as **muted** empty tiles (lower contrast).
- Rows use a **stagger**: row *n* (0-based) is shifted right by `n × (cell + gap) / 2` px so each line moves by half a slot (cell plus inter-cell gap) cumulatively.
- Only the **active folder level** is shown (`current` or root `items`). On blur (before hide), `current` is cleared so the next open starts at the top level.
- Main window (`main`): frameless, **transparent** webview, **no shadow**; Rust fits the window to the **work area** of the monitor under the mouse (`work_area` from `available_monitors` / primary / first), not OS fullscreen API. **`user-select: none`** on `main`; **pointerdown** outside filled **`<button>`** tiles clears folder state and **hides** the window. **Visual theme**: low-chroma **zinc** surfaces, **pink** accents — filled tiles use **pink** borders; **hover** only adjusts background + border / inset ring (no translation). Emoji icon size scales with tile (~60% height); titles **line-clamp-2** with px from tile size. Empty slots are **disabled-style** (lighter gray, thin border). Hides on focus loss after first focus as before.
- Launcher panel: total height still targets ~60% of **screen** (capped by inner height); a fixed **breadcrumb** strip reduces the vertical space used for the four tile rows. **Cell size** is `min(height-derived, width-derived)` so `5.5×cell + 4.5×gap + horizontal padding` fits `window.innerWidth`. Inner panel uses `contain: paint` and `isolation: isolate`. Root uses full-viewport height with `overflow-hidden`.
- Config is stored under OS config dir in a `rusto/config.json` file.
- `watch_folder` is scanned to build launcher items. Entries whose names start with `.` are ignored (dotfiles / dot-directories).
- File/folder names can force key assignment with `[key]name`, e.g. `[q]Terminal.lnk`.
- Top-level folders become submenus/pages when they contain launchable children; empty folders are skipped.
- Icons:
  - folder `_icon.png` is used for that folder;
  - sibling `Name.png` can be used as icon for item/folder named `Name`;
  - standalone PNG files are treated as icon assets and not launcher items.
- Launching:
  - extensions matching `config.custom_openers` run configured program/args;
  - placeholders supported in opener args: `{file}`, `{dir}`, `{name}`;
  - on **Linux**, if no custom opener matches, **`appimage` / `.AppImage`** paths use **direct detached spawn** (`Command::new(path)`), same idea as executing the file from a shell; add a custom opener row in Setup only if you need a wrapper;
  - other items use OS default opener via `open::that_detached`.
- Setup lives in a separate webview window (`setup`), opened from tray **Setup** or automatically when `watch_folder` is empty on first load. **Save** writes config and emits `config-changed` so the main window reloads config and rescans.
- Window/tray:
  - tray left-click shows/focuses main window (re-centered on cursor monitor);
  - tray menu: **Show**, **Setup**, **Reload** (notifies main to reload, then shows main), **Exit**;
  - if the system tray cannot be created (common under AppImage / minimal session / no status notifier), startup **continues** and a message is printed to stderr; use the main window or a desktop shortcut to show the app;
  - frontend handles configured back/hide hotkeys while the main launcher is focused; global hotkeys are not yet implemented.
- **Single-instance**: `tauri-plugin-single-instance` ensures that launching a second copy (e.g. via desktop hotkey) instead shows/focuses the existing main window.

## Commands

```bash
npm run check       # Svelte type/a11y check
npm run build       # static frontend build to build/
npm run tauri dev   # run app in development
npm run tauri build # build release app and platform bundles
cd src-tauri && cargo build --release # compile only the Rust release binary
```

## Development rules for agents

- Prefer minimal, focused changes.
- After moving/renaming files, update paths in this file and configs.
- After changing user-visible behavior, update `Current behavior`.
- After changing scripts/dependencies/tooling, update `Commands` and relevant notes.
- Run `npm run check` after frontend changes; run `npm run build` for build-impacting changes; run `cargo check` after Rust changes.
