

h2FontStyle:="s22 w600 c505050 q5"
textFontStyle:="s12 w400 cblack q5"
clientWidth:=320

ahko_setup := Gui("+ToolWindow +AlwaysOnTop -DPIScale +OwnDialogs","ahko setup")
ahko_setup.SetFont(, "Microsoft JhengHei")
ahko_setup.SetFont(, "Verdana")
; ahko_setup.SetFont(, "LilyUPC")
; ahko_setup.SetFont(, "Meiryo")
ahko_setup.SetFont(, "MV Boli")

ahko_setup.SetFont("s32 w700 cc07070")
ahko_setup.Add("Text", "x10 y10", "ahko setup")
ahko_setup.Add("Text", "x0 y+-50 +BackgroundTrans", "____________________")

ahko_setup.SetFont(h2FontStyle)
ahko_setup.Add("Text","x30 y+20 section", "UI type")
ahko_setup.SetFont(textFontStyle)
ahkoSetup_uiType:=ahko_setup.Add("DropDownList", "y+10 w" clientWidth, ["Listview","Gridview","Gridview(Gdip)"])
ahkoSetup_uiType.OnEvent("Change", uiType_update)
uiType_update(*) {
	if(ahkoSetup_uiType.Value>2) {
		MsgBox("This ui type is still under development","OK","Owner" ahko_setup.Hwnd)
		ahkoSetup_uiType.Value := 2
	}
}
ahko_setup.SetFont(h2FontStyle)
ahko_setup.Add("Text", "xs y+30", "Watch folder")
ahko_setup.SetFont(textFontStyle)
buttonWidth:=95
AhkoSetup_path:=ahko_setup.Add("Edit", "y+10 r1 w" clientWidth-buttonWidth-5, "")
pathSelectBtn := ahko_setup.Add("Button", "x+5 hp w" buttonWidth, "Select")
pathSelectBtn.OnEvent("Click", setup_path)
setup_path(*){
	global AhkoSetup_path,ahko_setup
	ahko_setup.Opt("+OwnDialogs")
	newpath:=RegExReplace(DirSelect(,0), "\\$")
	ahkoSetup_path.Value:=newpath
}

ahko_setup.SetFont(h2FontStyle)
ahko_setup.Add("Text", "xs y+30", "Hotkey")
ahko_setup.SetFont(textFontStyle)
ahkoSetup_hotkey:=ahko_setup.Add("Hotkey", "y+10 w" clientWidth-buttonWidth-5)
ahkoSetup_hotkey.OnEvent("Change", hotkeyText_update)
ahkoSetup_hotkeyWin:=ahko_setup.Add("CheckBox", "x+10 hp w" buttonWidth, "Win")
ahkoSetup_hotkeyWin.OnEvent("Click", hotkeyText_update)

ahko_setup.SetFont("s10")
ahko_setup.Add("Text", "xs y+5", "Hotkey is ")
ahkoSetup_hotkeyText:=ahko_setup.Add("Text", "x+0 hp cc07070 w260", "")

ahko_setup.SetFont(h2FontStyle)
ahko_setup.Add("Text", "xs y+30", "Other")
ahko_setup.SetFont(textFontStyle)
ahkoSetup_enable_fullscreen:=ahko_setup.Add("CheckBox", "y+10 hp", "Enable in fullscreen")
ahkoSetup_enable_fullscreen.OnEvent("Click", enable_fullscreen_update)

ahkoSetup_autoStart:=ahko_setup.Add("CheckBox", "y+5 hp", "Startup with Windows")
ahkoSetup_autoStart.OnEvent("Click", autoStartup_update)

