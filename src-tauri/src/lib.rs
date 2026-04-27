use serde::{Deserialize, Serialize};
use std::{collections::HashSet, fs, path::{Path, PathBuf}, process::Command};
use tauri::{menu::{Menu, MenuItem}, tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent}, AppHandle, Manager};

const ITEM_KEYS: [&str; 16] = ["1", "2", "3", "q", "w", "e", "a", "s", "d", "4", "r", "f", "z", "x", "c", "v"];

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CustomOpener { pub extensions: Vec<String>, pub program: String, pub args: Vec<String> }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig { pub watch_folder: String, pub toggle_hotkey: String, pub back_hotkey: String, pub hide_hotkey: String, pub show_at: String, pub enable_in_fullscreen: bool, pub autostart: bool, pub custom_openers: Vec<CustomOpener> }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LauncherItem { pub name: String, pub key: String, pub path: String, pub is_dir: bool, pub icon: Option<String>, pub children: Vec<LauncherItem> }

impl Default for AppConfig { fn default() -> Self { Self { watch_folder: String::new(), toggle_hotkey: "Alt+Q".into(), back_hotkey: "`".into(), hide_hotkey: "Esc".into(), show_at: "mouse".into(), enable_in_fullscreen: false, autostart: false, custom_openers: vec![CustomOpener { extensions: vec!["py".into(), "pyw".into()], program: "python3".into(), args: vec!["{file}".into()] }] } } }

fn config_dir() -> Result<PathBuf, String> { dirs::config_dir().map(|p| p.join("rusto")).ok_or("Cannot locate config directory".into()) }
fn config_path() -> Result<PathBuf, String> { Ok(config_dir()?.join("config.json")) }
fn normalize_ext(s: &str) -> String { s.trim().trim_start_matches('.').to_ascii_lowercase() }
fn file_stem_name(path: &Path) -> String { path.file_stem().and_then(|s| s.to_str()).unwrap_or_default().to_string() }

fn parse_keyed_name(file_name: &str, available: &mut Vec<String>) -> (String, Option<String>) {
    if file_name.starts_with('[') && file_name.len() > 3 { if let Some(end) = file_name.find(']') { let key = file_name[1..end].to_ascii_lowercase(); if available.iter().any(|k| k == &key) { available.retain(|k| k != &key); return (file_name[end + 1..].to_string(), Some(key)); } } }
    (file_name.to_string(), None)
}
fn assign_key(existing: Option<String>, available: &mut Vec<String>) -> Option<String> { existing.or_else(|| if available.is_empty() { None } else { Some(available.remove(0)) }) }

fn scan_level(dir: &Path, inner: bool) -> Vec<LauncherItem> {
    let mut icon_map = std::collections::HashMap::new(); let mut raw = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) { for entry in entries.flatten() { let path = entry.path(); let name = entry.file_name().to_string_lossy().to_string(); if name.eq_ignore_ascii_case("_icon.png") { continue; } if path.extension().and_then(|e| e.to_str()).is_some_and(|e| e.eq_ignore_ascii_case("png")) { icon_map.insert(file_stem_name(&path), path.to_string_lossy().to_string()); continue; } raw.push((name, path)); } }
    raw.sort_by(|a, b| a.0.to_lowercase().cmp(&b.0.to_lowercase()));
    let mut keys: Vec<String> = ITEM_KEYS.iter().map(|s| s.to_string()).collect(); let mut result = Vec::new();
    for (name, path) in raw.into_iter().take(16) { let is_dir = path.is_dir(); let (display_file, keyed) = parse_keyed_name(&name, &mut keys); let display_path = Path::new(&display_file); let display_name = display_path.file_stem().and_then(|s| s.to_str()).unwrap_or(&display_file).to_string(); let mut children = if is_dir && !inner { scan_level(&path, true) } else { vec![] }; if is_dir && !inner && children.is_empty() { continue; } let icon = if is_dir { let folder_icon = path.join("_icon.png"); if folder_icon.exists() { Some(folder_icon.to_string_lossy().to_string()) } else { icon_map.get(&display_name).cloned() } } else { icon_map.get(&display_name).cloned() }; if let Some(key) = assign_key(keyed, &mut keys) { result.push(LauncherItem { name: display_name, key, path: path.to_string_lossy().to_string(), is_dir, icon, children: std::mem::take(&mut children) }); } }
    result
}

#[tauri::command] fn load_config() -> Result<AppConfig, String> { let path = config_path()?; if !path.exists() { return Ok(AppConfig::default()); } serde_json::from_str(&fs::read_to_string(path).map_err(|e| e.to_string())?).map_err(|e| e.to_string()) }
#[tauri::command] fn save_config(config: AppConfig) -> Result<(), String> { let dir = config_dir()?; fs::create_dir_all(&dir).map_err(|e| e.to_string())?; fs::write(config_path()?, serde_json::to_string_pretty(&config).map_err(|e| e.to_string())?).map_err(|e| e.to_string()) }
#[tauri::command] fn scan_launcher(config: AppConfig) -> Result<Vec<LauncherItem>, String> { let path = PathBuf::from(&config.watch_folder); if !path.is_dir() { return Ok(vec![]); } Ok(scan_level(&path, false)) }
#[tauri::command] fn launch_item(config: AppConfig, path: String) -> Result<(), String> { let p = PathBuf::from(&path); let ext = p.extension().and_then(|e| e.to_str()).map(normalize_ext).unwrap_or_default(); if let Some(opener) = config.custom_openers.iter().find(|o| o.extensions.iter().map(|e| normalize_ext(e)).collect::<HashSet<_>>().contains(&ext)) { let dir = p.parent().unwrap_or(Path::new("")); let file = p.to_string_lossy().to_string(); let name = p.file_name().and_then(|n| n.to_str()).unwrap_or_default().to_string(); let args: Vec<String> = opener.args.iter().map(|a| a.replace("{file}", &file).replace("{dir}", &dir.to_string_lossy()).replace("{name}", &name)).collect(); Command::new(&opener.program).args(args).current_dir(dir).spawn().map_err(|e| e.to_string())?; } else { open::that_detached(&p).map_err(|e| e.to_string())?; } Ok(()) }
#[tauri::command] fn hide_window(app: AppHandle) -> Result<(), String> { if let Some(w) = app.get_webview_window("main") { w.hide().map_err(|e| e.to_string())?; } Ok(()) }
fn show_main(app: &AppHandle) { if let Some(w) = app.get_webview_window("main") { let _ = w.show(); let _ = w.set_focus(); } }

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default().plugin(tauri_plugin_opener::init()).setup(|app| { let setup = MenuItem::with_id(app, "setup", "Setup", true, None::<&str>)?; let reload = MenuItem::with_id(app, "reload", "Reload", true, None::<&str>)?; let quit = MenuItem::with_id(app, "quit", "Exit", true, None::<&str>)?; let menu = Menu::with_items(app, &[&setup, &reload, &quit])?; TrayIconBuilder::new().menu(&menu).show_menu_on_left_click(false).on_tray_icon_event(|tray, event| { if let TrayIconEvent::Click { button: MouseButton::Left, button_state: MouseButtonState::Up, .. } = event { show_main(&tray.app_handle()); } }).on_menu_event(|app, event| match event.id().as_ref() { "setup" | "reload" => show_main(app), "quit" => app.exit(0), _ => {} }).build(app)?; Ok(()) }).invoke_handler(tauri::generate_handler![load_config, save_config, scan_launcher, launch_item, hide_window]).run(tauri::generate_context!()).expect("error while running tauri application");
}
