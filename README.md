# rusto

`rusto` is a cross-platform quick launcher for Windows and Ubuntu, rebuilt from the original AHK `ahko` reference with Rust + Tauri v2 + Svelte + Tailwind CSS.

## Development

```bash
npm install
npm run check
npm run build
npm run tauri dev
```

On Windows, ensure the Rust toolchain managed by rustup is earlier in `PATH` than any Chocolatey/system Rust installation, for example `C:\Users\xiany\.cargo\bin` before `C:\ProgramData\chocolatey\bin`.

## Release build

Install dependencies first:

```bash
npm install
```

Build the release app and platform bundles:

```bash
npm run tauri build
```

The release executable is generated at:

```text
src-tauri/target/release/rusto.exe
```

Bundled installers/packages are generated under:

```text
src-tauri/target/release/bundle/
```

To compile only the Rust release binary without generating installers:

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

