# rusto

Cross-platform quick launcher for **Windows**, **Linux**, and **macOS**. Built with Rust + Tauri v2 + Svelte + Tailwind CSS (successor to the AHK `ahko` reference).

## Platform support

| Area | Windows | Linux (X11) | Linux (Wayland) | macOS |
|------|---------|-------------|-----------------|-------|
| Core launcher (grid, keyboard, scan folder) | Yes | Yes | Yes | Yes* |
| Setup window | Yes | Yes | Yes | Yes* |
| System tray | Yes | Yes† | Yes† | Yes* |
| Launcher screen (mouse / focus / fixed) | Yes | Yes | **No** ‡ | Yes* |
| Global wake shortcut (in-app) | Reserved | Not wired | Not wired | Reserved |
| AppImage direct launch | — | Yes | Yes | — |

\* macOS is a target of the stack (Tauri v2) but not regularly tested in this repo yet.  
† Tray creation failure is non-fatal; use a desktop shortcut if the tray is unavailable.  
‡ See [Linux Wayland](#linux-wayland) below.

The project is **architecturally cross-platform**: one Svelte frontend and one Rust backend (`src-tauri/src/lib.rs`) compile for all three OSes via Tauri. Platform differences are handled with runtime capability checks (e.g. `get_platform_capabilities`), `TAURI_ENV_PLATFORM` in the UI, and small `cfg!(target_os = …)` branches (e.g. AppImage spawn on Linux). No separate per-OS codebases are required.

What still varies by platform is mostly **desktop integration** (tray, global hotkeys, window placement), not the launcher logic itself.

## Linux Wayland

On **Linux Wayland** sessions (e.g. Ubuntu GNOME with `XDG_SESSION_TYPE=wayland`), the compositor does **not** allow applications to move themselves to a chosen monitor or pixel position. Tauri’s `set_position()` / `set_size()` calls succeed but are ignored ([tauri#14913](https://github.com/tauri-apps/tauri/issues/14913), [tao#566](https://github.com/tauri-apps/tao/issues/566)).

**Impact on rusto:**

- **Launcher screen** settings (follow mouse, follow focused window, fixed screen) are saved in config but **have no effect** on Wayland until upstream adds a supported API (e.g. fullscreen-on-monitor) or you use an **X11 session** (login screen → “Ubuntu on Xorg”).
- The launcher may always appear on the monitor where the compositor first placed the window (often the primary display).
- Setup shows a warning when Wayland is detected.

**Workarounds:**

1. Log in with an **X11** desktop session to use launcher screen settings.
2. Use the **tray** or a **desktop shortcut** to wake the app; placement will still follow Wayland rules above.
3. Watch [Tauri PR #14926](https://github.com/tauri-apps/tauri/pull/14926) for possible Wayland support via monitor-targeted fullscreen.

## Development

```bash
npm install
npm run check
npm run build
npm run tauri dev
```

On Windows, ensure the Rust toolchain managed by rustup is earlier in `PATH` than any Chocolatey/system Rust installation, for example `C:\Users\xiany\.cargo\bin` before `C:\ProgramData\chocolatey\bin`.

Linux build requires WebKit/GTK dev packages (see [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/)).

## Release build

Install dependencies first:

```bash
npm install
```

Build the release app and platform bundles:

```bash
npm run tauri build
```

Artifacts:

```text
src-tauri/target/release/rusto[.exe]
src-tauri/target/release/bundle/
```

Rust-only release binary:

```bash
cd src-tauri
cargo build --release
```

## Wake shortcut (show launcher)

Rusto keeps **Back** and **Hide** hotkeys inside the launcher only. **Wake** (opening or focusing the launcher when it is hidden) depends on the platform:

### Windows

1. **Setup → Show** — Stores the shortcut you want for waking the launcher in config (reserved for future in-app global registration). This field is visible only on Windows builds.
2. **Tray icon** — Left-click the tray icon to show or focus the main window.
3. **Shortcut key on a `.lnk`** — Right-click a desktop/start-menu shortcut → **Properties** → **Shortcut** → **Shortcut key** → pick a letter (Windows assigns Ctrl+Alt+letter). Target must be `rusto.exe`.
4. **Third-party tools** — e.g. PowerToys Keyboard Manager or AutoHotkey can map keys to launching or activating `rusto.exe`.

### Linux

The **Show** wake field is **hidden** in Setup because it is not wired to a global shortcut under Wayland/X11 here; use one of:

1. **Tray icon** — Same as Windows: click the tray icon to show the launcher when available.
2. **Desktop session shortcuts** — GNOME **Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts**: command your **installed** `rusto` binary or AppImage path (e.g. `/path/to/rusto`). KDE: **System Settings → Shortcuts** (or similar) with the same idea.
3. **`xdg-desktop` menu** — Add a `.desktop` file with `Exec=` pointing to rusto and assign an accelerator where your desktop supports it.
4. **Window manager / compositor tools** — e.g. sway/hyprland binds to `exec` the app binary.

Keep **Hide** / **Back** configured in Setup; they apply while the launcher webview has focus.

### macOS

Use the **tray icon** or assign a shortcut via **System Settings → Keyboard → Keyboard Shortcuts** (custom app shortcut). In-app global wake registration is not implemented yet.

## Launcher screen (Setup)

Choose where the fullscreen launcher appears when woken:

- **Follow mouse cursor** — monitor under the pointer
- **Follow focused window** — monitor containing the active window (via `active-win-pos-rs`; Wayland compositor support varies)
- **Fixed screen** — always a selected display

Effective on Windows, macOS, and **Linux X11**. **Not effective on Linux Wayland** (see above).
