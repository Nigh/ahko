ahko_show(*)
{
	ahko_gridview.Show()
	if (!winwait("ahk_id " ahko_gridview.grid_gui.hwnd, , 3)) {
		Return
	}
}

ahko_ui_init(*)
{
	global
	ahko_gridview := ahko_gridview_class()
	ahko_gridview.showat := showat
}

; icon support format: ICO, CUR, ANI, EXE, DLL, CPL, SCR
#Include ahko_gridview_ui.ahk
