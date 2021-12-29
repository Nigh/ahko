
SetWorkingDir(A_ScriptDir)
#SingleInstance force
#include meta.ahk

;@Ahk2Exe-IgnoreBegin
_exit(ThisHotkey){
	ExitApp
}
_reload(ThisHotkey){
	Reload
}
Hotkey("F5", _exit)
Hotkey("F6", _reload)
;@Ahk2Exe-IgnoreEnd

outputVersion()

if A_IsCompiled
debug:=0
Else
debug:=1

; if you need admin privilege, enable it.
if(0)
{
	UAC()
}
#include update.ahk
setTray()
OnExit(trueExit)

; ===============================================================
; ===============================================================
; your code below

mygui:=Gui("-DPIScale -AlwaysOnTop -Owner +OwnDialogs")
mygui.SetFont("s32 Q5", "Verdana")
mygui.Add("Text","w640 Center","AHKv2-AutoUpdate-Template")
mygui.SetFont("s12 Q5", "Verdana")
mygui.Add("Text","w640 Center","v" . version)
mygui.Show()
Return

GuiClose:
ExitApp
trueExit(ExitReason, ExitCode){
	ExitApp
}

; ===============================================================
; ===============================================================

UAC()
{
	full_command_line := DllCall("GetCommandLine", "str")

	if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
		try
		{
			if A_IsCompiled
				Run '*RunAs "' A_ScriptFullPath '" /restart'
			else
				Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
		}
		ExitApp
	}
}
#include tray.ahk
