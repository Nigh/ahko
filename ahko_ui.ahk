

ahko_show(*)
{
	if(uiType=="1") {
		ahko_listview.Show()
	}
	if(uiType=="2") {
		ahko_grid.Show()
		if(!winwait("ahk_id " ahko_grid.hwnd,,3)){
			Return
		}
		WinActivate("ahk_id " ahko_grid.hwnd)
		SetTimer(gridWaitNotActive, 150)
	}
}
gridWaitNotActive()
{
	global ahko_grid
	if(!WinActive("ahk_id " ahko_grid.hwnd)) {
		Try {
			ahko_grid.Hide()
		}
		SetTimer(gridWaitNotActive, 0)
	}
}

ahko_ui_init(*)
{
	if(uiType=="1") {
		ahko_listview_init(ahko)
	}
	if(uiType=="2") {
		ahko_gridview_init(ahko)
	}
}

; icon support format: ICO, CUR, ANI, EXE, DLL, CPL, SCR
#Include ahko_listview_ui.ahk
#Include ahko_gridview_ui.ahk