ahko_setup.SetFont(textFontStyle)
saveBtn := ahko_setup.Add("Button", "xs y+50 h50 w" (clientWidth-40)//2, "Save")
saveBtn.OnEvent("Click", ahko_setup_save)
cancelBtn := ahko_setup.Add("Button", "x+40 hp w" (clientWidth-40)//2, "Cancel")
cancelBtn.OnEvent("Click", ahko_setup_cancel)

ahko_setup.Add("Link", "xs y+0 w" clientWidth " right", 'Visit <a href="https://github.com/Nigh/ahko">GitHub Page</a>')

hotkeyText_update(*) {
	global

	local hotkey_str:=""
	if(ahkoSetup_hotkeyWin.Value) {
		hotkey_str.="Win + "
	}
	if(InStr(ahkoSetup_hotkey.Value,"^")) {
		hotkey_str.="Ctrl + "
	}
	if(InStr(ahkoSetup_hotkey.Value,"!")) {
		hotkey_str.="Alt + "
	}
	if(InStr(ahkoSetup_hotkey.Value,"+")) {
		hotkey_str.="Shift + "
	}
	hotkey_str.=RegExReplace(ahkoSetup_hotkey.Value, "#|\^|\!|\+|\<|\>")
	ahkoSetup_hotkeyText.Value:=hotkey_str
}
ahko_setup_show(*) {
	global
	ahkoSetup_uiType.Value:=uiType
	ahkoSetup_path.Value:=path

	ahkoSetup_hotkey.Value:=RegExReplace(hotkeys, "#")
	ahkoSetup_hotkeyWin.Value:=RegExMatch(hotkeys, "#")
	hotkeyText_update()
	local autostart:=RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run","ahko","")
	ahkoSetup_enable_fullscreen.Value:=fullscreen_enable
	if(autostart!="") {
		ahkoSetup_autoStart.Value:=1
	} else {
		ahkoSetup_autoStart.Value:=0
	}
	ahko_setup.show("w" clientWidth+60)
}
ahko_setup_cancel(*) {
	global
	ahko_setup.Hide()
}

; TODO: 未改动设置时无需重启
ahko_setup_save(*) {
	global
	if(ahko_setup_check())
	{
		hotkeyStr:=""
		if(ahkoSetup_hotkeyWin.Value){
			hotkeyStr:="#"
		}
		hotkeyStr.=ahkoSetup_hotkey.Value
		IniWrite("path=" ahkoSetup_path.Value, "setting.ini", "dir")
		IniWrite("key=" hotkeyStr, "setting.ini", "hotkey")
		IniWrite("fullscreen=" fullscreen_enable, "setting.ini", "hotkey")
		IniWrite("type=" ahkoSetup_uiType.Value, "setting.ini", "ui")
		MsgBox("In order for the changes to take effect`nahko is is about to be restarted","OK","Owner" ahko_setup.Hwnd)
		Reload
	}
}

ahko_setup_check(*) {
	global
	; MsgBox(ahkoSetup_hotkey.Value,,"Owner" ahko_setup.Hwnd)
	if(ahkoSetup_uiType.Value<1 || ahkoSetup_uiType.Value>3) {
		MsgBox("Invalid UI type","Error","Owner" ahko_setup.Hwnd)
		Return False
	}
	if(!DirExist(ahkoSetup_path.Value)) {
		MsgBox("Invalid watch folder","Error","Owner" ahko_setup.Hwnd)
		Return False
	}
	if(RegExReplace(ahkoSetup_hotkey.Value, "#|\^|\!|\+|\<|\>")="") {
		MsgBox("Invalid hotkey","Error","Owner" ahko_setup.Hwnd)
		Return False
	}
	Return true
}

ahko_setup_autostart(b){
	global
;@Ahk2Exe-IgnoreBegin
	MsgBox("Only compiled script could be set auto start !","Error","Owner" ahko_setup.Hwnd)
	Return
;@Ahk2Exe-IgnoreEnd
	DirCreate(A_Temp "\ahko_temp")
	FileInstall(".\set_auto_run\startup.exe", A_Temp "\ahko_temp\startup.exe",1)
	if(b) {
		runwait(A_Temp "\ahko_temp\startup.exe --name=ahko --target=" A_ScriptFullPath)
	} else {
		runwait(A_Temp "\ahko_temp\startup.exe --name=ahko --remove")
	}
	try {
		FileDelete(A_Temp "\ahko_temp\startup.exe")
	}
}
autoStartup_update(*)
{
	global
	ahko_setup_autostart(ahkoSetup_autoStart.Value)
}
enable_fullscreen_update(*)
{
	global
	fullscreen_enable:=ahkoSetup_enable_fullscreen.Value
}
; ahko_setup_show()

