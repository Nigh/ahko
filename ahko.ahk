#SingleInstance Ignore
SetWorkingDir A_ScriptDir
Persistent


path:=IniRead("setting.ini", "dir", "path")
; if()
TrayTip "Start at " path, "ahko", 0x14

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
				local_name := "[D]" A_LoopFileName
			} else {
				local_name := A_LoopFileName
				if(local_name == "_icon.png") {
					ahko[-1].icon := A_LoopFileFullPath
					Continue
				}
			}
			item_count += 1
			ahko[-1].sub.Push({name:local_name,attrib:A_LoopFileAttrib,path:A_LoopFileFullPath})
		}
		ahko[-1].name := A_LoopFileName "[" item_count "]"
	} else {
		ahko.Push({name:A_LoopFileName,attrib:A_LoopFileAttrib,path:A_LoopFileFullPath})
	}
}


; icon support format: ICO, CUR, ANI, EXE, DLL, CPL, SCR
ahko_menu := Menu()
ahko_menu_sub:=[]
For , layer0 in ahko
{
	if(InStr(layer0.attrib, "D")){
		ahko_menu_sub.Push(Menu())
		For , layer1 in layer0.sub
		{
			ahko_menu_sub[-1].add(layer1.name, ahko_go)
			iconPath:=fileGetIcon(layer1.path)
			if(iconPath){
				Try{
					ahko_menu_sub[-1].setIcon(layer1.name, iconPath)
				}Catch as e{
					; MsgBox("Err:" e.Message "`norigin:" layer1.path "`nicon:" iconPath)
				}
			}
		}
		ahko_menu.add(layer0.name, ahko_menu_sub[-1])
		if(layer0.HasOwnProp("icon") && layer0.icon) {
			ahko_menu.setIcon(layer0.name, layer0.icon)
		}
	} else {
		ahko_menu_sub.Push("")
		ahko_menu.add(layer0.name, ahko_go)
	}
}
Return

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

#q::ahko_menu.Show()


ahko_go(ItemName, ItemPos, MyMenu)
{
	global ahko, ahko_menu, ahko_menu_sub

	if(MyMenu==ahko_menu) {
		For , item in ahko
		{
			if(item.name == ItemName) {
				SplitPath(item.path,,&atDir)
				Run(item.path, atDir)
				Return
			}
		}
	} else {
		For index, menus in ahko_menu_sub
		{
			if(MyMenu==menus) {
				For ,item in ahko[index].sub
				{
					if(item.name == ItemName) {
						SplitPath(item.path,,&atDir)
						Run(item.path, atDir)
						Return
					}
				}
			}
		}
	}
}
