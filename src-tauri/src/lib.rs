use mouse_position::mouse_position::Mouse;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashSet,
    fs,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    sync::Mutex,
    time::Duration,
};
use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Emitter, Manager, Monitor, PhysicalPosition, PhysicalSize, WebviewUrl,
    WebviewWindow, WebviewWindowBuilder,
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
    #[serde(default)]
    pub show_monitor_id: String,
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

#[derive(Debug, Clone, Serialize)]
pub struct PlatformCapabilities {
    pub session_type: String,
    pub desktop: String,
    pub launcher_screen_supported: bool,
    pub launcher_screen_note: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonitorInfo {
    pub id: String,
    pub name: String,
    pub is_primary: bool,
    pub width: u32,
    pub height: u32,
    pub x: i32,
    pub y: i32,
}

struct MonitorWatchState {
    fingerprint: Mutex<Vec<String>>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            watch_folder: String::new(),
            toggle_hotkey: "Alt+Q".into(),
            back_hotkey: "`".into(),
            hide_hotkey: "Esc".into(),
            show_at: "mouse".into(),
            show_monitor_id: String::new(),
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

/// Resize and move `main` to the **work area** of the monitor chosen by config
/// (`mouse` | `focus` | `fixed`), falling back to primary then first monitor.
fn monitor_id(m: &Monitor) -> String {
    let p = m.position();
    let s = m.size();
    format!("{}x{}@{},{}", s.width, s.height, p.x, p.y)
}

fn monitor_label(m: &Monitor) -> String {
    if let Some(name) = m.name().filter(|n| !n.is_empty()) {
        name.clone()
    } else {
        let p = m.position();
        let s = m.size();
        format!("{}×{} @ {},{}", s.width, s.height, p.x, p.y)
    }
}

fn monitors_same(a: &Monitor, b: &Monitor) -> bool {
    monitor_id(a) == monitor_id(b)
}

fn monitor_at_point(monitors: &[Monitor], x: i32, y: i32) -> Option<Monitor> {
    monitors.iter().find(|m| {
        let p = m.position();
        let s = m.size();
        x >= p.x
            && x < p.x + s.width as i32
            && y >= p.y
            && y < p.y + s.height as i32
    }).cloned()
}

fn find_monitor_by_id(monitors: &[Monitor], id: &str) -> Option<Monitor> {
    if id.is_empty() {
        return None;
    }
    if let Some(m) = monitors.iter().find(|m| monitor_id(m) == id).cloned() {
        return Some(m);
    }
    monitors
        .iter()
        .find(|m| m.name().is_some_and(|n| n == id))
        .cloned()
}

fn desktop_cursor_point(w: &WebviewWindow) -> Option<(i32, i32)> {
    if let Ok(pos) = w.cursor_position() {
        return Some((pos.x.round() as i32, pos.y.round() as i32));
    }
    match Mouse::get_mouse_position() {
        Mouse::Position { x, y } => Some((x, y)),
        Mouse::Error => None,
    }
}

fn monitor_for_point(w: &WebviewWindow, monitors: &[Monitor], x: i32, y: i32) -> Option<Monitor> {
    w.monitor_from_point(x as f64, y as f64)
        .ok()
        .flatten()
        .or_else(|| monitor_at_point(monitors, x, y))
}

fn focused_window_center() -> Option<(i32, i32)> {
    active_win_pos_rs::get_active_window().ok().map(|w| {
        (
            (w.position.x + w.position.width / 2.0) as i32,
            (w.position.y + w.position.height / 2.0) as i32,
        )
    })
}

fn collect_monitor_infos(w: &WebviewWindow) -> Result<Vec<MonitorInfo>, String> {
    let monitors = w.available_monitors().map_err(|e| e.to_string())?;
    let primary = w.primary_monitor().map_err(|e| e.to_string())?;
    Ok(monitors
        .into_iter()
        .map(|m| {
            let p = m.position();
            let s = m.size();
            MonitorInfo {
                id: monitor_id(&m),
                name: monitor_label(&m),
                is_primary: primary.as_ref().is_some_and(|pm| monitors_same(pm, &m)),
                width: s.width,
                height: s.height,
                x: p.x,
                y: p.y,
            }
        })
        .collect())
}

fn monitor_fingerprints(w: &WebviewWindow) -> Result<Vec<String>, String> {
    Ok(w.available_monitors()
        .map_err(|e| e.to_string())?
        .iter()
        .map(monitor_id)
        .collect())
}

fn pick_target_monitor(w: &WebviewWindow, config: &AppConfig) -> Option<Monitor> {
    let monitors = w.available_monitors().ok()?;
    if monitors.is_empty() {
        return None;
    }
    let primary = w.primary_monitor().ok().flatten();
    let fallback = || primary.clone().or_else(|| monitors.first().cloned());

    match config.show_at.as_str() {
        "fixed" => find_monitor_by_id(&monitors, &config.show_monitor_id).or_else(fallback),
        "focus" => focused_window_center()
            .and_then(|(x, y)| monitor_for_point(w, &monitors, x, y))
            .or_else(fallback),
        _ => desktop_cursor_point(w)
            .and_then(|(x, y)| monitor_for_point(w, &monitors, x, y))
            .or_else(fallback),
    }
}

fn apply_monitor_work_area(w: &WebviewWindow, mon: &Monitor) {
    let wa = mon.work_area();
    let _ = w.set_position(PhysicalPosition::new(wa.position.x, wa.position.y));
    let _ = w.set_size(PhysicalSize::new(wa.size.width, wa.size.height));
}

fn fit_main_to_work_area(app: &AppHandle, config: &AppConfig) {
    let Some(w) = app.get_webview_window("main") else {
        return;
    };
    if let Some(m) = pick_target_monitor(&w, config) {
        apply_monitor_work_area(&w, &m);
    }
}

fn emit_monitors_if_changed(app: &AppHandle) {
    let Some(w) = app.get_webview_window("main") else {
        return;
    };
    let Ok(fps) = monitor_fingerprints(&w) else {
        return;
    };
    let state = app.state::<MonitorWatchState>();
    let mut last = state.fingerprint.lock().expect("monitor watch lock");
    if *last == fps {
        return;
    }
    *last = fps;
    drop(last);
    if let Ok(infos) = collect_monitor_infos(&w) {
        let _ = app.emit("monitors-changed", infos);
    }
}

fn publish_monitors(app: &AppHandle) {
    let Some(w) = app.get_webview_window("main") else {
        return;
    };
    if let Ok(fps) = monitor_fingerprints(&w) {
        *app
            .state::<MonitorWatchState>()
            .fingerprint
            .lock()
            .expect("monitor watch lock") = fps;
    }
    if let Ok(infos) = collect_monitor_infos(&w) {
        let _ = app.emit("monitors-changed", infos);
    }
}

fn start_monitor_watch(app: AppHandle) {
    std::thread::spawn(move || loop {
        std::thread::sleep(Duration::from_secs(2));
        let handle = app.clone();
        let _ = handle.run_on_main_thread({
            let handle = handle.clone();
            move || emit_monitors_if_changed(&handle)
        });
    });
}

fn show_main(app: &AppHandle) {
    let config = load_config().unwrap_or_default();
    if let Some(w) = app.get_webview_window("main") {
        let _ = w.show();
        fit_main_to_work_area(app, &config);
        let _ = w.set_always_on_top(true);
        let _ = w.set_focus();
        let _ = w.request_user_attention(Some(tauri::UserAttentionType::Critical));
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
        .inner_size(440.0, 880.0)
        .min_inner_size(360.0, 600.0)
        .decorations(false)
        .transparent(true)
        .shadow(true)
        .resizable(true)
        .build()
        .map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
fn get_platform_capabilities() -> PlatformCapabilities {
    let session_type = std::env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| "unknown".into());
    let desktop = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_else(|_| "unknown".into());
    let wayland = session_type.eq_ignore_ascii_case("wayland");
    let launcher_screen_supported = !(cfg!(target_os = "linux") && wayland);
    let launcher_screen_note = if launcher_screen_supported {
        String::new()
    } else {
        "Linux Wayland (e.g. Ubuntu GNOME) does not allow apps to choose their screen. \
         Launcher screen settings are saved but have no effect until you log into an X11 session \
         or Tauri adds Wayland support."
            .into()
    };
    PlatformCapabilities {
        session_type,
        desktop,
        launcher_screen_supported,
        launcher_screen_note,
    }
}

#[tauri::command]
fn list_monitors(app: AppHandle) -> Result<Vec<MonitorInfo>, String> {
    let w = app
        .get_webview_window("main")
        .ok_or_else(|| "Main window not found".to_string())?;
    collect_monitor_infos(&w)
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

fn validate_custom_openers(openers: &[CustomOpener]) -> Result<(), String> {
    for (i, opener) in openers.iter().enumerate() {
        let label = format!("Custom opener #{}", i + 1);
        if opener.program.trim().is_empty() {
            return Err(format!("{label}: program field is empty"));
        }
        if opener.program.contains(char::is_whitespace) {
            return Err(format!(
                "{label}: program \"{}\" contains whitespace — put arguments in the args field instead",
                opener.program
            ));
        }
        if opener.extensions.is_empty() {
            return Err(format!("{label}: no extensions specified"));
        }
        for ext in &opener.extensions {
            if ext.trim().is_empty() {
                return Err(format!("{label}: extension list contains an empty entry"));
            }
            if ext.contains('.') {
                return Err(format!(
                    "{label}: extension \"{ext}\" should not contain a dot — write \"{}\" instead",
                    ext.trim_start_matches('.')
                ));
            }
        }
    }
    Ok(())
}

fn validate_show_at(config: &AppConfig) -> Result<(), String> {
    match config.show_at.as_str() {
        "mouse" | "focus" | "fixed" => {}
        other => return Err(format!("Invalid launcher screen mode: {other}")),
    }
    if config.show_at == "fixed" && config.show_monitor_id.trim().is_empty() {
        return Err("Select a screen when launcher position is fixed".into());
    }
    Ok(())
}

#[tauri::command]
fn save_config(app: AppHandle, config: AppConfig) -> Result<(), String> {
    validate_custom_openers(&config.custom_openers)?;
    validate_show_at(&config)?;
    let dir = config_dir()?;
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    fs::write(
        config_path()?,
        serde_json::to_string_pretty(&config).map_err(|e| e.to_string())?,
    )
    .map_err(|e| e.to_string())?;
    fit_main_to_work_area(&app, &config);
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
    if cfg!(target_os = "linux")
        && (ext == "appimage" || p.extension().is_some_and(|e| e.eq_ignore_ascii_case("AppImage")))
    {
        spawn_appimage_detached(&p)?;
    } else if let Some(opener) = config.custom_openers.iter().find(|o| {
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
        .manage(MonitorWatchState {
            fingerprint: Mutex::new(Vec::new()),
        })
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
            let config = load_config().unwrap_or_default();
            fit_main_to_work_area(&app.handle(), &config);
            publish_monitors(&app.handle());
            start_monitor_watch(app.handle().clone());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            load_config,
            save_config,
            scan_launcher,
            launch_item,
            hide_window,
            open_setup_window,
            list_monitors,
            get_platform_capabilities
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
