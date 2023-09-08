

#Include Gdip_All.ahk
pGDI := Gdip_Startup()

class ahko_gridview_class
{
	showat := "10"
	grid_opt := "+AlwaysOnTop -DPIScale +Owner"
	grid_gui := Gui(this.grid_opt)
	grid_sub_gui := []
	use_gdip := 0

	item_pos:=Array(
		{x:0,y:0,key:'1'},{x:1,y:0,key:'2'},{x:2,y:0,key:'3'},
		{x:0.5,y:1,key:'q'},{x:1.5,y:1,key:'w'},{x:2.5,y:1,key:'e'},
		{x:1,y:2,key:'a'},{x:2,y:2,key:'s'},{x:3,y:2,key:'d'},
		{x:3,y:0,key:'4'},{x:3.5,y:1,key:'r'},{x:4,y:2,key:'f'},
		{x:1.5,y:3,key:'z'},{x:2.5,y:3,key:'x'},{x:3.5,y:3,key:'c'},
		{x:4.5,y:3,key:'v'})
	buttonSize:=200
	outerIndex:=1
	gmargin:=10
	titleHeight:=40

	__New(gdip:=0) {
		this.use_gdip := gdip
		this.set_gui_default_prop(this.grid_gui)
		this.grid_gui.size:={
			w:5.5*(this.buttonSize+this.gmargin),
			h:4*(this.buttonSize+this.gmargin)+this.titleHeight
		}
		; add title button
		this.gui_add_btn(this.grid_gui, 
			0, 
			1, 
			this.buttonSize, 
			this.titleHeight, 
			"left", 
			" ahko")

		For k0, layer0 in ahko
		{
			if(InStr(layer0.attrib, "D")) {
				sub_gui:=this.sub_gui_push()
				; add title button
				btn:=this.gui_add_btn(sub_gui, 
					0, 
					1, 
					this.buttonSize, 
					this.titleHeight, 
					"left", 
					layer0.name,
					this.uShow)
				btn.father_gui := this.grid_gui
				; create sub grid
				For k1, layer1 in layer0.sub
				{
					; add item button
					this.gui_add_grid_btn(sub_gui, k1, layer1)
				}
				this.set_gui_transparent(sub_gui)
			}
			; add grid button
			this.gui_add_grid_btn(this.grid_gui, k0, layer0, sub_gui)
		}
		this.set_gui_transparent(this.grid_gui)
		this.hotkey_setup()
	}

	hotkey_setup() {
		this.revkeyList:=map()
		For k, v in this.item_pos
		{
			this.revkeyList[v.key]:=k
		}
		
		subgrid_func_maker(n) {
			select(*) {
				For , v in this.grid_sub_gui
				{
					if not v.isHide
					{
						v.callback[n]()
					}
				}
			}
			return select
		}

		HotIfWinActive("ahk_id " this.grid_gui.Hwnd)
		hotkey("Escape", this.grid_gui.uHide)
		For k, v in this.grid_gui.callback
		{
			if(v!="") {
				hotkey(this.item_pos[k].key, v)
			}
		}
		HotIf

		subgrid_return(*){
			this.Show()
		}
		HotIfWinActive("ahk_group subgridGroup")
		hotkey("Escape", subgrid_return)
		hotkey("``", subgrid_return)
		Loop 16
		{
			hotkey(this.item_pos[A_Index].key, subgrid_func_maker(A_Index))
		}
		HotIf
	}

	sub_gui_push()
	{
		this.grid_sub_gui.Push(Gui(this.grid_opt))
		this.set_gui_default_prop(this.grid_sub_gui[-1])
		GroupAdd("subgridGroup", "ahk_id " this.grid_sub_gui[-1].Hwnd)
		Return this.grid_sub_gui[-1]
	}
	
	set_gui_default_prop(g) {
		uHide(*) {
			g.isHide:=True
			g.Hide()
		}
		uShow(*) {
			g.isHide:=False
			g.Show(this.gui_showat())
		}
		g.btnCall:=[]
		g.isHide:=True
		g.uShow := uShow
		g.uHide := uHide
		g.SetFont(, "Microsoft JhengHei")
		g.SetFont(, "Verdana")
		g.SetFont(, "LilyUPC")
		g.SetFont("s14 w700 cc07070")
	}

	set_gui_transparent(g)
	{
		g.BackColor := "FF00FF"
		WinSetTransColor "FF00FF 0xE0", g.Hwnd
		g.Opt("-Caption")
		g.Show("Hide")
	}

	runner_maker(file, grid:="")
	{
		runner(*) {
			if(grid is Class and grid.HasOwnProp("uHide")) {
				grid.uHide()
			}
			SplitPath(file,,&atDir)
			Try{
				Run(file, atDir)
			}
		}
		return runner
	}

