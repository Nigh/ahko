#Requires AutoHotkey v2.0
#Warn Unreachable, Off
#Include ../lib/ahk-xaml/XAML_GUI.ahk
#Include ../lib/ahk-xaml/AXML.ahk
#Include ../lib/ahk-xaml/XAML_Components.ahk

global SetupAppState := ""
global setupApp := ""
global setupUi := ""
global setupReady := false

setup_build_showAtDDL() {
	local items := ["Primary monitor", "Follow mouse", "Follow active window"]
	for k, v in isFullScreen.monitors {
		items.Push("Monitor #" k)
	}
	return items
}

setup_init() {
	global SetupAppState, setupApp, setupUi, setupReady
	if (setupReady) {
		return
	}

	SetupAppState := AXML_State({
		Path: "",
		Hotkey: "",
		HotkeyWin: "False",
		HotkeyText: "",
		ShowAtIndex: 0,
		Fullscreen: "False",
		AutoStart: "False"
	})

	options := Map(
		"Sidebar", false,
		"BurgerMenu", false,
		"AppIcon", false,
		"MinMaxButtons", false,
		"Resize", false,
		"Width", 420,
		"Height", 530,
		"TitleBarHeight", 40,
		"CloseAction", ahko_setup_cancel
	)

	setupApp := XAML_GUI("ahko Setup", options)
	setupApp.tabs.Visibility("Collapsed")

	if (A_IsCompiled) {
		axmlTemp := A_Temp "\ahko_setup.axml"
		FileInstall("setup\setup.axml", axmlTemp, 1)
		axmlPath := axmlTemp
	} else {
		axmlPath := A_ScriptDir "\setup\setup.axml"
	}
	content := FileRead(axmlPath, "UTF-8")
	result := AXML.ParseString(content, setupApp.main, SetupAppState, "setup.axml")
	cmb := setupApp.X.Find("CmbShowAt")
	for item in setup_build_showAtDDL() {
		cmb.Add("ComboBoxItem").Content(item)
	}

	if (A_IsCompiled) {
		setupUi := setupApp.Load("ahko_bundled.dll")
	} else {
		setupUi := setupApp.Compile()
	}
	AXML.BindAll(setupUi, result, SetupAppState)

	txtHotkey := setupApp.X.Find("TxtHotkey")
	txtHotkey._Props["Name"] := txtHotkey._Props["x:Name"]
	setupApp.RegisterHotKeyChange(txtHotkey, setup_hotkey_changed)
	for ctrlName in ["TxtPath", "TxtHotkey", "ChkHotkeyWin", "CmbShowAt", "ChkFullscreen", "ChkAutoStart"] {
		setupUi.Track(ctrlName)
	}

	setupReady := true
}

setup_sync_from_ui() {
	global setupUi, SetupAppState
	if (!setupUi) {
		return
	}
	state := setupUi.Query("TxtPath", "TxtHotkey", "ChkHotkeyWin", "CmbShowAt", "ChkFullscreen", "ChkAutoStart")
	SetupAppState.Path := state.Has("TxtPath") ? state["TxtPath"] : SetupAppState.Path
	SetupAppState.Hotkey := state.Has("TxtHotkey") ? state["TxtHotkey"] : SetupAppState.Hotkey
	SetupAppState.HotkeyWin := state.Has("ChkHotkeyWin") ? state["ChkHotkeyWin"] : SetupAppState.HotkeyWin
	SetupAppState.ShowAtIndex := state.Has("CmbShowAt") ? state["CmbShowAt"] : SetupAppState.ShowAtIndex
	SetupAppState.Fullscreen := state.Has("ChkFullscreen") ? state["ChkFullscreen"] : SetupAppState.Fullscreen
	SetupAppState.AutoStart := state.Has("ChkAutoStart") ? state["ChkAutoStart"] : SetupAppState.AutoStart
	hotkeyText_update()
}

setup_hotkey_changed(val) {
	global SetupAppState
	SetupAppState.Hotkey := val
	hotkeyText_update()
}

setup_sync_state_from_config() {
	global SetupAppState, path, hotkeys, showat, fullscreen_enable
	SetupAppState.Path := path
	SetupAppState.Hotkey := RegExReplace(hotkeys, "#")
	SetupAppState.HotkeyWin := RegExMatch(hotkeys, "#") ? "True" : "False"
	SetupAppState.ShowAtIndex := ddl_from_showat(showat) - 1
	SetupAppState.Fullscreen := fullscreen_enable ? "True" : "False"
	local autostart := (RunWait('schtasks /query /tn "ahko"', , "Hide") == 0)
	SetupAppState.AutoStart := autostart ? "True" : "False"
	hotkeyText_update()
}

