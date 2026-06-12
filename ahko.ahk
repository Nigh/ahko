#SingleInstance Ignore
SetWorkingDir A_ScriptDir
Persistent

path := IniRead("setting.ini", "dir", "path", "")
hotkeys := IniRead("setting.ini", "hotkey", "key", "!q")
fullscreen_enable := IniRead("setting.ini", "hotkey", "fullscreen", "0")
; 0 = primary monitor
; 1~9 = specific monitor
; 10 = monitor the mouse at
; 11 = monitor the activate window at
showat_list := "0|1|2|3|4|5|6|7|8|9|10|11"
showat := IniRead("setting.ini", "settings", "showat", "10")
if not RegExMatch(showat, showat_list)
{
	showat := "10"
}

#include isFullScreen.ahk
#include setup/ahko_setup_gui.ahk

customTrayMenu := { valid: true }
customTrayMenu.menu := []
customTrayMenu.menu.push({ name: "Setup", func: ahko_setup_show })

setupWatchFolder(*)
{
	newpath := RegExReplace(DirSelect(, 0), "\\$")
	if (newpath != "") {
		IniWrite("path=" newpath, "setting.ini", "dir")
		Reload
	}
}

if (!DirExist(path)) {
	ahko_setup_show()
	Return
}

ahko_keys := ["1", "2", "3", "q", "w", "e", "a", "s", "d", "4", "r", "f", "z", "x", "c", "v"]
ahko := []
ahko_init(&ahko, path)
{
	local icon_map_outer := Map()
	local keys_valid_outer := ahko_keys.Clone()
	Loop files path "\*", "FD"
	{
		fileName_outer := A_LoopFileName
		if (RegExMatch(fileName_outer, "(.+)\.png$", &iconFileName_outer)) {
			icon_map_outer.set(iconFileName_outer[1], A_LoopFileFullPath)
			Continue
		}
		local key_outer := ""
		local regexp := ""
		For v in keys_valid_outer {
			regexp .= v
		}
		if (RegExMatch(fileName_outer, "^\[([" regexp "])\](.+)$", &key)) {
			key_outer := StrLower(key[1])
			fileName_outer := key[2]
			For k, v in keys_valid_outer {
				if (StrCompare(v, key_outer) == 0) {
					keys_valid_outer.RemoveAt(k)
					Break
				}
			}
		}
		ahko.Push({ name: filenameWithoutExt(fileName_outer), attrib: A_LoopFileAttrib, path: A_LoopFileFullPath, sub: [], icon: "", key: key_outer })
		if (InStr(A_LoopFileAttrib, "D")) {
			local icon_map := Map()
			local keys_valid_inner := ahko_keys.Clone()
			local target_count := 0
			Loop files A_LoopFileFullPath "\*", "FD"
			{
				fileName_inner := A_LoopFileName
				if (fileName_inner == "_icon.png") {
					ahko[-1].icon := A_LoopFileFullPath
					Continue
				}
				if (RegExMatch(fileName_inner, "(.+)\.png$", &iconFileName)) {
					icon_map.set(iconFileName[1], A_LoopFileFullPath)
					Continue
				}
				if (target_count >= 16) {
					Continue
				}
				local key_inner := ""
				local regexp := ""
				For v in keys_valid_inner {
					regexp .= v
				}
				if (RegExMatch(fileName_inner, "^\[([" regexp "])\](.+)$", &key)) {
					key_inner := StrLower(key[1])
					fileName_inner := key[2]
					For k, v in keys_valid_inner {
						if (StrCompare(v, key_inner) == 0) {
							keys_valid_inner.RemoveAt(k)
							Break
						}
					}
				}
				ahko[-1].sub.Push({ name: filenameWithoutExt(fileName_inner), attrib: A_LoopFileAttrib, path: A_LoopFileFullPath, icon: "", key: key_inner })
				target_count += 1
			}
			for k, v in ahko[-1].sub
			{
				if (icon_map.Has(v.name)) {
					v.icon := icon_map.Get(v.name)
				}
				if (v.key == "") {
					v.key := keys_valid_inner[1]
					keys_valid_inner.RemoveAt(1)
				}
			}
			if (target_count == 0) {
				ahko.Pop()
			}
		}
		if (A_Index >= 16) {
			Break
		}
	}
	for k, v in ahko
	{
		if (icon_map_outer.Has(v.name)) {
			v.icon := icon_map_outer.Get(v.name)
		}
		if (v.key == "") {
			v.key := keys_valid_outer[1]
			keys_valid_outer.RemoveAt(1)
		}
	}
}
ahko_init(&ahko, path)
filenameWithoutExt(name)
{
	SplitPath(name, , , , &outname)
	Return outname
}

isNotFullScreen(*)
{
	Return not isFullScreen()
}

#Include ahko_ui.ahk
isUacMode := A_IsAdmin
ahko_ui_init()

ahko_invoke(*) {
	global
	if (isUacMode && ahko.Length == 0) {
		ahko_setup_show()
	} else {
		ahko_show()
	}
}

; TODO: if hotkey invalid, then reset the hotkey to default
if (fullscreen_enable)
{
	Hotkey hotkeys, ahko_invoke, "On"
} else {
	Hotif isNotFullScreen
	Hotkey hotkeys, ahko_invoke, "On"
	Hotif
}

TrayTip "ahko start at " path, "ahko", 0x14

; ahko_show()
; ahko_setup_show()
