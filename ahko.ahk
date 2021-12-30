#SingleInstance Ignore
SetWorkingDir A_ScriptDir
Persistent

path:=IniRead("setting.ini", "dir", "path", "")
hotkeys:=IniRead("setting.ini", "hotkey", "key", "#q")
uiType:=IniRead("setting.ini", "ui", "type", "1")

#include ahko_setup_gui.ahk

customTrayMenu:={valid:true}
customTrayMenu.menu:=[]
customTrayMenu.menu.push({name:"Setup",func:ahko_setup_show})

setupWatchFolder(*)
{
	newpath:=RegExReplace(DirSelect(,0), "\\$")
	if(newpath!="") {
		IniWrite("path=" newpath,"setting.ini", "dir")
		Reload
	}
}

if(!DirExist(path)) {
	; MsgBox("ahko watch folder not set.`nPlease select which folder to watch.")
	; path:=RegExReplace(DirSelect(,0), "\\$")
	; if(path="") {
	; 	MsgBox("No valid folder selected`nahko is going to exit.",,"T3")
	; 	Exitapp
	; }
	; IniWrite("path=" path,"setting.ini", "dir")
	ahko_setup_show()
	Return
}

TrayTip "ahko start at " path, "ahko", 0x14
Hotkey hotkeys, ahko_show, "On"

ahko := []
Loop files path "\*", "FD"
{
	; MsgBox(A_LoopFileName " " A_LoopFileExt "`n" A_LoopFileAttrib)
	if(InStr(A_LoopFileAttrib,"D")){
		ahko.Push({name:"",attrib:A_LoopFileAttrib,path:A_LoopFileFullPath,sub:[]})
		item_count := 0
		Loop files A_LoopFileFullPath "\*", "FD"
		{
			if(InStr(A_LoopFileAttrib,"D")){
				local_name := "[D] " A_LoopFileName
			} else {
				local_name := A_LoopFileName
				if(local_name == "_icon.png") {
					ahko[-1].icon := A_LoopFileFullPath
					Continue
				}
			}
			item_count += 1
			ahko[-1].sub.Push({name:local_name,attrib:A_LoopFileAttrib,path:A_LoopFileFullPath})
			if(A_Index >= 16){
				Break
			}
		}
		ahko[-1].name := A_LoopFileName " [" item_count "]"
	} else {
		ahko.Push({name:A_LoopFileName,attrib:A_LoopFileAttrib,path:A_LoopFileFullPath})
	}
	if(A_Index >= 16){
		Break
	}
}


fileGetIcon(file)
{
	SplitPath(file, &filename,,&ext)
	if(ext="lnk"){
		FileGetShortcut(file, &target)
		file := target
		SplitPath(file, &filename,,&ext)
	}
	if(RegExMatch(ext,"i)^(ICO|CUR|ANI|EXE|DLL|CPL|SCR)$")){
		return file
	}
	Return ""
}

#Include ahko_ui.ahk
ahko_init()
