

ahko_show(*)
{
	if(uiType=="1") {
		ahko_menu.Show()
	}
}

ahko_init(*)
{
	if(uiType=="1") {
		ahko_listview_init()
	}
}

ahko_listview_init()
{
	global
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
}

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
