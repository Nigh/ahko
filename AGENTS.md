# AGENTS.md

> **Important:** After modifying any project content (code, config, structure, dependencies), you **MUST** update this file to reflect the changes. Keep this document perfectly synchronized with the actual project state at all times.

---

## Project Overview

**ahko** is a keyboard-driven quick launcher for Windows, built with **AutoHotkey v2.0**. It watches a user-configured folder and presents a grid overlay UI to launch files, folders, and shortcuts via keyboard shortcuts. Invoked by a configurable global hotkey (default `Alt+Q`).

- **Author:** Nigh (HelloWorks)
- **License:** MIT
- **Current Version:** `1.0.3` (defined in `meta.ahk`)
- **Repository:** https://github.com/Nigh/ahko

---

## Directory Structure

```
ahko/
├── app.ahk                      # Entry point - main application bootstrap
├── meta.ahk                     # App metadata (name, version, filenames, URLs, changelog)
├── ahko.ahk                     # Core logic: folder scanning, key binding, item initialization
├── ahko_ui.ahk                  # UI dispatcher (selects GDIp or Native mode)
├── ahko_gridview_ui.ahk         # GDIp-based grid view UI class (main UI)
├── ahko_setup_gui.ahk           # Setup/configuration GUI (hotkey, folder, UI type, monitor)
├── Gdip_All.ahk                 # GDI+ library for AHK v2 (3rd party, ~3030 lines)
├── isFullScreen.ahk             # Fullscreen window detection utility class
├── tray.ahk                     # System tray menu setup
├── update.ahk                   # Auto-update logic (checks GitHub releases)
├── updater.c                    # C source for updater binary (extracts zip, launches exe)
├── updater.h                    # C header for updater (filename defines)
├── distribution.ahk             # Build/distribution script (compile + package)
├── set_auto_run.ahk             # Windows startup registry helper
├── icon.ico                     # Application icon (ICO)
├── icon.png                     # Application icon (PNG)
├── LICENSE                      # MIT license
├── README.md                    # Project documentation
├── AGENTS.md                    # This file - agent instructions
├── .gitignore                   # Ignores: dist/, *.exe, *.ini, compile_prop.ahk, .vscode/
├── .gitmodules                  # Git submodule: ahk-compile-toolset
├── assets/                      # Screenshots for README
│   ├── setup.png
│   └── setupui.png
└── ahk-compile-toolset/         # Git submodule - compile toolchain
    ├── Ahk2Exe.exe              # AHK script-to-exe compiler
    ├── AutoHotkey64.exe         # AHK v2 runtime for compilation
    ├── mpress.exe               # Executable compressor
    ├── tcc/                     # Tiny C Compiler (for building updater.c)
    └── c_utils/                 # C utility files
```

---

## Architecture

### Execution Flow

```
app.ahk (entry point)
  ├── meta.ahk              (metadata: version, filenames, URLs)
  ├── update.ahk            (auto-update check against GitHub releases)
  │   └── Uses MSXML2.ServerXMLHTTP to fetch version.txt
  │   └── Downloads new zip, launches updater.c binary to extract
  ├── ahko.ahk              (core logic)
  │   ├── isFullScreen.ahk  (multi-monitor fullscreen detection)
  │   ├── ahko_setup_gui.ahk (settings GUI)
  │   └── ahko_ui.ahk       (UI dispatcher)
  │       └── ahko_gridview_ui.ahk (GDIp grid view class)
  │           └── Gdip_All.ahk (GDI+ library)
  └── tray.ahk              (system tray menu)
```

### Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| `app.ahk` | Entry point. Bootstraps app, includes all modules, sets up dev hotkeys (F5=exit, F6=reload) |
| `meta.ahk` | Single source of truth for app name, version, binary filename, download URL, changelog |
| `ahko.ahk` | Core logic. Reads `setting.ini`, scans watch folder (2 levels, 16 items max per level), builds item array |
| `ahko_ui.ahk` | Thin dispatcher: initializes grid view class with GDIp rendering |
| `ahko_gridview_ui.ahk` | Main UI. Keyboard-driven grid overlay with 16-button layout using GDIp rendering. Includes misfire detection |
| `ahko_setup_gui.ahk` | Settings GUI: borderless window with GDIp-rendered header, buttons, and section labels. Uses native controls for inputs. Watch folder, hotkey, monitor position, fullscreen toggle, auto-start. Timer-based hover detection via `SetTimer` + `GetCursorPos` polling (30ms) |
| `Gdip_All.ahk` | Third-party GDI+ wrapper library for AHK v2 |
| `isFullScreen.ahk` | Detects fullscreen windows by comparing client rect against monitor bounds |
| `tray.ahk` | System tray context menu: version, Setup, GitHub, Donate, Reload, Exit |
| `update.ahk` | Auto-update via GitHub releases API with mirror support |
| `updater.c` / `updater.h` | C program compiled via TCC; extracts downloaded zip and restarts app |
| `distribution.ahk` | Build script: compiles updater.c, compiles AHK to exe, creates zip in `dist/` |
| `set_auto_run.ahk` | Adds/removes app from Windows startup registry |

