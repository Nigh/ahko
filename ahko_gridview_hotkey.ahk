

; hotkeyList:=[
; 	'1','2','3','4',
; 	'q','w','e','r',
; 	'a','s','d','f',
; 	'z','x','c','v'
; ]
hotkeyList:=[
	'1','2','3',
	'q','w','e',
	'a','s','d',
	'4','r','f',
	'z','x','c','v'
]
revkeyList:=map()
For k, v in hotkeyList
{
	revkeyList[v]:=k
}

gridview_goback(*)
{
	global
	ahko_show()
}
subgrid_choose(key)
{
	global ahko_grid_sub
	For k, v in ahko_grid_sub
	{
		if not v.isHide
		{
			
			if(v.btnCall[revkeyList[key]]!="") {
				v.btnCall[revkeyList[key]]()
			}
			; MsgBox(k "," key)
			Return
		}
	}
}
gridview_hotkey_init()
{
	HotIfWinActive("ahk_id " ahko_grid.Hwnd)
	hotkey("Escape", ahko_grid.uHide)
	For k, v in ahko_grid.btnCall
	{
		if(v!="") {
			hotkey(hotkeyList[k], v)
		}
	}
	HotIf
	HotIfWinActive("ahk_group subgridGroup")
	hotkey("Escape", gridview_goback)
	hotkey("``", gridview_goback)
	Loop 16
	{
		hotkey(hotkeyList[A_Index], subgrid_choose)
	}
	HotIf
}
; #HotIf WinActive("ahk_group subgridGroup")

; #HotIf