	gui_add_btn(obj, x, y, w, h, opt:="", title:="", callback:="")
	{
		if(!this.use_gdip) {
			btn:=obj.add("Button", "x" x " y" y " w" w " h" h " " opt, " " title)
		} else {
			btn:=obj.add("Picture", "x" x " y" y " w" w " h" h " 0xE 0x200 -Border",)

			pBitmapBtn := Gdip_CreateBitmap(200, 200)
			G := Gdip_GraphicsFromImage(pBitmapBtn)
			pBrush:=Gdip_BrushCreateSolid(0xFF000000)
			Gdip_FillRoundedRectangle(G, pBrush, 2, 2, 96, 96, 20)
			Gdip_DeleteBrush(pBrush)
			gui_pic_show_bitmap(btn, pBitmapBtn, 0, 0, 200, 200)
			Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapBtn), DeleteObject(G)
		}
		if(callback) {
			btn.OnEvent("Click", callback)
		}
		Return btn
	}

	gui_add_grid_btn(guiobj, grid_index, ahko_obj, sub_grid:="")
	{
		callback_maker() {
			callback(*){
				guiobj.uHide()
				if(sub_grid!="" && InStr(ahko_obj.attrib, "D")){
					sub_grid.uShow()
				} else if(ahko_obj!="") {
					SplitPath(ahko_obj.path,,&atDir)
					Try{
						Run(ahko_obj.path, atDir)
					}
				} else {
					this.Show()
				}
			}
			return callback
		}
		callback := callback_maker()
		if(!guiobj.HasOwnProp("callback")) {
			guiobj.callback := map()
		}
		guiobj.callback[grid_index] := callback
		btn:=this.gui_add_btn(guiobj, 
							this.item_pos[grid_index].x*(this.buttonSize+this.gmargin), 
							this.item_pos[grid_index].y*(this.buttonSize+this.gmargin)+this.titleHeight+this.gmargin, 
							this.buttonSize, this.buttonSize, , 
							ahko_obj.name "`n<&" StrUpper(this.item_pos[grid_index].key) ">", 
							callback)
		if(!this.use_gdip) {
			iconPath:=ahko_obj.icon Or fileGethIcon(ahko_obj.path)
			if(iconPath){
				Try{
					GuiButtonIcon(btn.hwnd, iconPath,, "a2 s100 t16")
				}
			}
		}
	}

	gui_showat()
	{
		global isFullScreen
		; MsgBox(this.showat)
		CoordMode("Mouse","Screen")
		if(this.showat=="0"){
			Return ""
		}
		if(this.showat>=1 and this.showat<=9){
			if(isFullScreen.monitors.Length >= this.showat){
				Return showat_monitor(this.showat)
			}else{
				Return ""
			}
		}
		if(this.showat=="10"){
			MouseGetPos(&mx,&my)
			For k, v in isFullScreen.monitors
			{
				; MsgBox("m" k ":mx" mx ",my" my "`nl" v.l "r" v.r "t" v.t "b" v.b)
				if(mx>=v.l && mx<=v.r && my>=v.t && my<=v.b){
					Return showat_monitor(k)
				}
			}
		}
		if(this.showat=="11"){
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
			Return "x" Round(isFullScreen.monitors[n].l+isFullScreen.monitors[n].r-this.grid_gui.size.w)//2 " y" Round(isFullScreen.monitors[n].t+isFullScreen.monitors[n].b-this.grid_gui.size.h)//2
		}
	}

	; for callback this=button
	uShow(*) {
		if(this.HasOwnProp("father_gui")) {
			this.father_gui.uShow()
			SetTimer(this.gridWaitNotActive, 100)
		}
		this.Gui.uHide()
	}

	Show() {
		For , v in this.grid_sub_gui
		{
			if(!v.isHide){
				v.uHide()
			}
		}
		this.grid_gui.uShow()
		SetTimer(this.gridWaitNotActive, 100)
	}

	gridWaitNotActive {
		get {
			cb() {
				active_count:=0
				if(!this.grid_gui.isHide) {
					active_count += 1
					if(!WinActive("ahk_id " this.grid_gui.hwnd)){
						this.grid_gui.uHide()
						SetTimer(this.gridWaitNotActive, 0)
						Return
					}
				}
				For , v in this.grid_sub_gui
				{
					if(!v.isHide){
						active_count += 1
						if(!WinActive("ahk_id " v.hwnd)){
							v.uHide()
							SetTimer(this.gridWaitNotActive, 0)
							Return
						}
					}
				}
				if(!active_count) {
					SetTimer(this.gridWaitNotActive, 0)
				}
			}
			Return cb
		}
	}
}

gui_pic_show_bitmap(GuiCtrlObj, pBitmap, sx:=0, sy:=0, sw:=0, sh:=0)
{
	Gdip_GetImageDimensions(pBitmap, &W, &H)
	percentW:=sw/W
	percentH:=sh/H
	percent := Min(percentW, percentH)
	if(percent==0) {
		percent := 1
	}

	picW:=W*percent
	picH:=H*percent

	; msgbox(picW "`n" picH)

	pBitmapShow := Gdip_CreateBitmap(picW, picH)
	G := Gdip_GraphicsFromImage(pBitmapShow)
	Gdip_SetSmoothingMode(G, 4)
	Gdip_SetInterpolationMode(G, 7)
	Gdip_DrawImage(G, pBitmap, sx, sy, picW, picH)
	hBitmapShow := Gdip_CreateHBITMAPFromBitmap(pBitmapShow)
	SetImage(GuiCtrlObj.hwnd, hBitmapShow)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapShow), DeleteObject(hBitmapShow)
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