### Key Design Patterns

1. **INI-based configuration** - All settings in `setting.ini` (sections: `[dir]`, `[hotkey]`, `[settings]`, `[update]`)
2. **Two-level directory scanning** - Folders become grid categories, files become launchable items
3. **Keyboard-centric grid UI** - 16 keys (`1,2,3,q,w,e,a,s,d,4,r,f,z,x,c,v`) mapped to staggered grid; backtick goes up, Esc hides
4. **Custom icon convention** - `_icon.png` for folder icons, `<name>.png` for item icons, `[key]` filename prefix for key assignment
5. **Self-updating** - Checks GitHub releases, downloads zip, uses compiled C binary for file extraction
6. **Misfire detection** - Timer-based mouse click and InputHook keyboard monitoring; auto-hides ahko window on unrelated input
7. **GDIp setup GUI** - Borderless setup window with GDIp-rendered header (dark title bar, rounded close button), GDIp-drawn buttons (Save, Cancel, Select), and native controls for text inputs. Draggable via WM_NCLBUTTONDOWN on header area
8. **Git submodule for toolchain** - `ahk-compile-toolset` bundles compiler and runtime

---

## Build & Run

### Run (Development)

```bash
AutoHotkey64.exe app.ahk
```

- `F5` exits the app (dev mode only)
- `F6` reloads the app (dev mode only)
- Command-line args: `--out=version` writes version file, `--run=<script.ahk>` runs a sub-script

### Build / Distribution

```bash
AutoHotkey64.exe distribution.ahk
```

This script:
1. Generates `compile_prop.ahk` with compiler metadata
2. Compiles `updater.c` -> `updater.exe` via TCC
3. Compiles `app.ahk` -> `ahko.exe` via Ahk2Exe
4. Generates `version.txt`
5. Compresses `ahko.exe` -> `ahko.zip`
6. Moves output to `dist/`

### Lint / Test

No formal testing or linting framework is present. The project relies on manual testing.

---

## Coding Conventions

- **Language:** AutoHotkey v2.0 syntax (not v1)
- **File naming:** lowercase with underscores (e.g., `ahko_gridview_ui.ahk`)
- **Classes:** Use AHK v2 class syntax with `class` keyword
- **Config:** Runtime config via `setting.ini` (INI format)
- **Metadata:** Version and app info centralized in `meta.ahk`
- **Third-party code:** `Gdip_All.ahk` is a vendored third-party library; do not modify unless absolutely necessary
- **Git submodule:** `ahk-compile-toolset` is a submodule - do not commit changes to its contents directly

---

## Git Information

- **Main branch:** `ahk` (active development)
- **Other branches:** `main`, `rust` (Tauri rewrite), `web-gui`, `gdip-gui`, `gdip-setup-gui`, `null-callback-fix`
- **Tags:** `v0.0.1` through `v1.0.3`
- **Submodule:** `ahk-compile-toolset` from `https://github.com/Nigh/ahk-compile-toolset`

---

## Agent Rules

1. **Sync this file:** After modifying any project content (code, config, structure, dependencies, build process), you **MUST** update `AGENTS.md` to reflect the changes. This includes but is not limited to:
   - Adding/removing/renaming files or directories
   - Changing module responsibilities or architecture
   - Updating version numbers or metadata
   - Modifying build/run commands
   - Adding/removing dependencies or submodules
   - Changing coding conventions or patterns

2. **Preserve conventions:** Follow existing AHK v2 code style and project patterns when making changes.

3. **Do not modify vendored code:** Avoid changing `Gdip_All.ahk` unless the task explicitly requires it.

4. **Update meta.ahk:** If the version changes, update `meta.ahk` as the single source of truth.

5. **No secrets:** Never commit secrets, API keys, or credentials.
