use mouse_position::mouse_position::Mouse;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashSet,
    fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
};
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Emitter, Manager, PhysicalPosition, PhysicalSize, WebviewUrl, WebviewWindowBuilder,
};

const ITEM_KEYS: [&str; 16] = ["1", "2", "3", "q", "w", "e", "a", "s", "d", "4", "r", "f", "z", "x", "c", "v"];

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CustomOpener {
    pub extensions: Vec<String>,
    pub program: String,
    pub args: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub watch_folder: String,
    pub toggle_hotkey: String,
    pub back_hotkey: String,
    pub hide_hotkey: String,
    pub show_at: String,
    pub enable_in_fullscreen: bool,
    pub autostart: bool,
    pub custom_openers: Vec<CustomOpener>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LauncherItem {
    pub name: String,
    pub key: String,
    pub path: String,
    pub is_dir: bool,
    pub icon: Option<String>,
    pub children: Vec<LauncherItem>,
}

fn default_custom_openers() -> Vec<CustomOpener> {
    vec![CustomOpener {
        extensions: vec!["py".into(), "pyw".into()],
        program: "python3".into(),
        args: vec!["{file}".into()],
    }]
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            watch_folder: String::new(),
            toggle_hotkey: "Alt+Q".into(),
            back_hotkey: "`".into(),
            hide_hotkey: "Esc".into(),
            show_at: "mouse".into(),
            enable_in_fullscreen: false,
            autostart: false,
            custom_openers: default_custom_openers(),
        }
    }
}

fn config_dir() -> Result<PathBuf, String> {
    dirs::config_dir()
        .map(|p| p.join("rusto"))
        .ok_or_else(|| "Cannot locate config directory".into())
}

fn config_path() -> Result<PathBuf, String> {
    Ok(config_dir()?.join("config.json"))
}

fn normalize_ext(s: &str) -> String {
    s.trim().trim_start_matches('.').to_ascii_lowercase()
}

fn file_stem_name(path: &Path) -> String {
    path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or_default()
        .to_string()
}

fn parse_keyed_name(file_name: &str, available: &mut Vec<String>) -> (String, Option<String>) {
    if file_name.starts_with('[') && file_name.len() > 3 {
        if let Some(end) = file_name.find(']') {
            let key = file_name[1..end].to_ascii_lowercase();
            if available.iter().any(|k| k == &key) {
                available.retain(|k| k != &key);
                return (file_name[end + 1..].to_string(), Some(key));
            }
        }
    }
    (file_name.to_string(), None)
}

fn assign_key(existing: Option<String>, available: &mut Vec<String>) -> Option<String> {
    existing.or_else(|| {
        if available.is_empty() {
            None
        } else {
            Some(available.remove(0))
        }
    })
}

fn scan_level(dir: &Path, inner: bool) -> Vec<LauncherItem> {
    let mut icon_map = std::collections::HashMap::new();
    let mut raw = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            let name = entry.file_name().to_string_lossy().to_string();
            if name.starts_with('.') {
                continue;
            }
            if name.eq_ignore_ascii_case("_icon.png") {
                continue;
            }
            if path
                .extension()
                .and_then(|e| e.to_str())
                .is_some_and(|e| e.eq_ignore_ascii_case("png"))
            {
                icon_map.insert(file_stem_name(&path), path.to_string_lossy().to_string());
                continue;
            }
            raw.push((name, path));
        }
    }
    raw.sort_by(|a, b| a.0.to_lowercase().cmp(&b.0.to_lowercase()));
    let mut keys: Vec<String> = ITEM_KEYS.iter().map(|s| s.to_string()).collect();
    let mut result = Vec::new();
    for (name, path) in raw.into_iter().take(16) {
        let is_dir = path.is_dir();
        let (display_file, keyed) = parse_keyed_name(&name, &mut keys);
        let display_path = Path::new(&display_file);
        let display_name = display_path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or(&display_file)
            .to_string();
        let mut children = if is_dir && !inner {
            scan_level(&path, true)
        } else {
            vec![]
        };
        if is_dir && !inner && children.is_empty() {
            continue;
        }
        let icon = if is_dir {
            let folder_icon = path.join("_icon.png");
            if folder_icon.exists() {
                Some(folder_icon.to_string_lossy().to_string())
            } else {
                icon_map.get(&display_name).cloned()
            }
        } else {
            icon_map.get(&display_name).cloned()
        };
        if let Some(key) = assign_key(keyed, &mut keys) {
            result.push(LauncherItem {
                name: display_name,
                key,
                path: path.to_string_lossy().to_string(),
                is_dir,
                icon,
                children: std::mem::take(&mut children),
            });
        }
    }
    result
}

/// Resize and move `main` to the **work area** (taskbar/dock excluded) of the monitor that
/// contains the mouse cursor, falling back to primary then first monitor — same idea as
/// Kando’s full-screen transparent menu window.
fn fit_main_to_cursor_work_area(app: &AppHandle) {
    let Some(w) = app.get_webview_window("main") else {
        return;
    };
    let Ok(monitors) = w.available_monitors() else {
        return;
    };
    let primary = w.primary_monitor().ok().flatten();
    let mon = match Mouse::get_mouse_position() {
        Mouse::Position { x, y } => monitors.iter().find(|m| {
            let p = m.position();
            let s = m.size();
            x >= p.x
                && x < p.x + s.width as i32
                && y >= p.y
                && y < p.y + s.height as i32
        }),
        Mouse::Error => None,
    }
    .or_else(|| primary.as_ref())
    .or_else(|| monitors.first());

    if let Some(m) = mon {
        let wa = m.work_area();
        let _ = w.set_position(PhysicalPosition::new(wa.position.x, wa.position.y));
        let _ = w.set_size(PhysicalSize::new(wa.size.width, wa.size.height));
    }
}

