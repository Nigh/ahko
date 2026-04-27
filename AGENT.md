# AGENT.md — rusto coding-agent context

This file is the compact project map for coding agents. **Any agent that changes code, config, dependencies, commands, behavior, or directory structure must update this file in the same change.** Keep it concise and accurate.

## Project

- Name: `rusto`
- Purpose: cross-platform quick launcher for Windows and Ubuntu, rebuilt from the AHK `ahko` reference in `https://github.com/Nigh/ahko`.
- Stack: Rust + Tauri v2 backend, Svelte 5 + SvelteKit + TypeScript frontend, Tailwind CSS 4 via Vite.
- Root is now the app root.

## Important paths

- `package.json`: npm scripts/deps. App package name is `rusto`.
- `src/routes/+page.svelte`: main launcher UI, setup panel, keyboard handling, Tauri command calls.
- `src/routes/+layout.svelte`, `src/app.css`: global layout/styles.
- `src-tauri/src/lib.rs`: Rust app logic and Tauri commands.
- `src-tauri/tauri.conf.json`: Tauri v2 config. `productName = rusto`, identifier `com.xianii.rusto`, frontend dist is `../build`.
- `src-tauri/capabilities/default.json`: Tauri command permissions.
- `src-tauri/icons/`: bundle icons used by Tauri.

## Current behavior

- Launcher shows a 16-slot key grid using keys: `1 2 3 q w e a s d 4 r f z x c v`.
- Config is stored under OS config dir in a `rusto/config.json` file.
- `watch_folder` is scanned to build launcher items.
- File/folder names can force key assignment with `[key]name`, e.g. `[q]Terminal.lnk`.
- Top-level folders become submenus/pages when they contain launchable children; empty folders are skipped.
- Icons:
  - folder `_icon.png` is used for that folder;
  - sibling `Name.png` can be used as icon for item/folder named `Name`;
  - standalone PNG files are treated as icon assets and not launcher items.
- Launching:
  - extensions matching `config.custom_openers` run configured program/args;
  - placeholders supported in opener args: `{file}`, `{dir}`, `{name}`;
  - other items use OS default opener via `open::that_detached`.
- Window/tray:
  - Tauri window is fixed size, always-on-top, initially visible;
  - tray left-click shows/focuses main window;
  - tray menu has `Setup`, `Reload`, `Exit`;
  - frontend handles configured show/back/hide hotkeys while focused; global hotkeys are not yet implemented.

## Commands

```bash
npm run check       # Svelte type/a11y check
npm run build       # static frontend build to build/
npm run tauri dev   # run app in development
```

## Development rules for agents

- Prefer minimal, focused changes.
- After moving/renaming files, update paths in this file and configs.
- After changing user-visible behavior, update `Current behavior`.
- After changing scripts/dependencies/tooling, update `Commands` and relevant notes.
- Run `npm run check` after frontend changes; run `npm run build` for build-impacting changes; run `cargo check` after Rust changes.
