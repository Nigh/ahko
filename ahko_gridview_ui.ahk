

#Include ahko_gridview_hotkey.ahk

gridOpt:="+AlwaysOnTop -DPIScale +Owner"
ahko_grid := Gui(gridOpt)
gui_user_bind(ahko_grid)
ahko_gridview_init(ahko)
{
	global ahko_grid, gridOpt, ahko_grid_sub, subgridGroup
	local position:=Array(
		{x:0,y:0},{x:1,y:0},{x:2,y:0},
		{x:0.5,y:1},{x:1.5,y:1},{x:2.5,y:1},
		{x:1,y:2},{x:2,y:2},{x:3,y:2},
		{x:3,y:0},{x:3.5,y:1},{x:4,y:2},
		{x:1.5,y:3},{x:2.5,y:3},{x:3.5,y:3},{x:4.5,y:3})
	local buttonSize:=200
	local outerIndex:=1
	local gmargin:=10
	local titleHeight:=40
	ahko_grid.size:={w:5.5*(buttonSize+gmargin), h:4*(buttonSize+gmargin)+titleHeight}

	gridview_presetup(ahko_grid)
	ahko_grid.add("Button", "w" buttonSize " h" titleHeight " x0 y1 left", " ahko")

	; ahko_grid.MarginX:=10, ahko_grid.MarginY:=10
	ahko_grid_sub:=[]
	For , layer0 in ahko
	{
		if(InStr(layer0.attrib, "D")) {
			ahko_grid_sub.Push(Gui(gridOpt))
			gui_user_bind(ahko_grid_sub[-1])
			GroupAdd("subgridGroup", "ahk_id " ahko_grid_sub[-1].Hwnd)
			gridview_presetup(ahko_grid_sub[-1])
			btn:=ahko_grid_sub[-1].add("Button", "w" buttonSize " h" titleHeight " x0 y1 left", " " layer0.name)
			btn.OnEvent("Click", ahko_show)
			local subIndex:=1
			For , layer1 in layer0.sub
			{
				btn:=ahko_grid_sub[-1].add("Button", "w" buttonSize " h" buttonSize " x" position[subIndex].x*(buttonSize+gmargin) " y" position[subIndex].y*(buttonSize+gmargin)+titleHeight+gmargin, layer1.name "`n<&" StrUpper(hotkeyList[subIndex]) ">")
				ahko_grid_sub[-1].btnCall.Push(gridview_run_maker(layer1.path, ahko_grid_sub[-1]))
				btn.OnEvent("Click", ahko_grid_sub[-1].btnCall[-1])
				iconPath:=layer1.icon Or fileGethIcon(layer1.path)
				if(iconPath){
					Try{
						GuiButtonIcon(btn.hwnd, iconPath,, "a2 s100 t16")
					}
				}
				subIndex+=1
			}
			gridview_postsetup(ahko_grid_sub[-1])

			local folder_name:=layer0.name "-[" subIndex-1 "]`n<&" StrUpper(hotkeyList[outerIndex]) ">"
			btn:=ahko_grid.add("Button", "w" buttonSize " h" buttonSize " x" position[outerIndex].x*(buttonSize+gmargin) " y" position[outerIndex].y*(buttonSize+gmargin)+titleHeight+gmargin, folder_name)
			if(subIndex>1) {
				ahko_grid.btnCall.Push(gridview_show_maker(ahko_grid_sub[-1]))
				btn.OnEvent("Click", ahko_grid.btnCall[-1])
			} else {
				ahko_grid.btnCall.Push("")
				btn.Opt("Disabled")
			}
			iconPath:=layer0.icon Or fileGethIcon(layer0.path)
			if(iconPath){
				Try{
					GuiButtonIcon(btn.hwnd, iconPath,, "a2 s100 t16")
				}
			}
			outerIndex+=1
		} else {
			ahko_grid_sub.Push("")
			btn:=ahko_grid.add("Button", "w" buttonSize " h" buttonSize " x" position[outerIndex].x*(buttonSize+gmargin) " y" position[outerIndex].y*(buttonSize+gmargin), layer0.name)
			btn.OnEvent("Click", gridview_run_maker(layer0.path))
			outerIndex+=1
		}
	}
	gridview_postsetup(ahko_grid)
	gridview_hotkey_init()
}
gui_user_bind(g)
{
	uHide(*) {
		g.isHide:=True
		g.Hide()
	}
	uShow(*) {
		g.isHide:=False
		g.Show(grid_showat())
	}
	g.btnCall:=[]
	g.isHide:=True
	g.uShow := uShow
	g.uHide := uHide
}
gridview_run_maker(file, grid:="")
{
	runner(*) {
		grid!="" ? grid.uHide() : ()=>{}
		SplitPath(file,,&atDir)
		Try{
			Run(file, atDir)
		}
	}
	return runner
}
gridview_show_maker(grid)
{
	gridAutoHide() {
		if(!WinActive("ahk_id " grid.Hwnd)) {
			Try {
				grid.uHide()
			}
			settimer(gridAutoHide, 0)
		}
	}
	shower(*) {
		global ahko_grid
		ahko_grid.uHide()
		grid.uShow()
		settimer(gridAutoHide, 150)
	}
	return shower
}
gridview_presetup(grid)
{
	grid.SetFont(, "Microsoft JhengHei")
	grid.SetFont(, "Verdana")
	grid.SetFont(, "LilyUPC")
	grid.SetFont("s14 w700 cc07070")
}
gridview_postsetup(grid)
{
	grid.BackColor := "FF00FF"
	WinSetTransColor "FF00FF 0xE0", grid.Hwnd
	grid.Opt("-Caption")
	grid.Show("Hide")
}