fn show_main(app: &AppHandle) {
    fit_main_to_cursor_work_area(app);
    if let Some(w) = app.get_webview_window("main") {
        let _ = w.show();
        let _ = w.set_always_on_top(true);
        let _ = w.set_focus();
        // Request user attention (flashing taskbar) as a fallback for stubborn WMs
        let _ = w.request_user_attention(Some(tauri::UserAttentionType::Critical));
        // Notify frontend to grab focus explicitly
        let _ = app.emit_to("main", "show-request", ());
    }
}

fn setup_webview_url(app: &AppHandle) -> WebviewUrl {
    match app.config().build.dev_url.as_ref() {
        Some(dev) => WebviewUrl::External(dev.join("setup").unwrap_or_else(|_| dev.clone())),
        None => WebviewUrl::App("setup.html".into()),
    }
}

fn open_or_focus_setup(app: &AppHandle) -> Result<(), String> {
    if let Some(w) = app.get_webview_window("setup") {
        w.show().map_err(|e| e.to_string())?;
        w.set_focus().map_err(|e| e.to_string())?;
        return Ok(());
    }
    WebviewWindowBuilder::new(app, "setup", setup_webview_url(app))
        .title("rusto — Setup")
        .inner_size(440.0, 760.0)
        .min_inner_size(360.0, 480.0)
        .resizable(true)
        .build()
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
fn load_config() -> Result<AppConfig, String> {
    let path = config_path()?;
    if !path.exists() {
        return Ok(AppConfig::default());
    }
    serde_json::from_str(&fs::read_to_string(path).map_err(|e| e.to_string())?)
        .map_err(|e| e.to_string())
}

#[tauri::command]
fn save_config(app: AppHandle, config: AppConfig) -> Result<(), String> {
    let dir = config_dir()?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    fs::write(
        config_path()?,
        serde_json::to_string_pretty(&config).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())?;
    let _ = app.emit_to("main", "config-changed", ());
    Ok(())
}

#[tauri::command]
fn scan_launcher(config: AppConfig) -> Result<Vec<LauncherItem>, String> {
    let path = PathBuf::from(&config.watch_folder);
    if !path.is_dir() {
        return Ok(vec![]);
    }
    Ok(scan_level(&path, false))
}

fn spawn_appimage_detached(p: &Path) -> Result<(), String> {
    Command::new(p)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
fn launch_item(config: AppConfig, path: String) -> Result<(), String> {
    let p = PathBuf::from(&path);
    let ext = p
        .extension()
        .and_then(|e| e.to_str())
        .map(normalize_ext)
        .unwrap_or_default();
    if let Some(opener) = config.custom_openers.iter().find(|o| {
        o.extensions
            .iter()
            .map(|e| normalize_ext(e))
            .collect::<HashSet<_>>()
            .contains(&ext)
    }) {
        let dir = p.parent().unwrap_or(Path::new(""));
        let file = p.to_string_lossy().to_string();
        let name = p
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or_default()
            .to_string();
        let args: Vec<String> = opener
            .args
            .iter()
            .map(|a| {
                a.replace("{file}", &file)
                    .replace("{dir}", &dir.to_string_lossy())
                    .replace("{name}", &name)
            })
            .collect();
        Command::new(&opener.program)
            .args(args)
            .current_dir(dir)
            .spawn()
            .map_err(|e| e.to_string())?;
    } else if cfg!(target_os = "linux")
        && (ext == "appimage" || p.extension().is_some_and(|e| e.eq_ignore_ascii_case("AppImage")))
    {
        spawn_appimage_detached(&p)?;
    } else {
        open::that_detached(&p).map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
fn hide_window(app: AppHandle) -> Result<(), String> {
    if let Some(w) = app.get_webview_window("main") {
        w.hide().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
fn open_setup_window(app: AppHandle) -> Result<(), String> {
    open_or_focus_setup(&app)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            show_main(app);
        }))
        .setup(|app| {
            let show = MenuItem::with_id(app, "show", "Show", true, None::<&str>)?;
            let setup = MenuItem::with_id(app, "setup", "Setup", true, None::<&str>)?;
            let reload = MenuItem::with_id(app, "reload", "Reload", true, None::<&str>)?;
            let quit = MenuItem::with_id(app, "quit", "Exit", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &setup, &reload, &quit])?;
            if let Err(e) = TrayIconBuilder::new()
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        show_main(&tray.app_handle());
                    }
                })
                .on_menu_event(|app, event| match event.id().as_ref() {
                    "show" => show_main(app),
                    "setup" => {
                        let _ = open_or_focus_setup(app);
                    }
                    "reload" => {
                        let _ = app.emit_to("main", "reload-request", ());
                        show_main(app);
                    }
                    "quit" => app.exit(0),
                    _ => {}
                })
                .build(app)
            {
                eprintln!("rusto: system tray unavailable ({e}). The app will still run; use the main window or bind a desktop shortcut to show it.");
            }
            fit_main_to_cursor_work_area(&app.handle());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            load_config,
            save_config,
            scan_launcher,
            launch_item,
            hide_window,
            open_setup_window
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
