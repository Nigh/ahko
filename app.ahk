
SetWorkingDir(A_ScriptDir)
#Warn Unreachable, Off
#SingleInstance force
#include meta.ahk

;@Ahk2Exe-SetCompanyName HelloWorks
;@Ahk2Exe-SetName %appName%
;@Ahk2Exe-SetDescription ahko
;@Ahk2Exe-SetVersion %version%
;@Ahk2Exe-SetMainIcon icon.ico
;@Ahk2Exe-ExeName %appName%

;@Ahk2Exe-IgnoreBegin
if A_Args.Length > 0
{
	for n, param in A_Args
	{
		RegExMatch(param, "--out=(\w+)", &outName)
		if(outName[1]=="version") {
			f := FileOpen(versionFilename,"w","UTF-8-RAW")
			f.Write(version)
			f.Close()
			ExitApp
		}
	}
}
_exit(ThisHotkey){
	ExitApp
}
_reload(ThisHotkey){
	Reload
}
Hotkey("F5", _exit)
Hotkey("F6", _reload)
;@Ahk2Exe-IgnoreEnd

; if you need admin privilege, enable it.
if(0)
{
	UAC()
}
#include update.ahk
OnExit(trueExit)

; ===============================================================
; ===============================================================
; your code below

#include ahko.ahk
setTray()
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