grid_showat()
{
	global showat,ahko_grid,isFullScreen
	; MsgBox(showat)
	CoordMode("Mouse","Screen")
	if(showat=="0"){
		Return ""
	}
	if(showat>=1 and showat<=9){
		if(isFullScreen.monitors.Length >= showat){
			Return showat_monitor(showat)
		}else{
			Return ""
		}
	}
	if(showat=="10"){
		MouseGetPos(&mx,&my)
		For k, v in isFullScreen.monitors
		{
			; MsgBox("m" k ":mx" mx ",my" my "`nl" v.l "r" v.r "t" v.t "b" v.b)
			if(mx>=v.l && mx<=v.r && my>=v.t && my<=v.b){
				Return showat_monitor(k)
			}
		}
	}
	if(showat=="11"){
		WinGetPos(&wx, &wy, &ww, &wh, "A")
		wx+=ww//3
		wy+=wh//3
		For k, v in isFullScreen.monitors
		{
			if(wx>=v.l and wx<=v.r and wy>=v.t and wy<=v.b){
				Return showat_monitor(k)
			}
		}
	}
	Return ""
	showat_monitor(n){
		; MsgBox("showat " n)
		; ahko_grid.GetClientPos(,,&w,&h)
		Return "x" Round(isFullScreen.monitors[n].l+isFullScreen.monitors[n].r-ahko_grid.size.w)//2 " y" Round(isFullScreen.monitors[n].t+isFullScreen.monitors[n].b-ahko_grid.size.h)//2
	}
}

;{ GuiButtonIcon
; Fanatic Guru
; 2014 05 31
; Version 2.0
;
; FUNCTION to Assign an Icon to a Gui Button
;
;------------------------------------------------
;
; Method:
;   GuiButtonIcon(Handle, File, Options)
;
;   Parameters:
;   1) {Handle} 	HWND handle of Gui button
;   2) {File} 		File containing icon image
;   3) {Index} 		Index of icon in file
;						Optional: Default = 1
;   4) {Options}	Single letter flag followed by a number with multiple options delimited by a space
;						W = Width of Icon (default = 16)
;						H = Height of Icon (default = 16)
;						S = Size of Icon, Makes Width and Height both equal to Size
;						L = Left Margin
;						T = Top Margin
;						R = Right Margin
;						B = Botton Margin
;						A = Alignment (0 = left, 1 = right, 2 = top, 3 = bottom, 4 = center; default = 4)
;
; Return:
;   1 = icon found, 0 = icon not found
;
; Example:
; Gui, Add, Button, w70 h38 hwndIcon, Save
; GuiButtonIcon(Icon, "shell32.dll", 259, "s30 a1 r2")
; Gui, Show
;
GuiButtonIcon(Handle, File, Index := 1, Options := "")
{
	RegExMatch(Options, "i)w\K\d+", &W) ? W:=W[] : W := 16
	RegExMatch(Options, "i)h\K\d+", &H) ? (H:=H[]) : H := 16
	RegExMatch(Options, "i)s\K\d+", &S) ? W := H := S[] : (0)
	RegExMatch(Options, "i)l\K\d+", &L) ? (L:=L[]) : L := 0
	RegExMatch(Options, "i)t\K\d+", &T) ? (T:=T[]) : T := 0
	RegExMatch(Options, "i)r\K\d+", &R) ? (R:=R[]) : R := 0
	RegExMatch(Options, "i)b\K\d+", &B) ? (B:=B[]) : B := 0
	RegExMatch(Options, "i)a\K\d+", &A) ? (A:=A[]) : A := 4
	Psz := A_PtrSize = "" ? 4 : A_PtrSize
	DW := "UInt"
	Ptr := A_PtrSize = "" ? DW : "Ptr"
	button_il_Buffer := Buffer(20 + Psz, 0)
	normal_il := DllCall( "ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1 )
	NumPut( Ptr, normal_il, button_il_Buffer, 0)	; Width & Height
	NumPut( DW, L, button_il_Buffer, 0 + Psz)		; Left Margin
	NumPut( DW, T, button_il_Buffer, 4 + Psz)		; Top Margin
	NumPut( DW, R, button_il_Buffer, 8 + Psz)		; Right Margin
	NumPut( DW, B, button_il_Buffer, 12 + Psz)	; Bottom Margin	
	NumPut( DW, A, button_il_Buffer, 16 + Psz)	; Alignment
	SendMessage(BCM_SETIMAGELIST := 5634, 0, button_il_Buffer.Ptr,, "ahk_id " Handle)
	return IL_Add( normal_il, File, Index )
}