setup_push_state_to_ui() {
	global setupUi, SetupAppState
	if (!setupUi) {
		return
	}
	setupUi.Update("TxtPath", "Text", SetupAppState.Path)
	setupUi.Update("TxtHotkey", "Text", SetupAppState.Hotkey)
	setupUi.Update("ChkHotkeyWin", "IsChecked", SetupAppState.HotkeyWin)
	setupUi.Update("CmbShowAt", "SelectedIndex", String(SetupAppState.ShowAtIndex))
	setupUi.Update("ChkFullscreen", "IsChecked", SetupAppState.Fullscreen)
	setupUi.Update("ChkAutoStart", "IsChecked", SetupAppState.AutoStart)
	setupUi.Update("TxtHotkeyText", "Text", SetupAppState.HotkeyText)
}

setup_show_window(pos := "") {
	global setupUi, setupApp
	if (setupUi.wpfHwnd && WinExist("ahk_id " setupUi.wpfHwnd)) {
		if (pos != "") {
			RegExMatch(pos, "x(-?\d+)\s+y(-?\d+)", &m)
			if (m) {
				WinMove(Integer(m[1]), Integer(m[2]), , , "ahk_id " setupUi.wpfHwnd)
			}
		}
		WinShow("ahk_id " setupUi.wpfHwnd)
		try WinActivate("ahk_id " setupUi.wpfHwnd)
	} else {
		setupApp.Show()
		if (pos != "" && setupUi.wpfHwnd) {
			RegExMatch(pos, "x(-?\d+)\s+y(-?\d+)", &m)
			if (m) {
				WinMove(Integer(m[1]), Integer(m[2]), , , "ahk_id " setupUi.wpfHwnd)
			}
		}
	}
}

setup_path(*) {
	global SetupAppState
	newpath := RegExReplace(DirSelect(, 0), "\\$")
	if (newpath != "") {
		SetupAppState.Path := newpath
		setup_push_state_to_ui()
	}
}

hotkeyText_update(state?, ctrl?, event?) {
	global SetupAppState, setupUi
	if (IsSet(state) && IsObject(state) && state.Has("ChkHotkeyWin")) {
		SetupAppState.HotkeyWin := state["ChkHotkeyWin"]
	}
	if (IsSet(state) && IsObject(state) && state.Has("TxtHotkey")) {
		SetupAppState.Hotkey := state["TxtHotkey"]
	}
	local hotkey_str := ""
	local hotkeyVal := SetupAppState.Hotkey
	local winChecked := (SetupAppState.HotkeyWin == "True" || SetupAppState.HotkeyWin == true || SetupAppState.HotkeyWin == 1)
	if (winChecked) {
		hotkey_str .= "Win + "
	}
	if (InStr(hotkeyVal, "^")) {
		hotkey_str .= "Ctrl + "
	}
	if (InStr(hotkeyVal, "!")) {
		hotkey_str .= "Alt + "
	}
	if (InStr(hotkeyVal, "+")) {
		hotkey_str .= "Shift + "
	}
	hotkey_str .= RegExReplace(hotkeyVal, "#|\^|\!|\+|\<|\>")
	SetupAppState.HotkeyText := hotkey_str
	if (setupUi) {
		setupUi.Update("TxtHotkeyText", "Text", hotkey_str)
	}
}

showat_from_ddl(dd) {
	if (dd >= 4) {
		return dd - 3
	} else if (dd >= 1) {
		if (dd == 1) {
			return 0
		}
		if (dd == 2) {
			return 10
		}
		if (dd == 3) {
			return 11
		}
	}
	return 1
}

ddl_from_showat(sw) {
	if (sw == 0) {
		return 1
	}
	if (sw == 10) {
		return 2
	}
	if (sw == 11) {
		return 3
	}
	if (sw >= 1 && sw <= 9) {
		return sw + 3
	}
	return 1
}

showat_monitor(n) {
	global isFullScreen, setupUi
	WinGetPos(, , &w, &h, "ahk_id " setupUi.wpfHwnd)
	return "x" Round(isFullScreen.monitors[n].l + isFullScreen.monitors[n].r - w) // 2 " y" Round(isFullScreen.monitors[n].t + isFullScreen.monitors[n].b - h) // 2
}

showAt_update(state?, ctrl?, event?) {
	global showat, SetupAppState, setupUi
	if (setupUi) {
		local idxVal := setupUi.Query("CmbShowAt>SelectedIndex")
		if (idxVal != "")
			SetupAppState.ShowAtIndex := idxVal
	}
	local ddlValue := Integer(SetupAppState.ShowAtIndex) + 1
	if (ddlValue >= 4) {
		showat := showat_from_ddl(ddlValue)
		setup_show_window(showat_monitor(showat))
	} else {
		showat := showat_from_ddl(ddlValue)
	}
}

ahko_setup_show(*) {
	global
	if (IsSet(ahko_gridview) && !ahko_gridview.grid_gui.isHide) {
		ahko_gridview._hideAll()
	}
	try Hotkey hotkeys, "Off"
	setup_init()
	setup_sync_state_from_config()
	setup_push_state_to_ui()
	local pos := ""
	if (showat >= 1 && showat <= 9) {
		pos := showat_monitor(showat)
	}
	setup_show_window(pos)
}

ahko_setup_cancel(*) {
	global setupUi, hotkeys, fullscreen_enable
	if (setupUi && setupUi.wpfHwnd) {
		WinHide("ahk_id " setupUi.wpfHwnd)
	}
	if (fullscreen_enable) {
		Hotkey hotkeys, ahko_invoke, "On"
	} else {
		HotIf isNotFullScreen
		Hotkey hotkeys, ahko_invoke, "On"
		HotIf
	}
}

ahko_setup_save(*) {
	global SetupAppState, setupUi
	setup_sync_from_ui()
	if (!ahko_setup_check()) {
		return
	}
	local hotkeyStr := ""
	local winChecked := (SetupAppState.HotkeyWin == "True" || SetupAppState.HotkeyWin == true || SetupAppState.HotkeyWin == 1)
	if (winChecked) {
		hotkeyStr := "#"
	}
	hotkeyStr .= SetupAppState.Hotkey
	IniWrite("path=" SetupAppState.Path, "setting.ini", "dir")
	IniWrite("key=" hotkeyStr, "setting.ini", "hotkey")
	IniWrite("fullscreen=" fullscreen_enable, "setting.ini", "hotkey")
	IniWrite("showat=" showat, "setting.ini", "settings")
	local owner := setupUi && setupUi.wpfHwnd ? " Owner" setupUi.wpfHwnd : ""
	MsgBox("In order for the changes to take effect`nahko is about to be restarted", "OK", owner)
	Reload
}

ahko_setup_check(*) {
	global SetupAppState, setupUi
	if (!DirExist(SetupAppState.Path)) {
		local owner := setupUi && setupUi.wpfHwnd ? " Owner" setupUi.wpfHwnd : ""
		MsgBox("Invalid watch folder", "Error", owner)
		return false
	}
	if (RegExReplace(SetupAppState.Hotkey, "#|\^|\!|\+|\<|\>") = "") {
		local owner := setupUi && setupUi.wpfHwnd ? " Owner" setupUi.wpfHwnd : ""
		MsgBox("Invalid hotkey", "Error", owner)
		return false
	}
	return true
}

ahko_setup_autostart(b) {
	global setupUi
	;@Ahk2Exe-IgnoreBegin
	local owner := setupUi && setupUi.wpfHwnd ? " Owner" setupUi.wpfHwnd : ""
	MsgBox("Only compiled script could be set auto start !", "Error", owner)
	return
	;@Ahk2Exe-IgnoreEnd
	DirCreate(A_Temp "\ahko_temp")
	FileInstall(".\set_auto_run.ahk", A_Temp "\ahko_temp\set_auto_run.ahk", 1)
	if (b) {
		RunWait('"' A_ScriptFullPath '" /script /force "' A_Temp "\ahko_temp\set_auto_run.ahk" '"' " --name=ahko --target=" A_ScriptFullPath)
	} else {
		RunWait('"' A_ScriptFullPath '" /script /force "' A_Temp "\ahko_temp\set_auto_run.ahk" '"' " --name=ahko --remove")
	}
	try {
		FileDelete(A_Temp "\ahko_temp\startup.exe")
	}
}

autoStartup_update(state?, ctrl?, event?) {
	global SetupAppState
	if (IsObject(state) && state.Has("ChkAutoStart")) {
		SetupAppState.AutoStart := state["ChkAutoStart"]
	}
	local enabled := (SetupAppState.AutoStart == "True" || SetupAppState.AutoStart == true || SetupAppState.AutoStart == 1)
	ahko_setup_autostart(enabled)
}

enable_fullscreen_update(state?, ctrl?, event?) {
	global SetupAppState, fullscreen_enable
	if (IsObject(state) && state.Has("ChkFullscreen")) {
		SetupAppState.Fullscreen := state["ChkFullscreen"]
	}
	fullscreen_enable := (SetupAppState.Fullscreen == "True" || SetupAppState.Fullscreen == true || SetupAppState.Fullscreen == 1) ? 1 : 0
}
