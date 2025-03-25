#Include Gdip_All.ahk
pGDI := Gdip_Startup()

class ahko_gridview_class
{
	showat := "10"
	grid_opt := "+AlwaysOnTop -DPIScale +Owner +E0x08000000"
	grid_gui := Gui(this.grid_opt)
	grid_sub_gui := []
	use_gdip := 0

	item_pos := Array(
	{ x: 0, y: 0, key: '1' }, 
	{ x: 1, y: 0, key: '2' }, 
	{ x: 2, y: 0, key: '3' }, 
	{ x: 0.5, y: 1, key: 'q' }, 
	{ x: 1.5, y: 1, key: 'w' }, 
	{ x: 2.5, y: 1, key: 'e' }, 
	{ x: 1, y: 2, key: 'a' }, 
	{ x: 2, y: 2, key: 's' }, 
	{ x: 3, y: 2, key: 'd' }, 
	{ x: 3, y: 0, key: '4' }, 
	{ x: 3.5, y: 1, key: 'r' }, 
	{ x: 4, y: 2, key: 'f' }, 
	{ x: 1.5, y: 3, key: 'z' }, 
	{ x: 2.5, y: 3, key: 'x' }, 
	{ x: 3.5, y: 3, key: 'c' }, 
	{ x: 4.5, y: 3, key: 'v' })
	buttonSize := 200
	outerIndex := 1
	gmargin := 10
	titleHeight := 42
	item_map := Map()

	__New(gdip := 0) {
		for k, v in this.item_pos {
			this.item_map[v.key] := { idx: k, x: v.x, y: v.y }
		}
		this.use_gdip := gdip
		this.set_gui_default_prop(this.grid_gui)
		this.grid_gui.size := {
			w: 5.5 * (this.buttonSize + this.gmargin),
			h: 4 * (this.buttonSize + this.gmargin) + this.titleHeight
		}
		; add title button
		this.gui_add_btn(this.grid_gui, "",
			0,
			1,
			this.buttonSize,
			this.titleHeight,
			"left",
			" ahko", "", this.grid_gui.uHide)

		For layer0 in ahko
		{
			if (InStr(layer0.attrib, "D")) {
				sub_gui := this.sub_gui_push()
				; add title button
				btn := this.gui_add_btn(sub_gui, "",
					0,
					1,
					this.buttonSize,
					this.titleHeight,
					"left",
					layer0.name, "",
					this.uShow)
				btn.father_gui := this.grid_gui
				; create sub grid
				For layer1 in layer0.sub
				{
					; add item button
					this.gui_add_grid_btn(sub_gui, layer1)
				}
				this.set_gui_transparent(sub_gui)
				; add grid button
				if (layer0.sub.Length > 0) {
					this.gui_add_grid_btn(this.grid_gui, layer0, sub_gui)
				}
			} else {
				this.gui_add_grid_btn(this.grid_gui, layer0, "")
			}
		}
		this.set_gui_transparent(this.grid_gui)
		this.hotkey_setup()
	}

	hotkey_setup() {
		subgrid_func_maker(n) {
			select(*) {
				For v in this.grid_sub_gui
				{
					if not v.isHide
					{
						if (v.callback.Has(n)) {
							v.callback[n]()
						}
					}
				}
			}
			return select
		}

		HotIfWinExist("ahk_id " this.grid_gui.Hwnd)
		hotkey("Escape", this.grid_gui.uHide)
		hotkey("``", this.grid_gui.uHide)
		For k, v in this.grid_gui.callback
		{
			hotkey(k, v)
		}
		HotIf

		subgrid_return(*) {
			this.Show()
		}
		HotIfWinExist("ahk_group subgridGroup")
		hotkey("Escape", this.subHide)
		hotkey("``", subgrid_return)
		For k, v in this.item_map
		{
			hotkey(k, subgrid_func_maker(k))
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
			g.isHide := True
			g.Hide()
		}
		uShow(*) {
			g.isHide := False
			g.Show(this.gui_showat() " NA")
		}
		g.btnCall := []
		g.isHide := True
		g.uShow := uShow
		g.uHide := uHide
		if !this.use_gdip {
			g.SetFont(, "Consolas")
			g.SetFont(, "Comic Sans MS")
			g.SetFont(, "Microsoft JhengHei")
			g.SetFont("s12 w700 cc07070")
		}
	}

	set_gui_transparent(g)
	{
		if !this.use_gdip {
			g.BackColor := "FF00FF"
			WinSetTransColor "FF00FF 0xE0", g.Hwnd
		} else {
			g.BackColor := "00FF00"
			WinSetTransColor "00FF00 220", g.Hwnd
		}
		g.Opt("-Caption")
		g.Show("Hide")
	}

	runner_maker(file, grid := "")
	{
		runner(*) {
			if (grid is Class and grid.HasOwnProp("uHide")) {
				grid.uHide()
			}
			SplitPath(file, , &atDir)
			Try {
				Run(file, atDir)
			}
		}
		return runner
	}

	gui_add_btn(guiobj, ahko_obj, x, y, w, h, opt := "", name := "", key := "", callback := "")
	{
		if (!this.use_gdip) {
			title := name "`n<&" StrUpper(key) ">"
			btn := guiobj.add("Button", "x" x " y" y " w" w " h" h " " opt, title)
			if (IsObject(ahko_obj)) {
				iconPath := ahko_obj.icon Or fileGethIcon(ahko_obj.path)
				if (iconPath) {
					Try {
						GuiButtonIcon(btn.hwnd, iconPath, , "a2 s100 t16")
					}
				}
			}
		} else {
			btn := guiobj.add("Picture", "x" x " y" y " w" w " h" h " 0xE 0x200 -Border",)

			pBitmapBtn := Gdip_CreateBitmap(w, h)
			local pBitmapIcon := 0
			if (IsObject(ahko_obj)) {
				if ahko_obj.icon {
					pBitmapIcon := Gdip_CreateBitmapFromFile(ahko_obj.icon)
				} else {
					fileinfo := Buffer(fisize := A_PtrSize + 688)
					; Get the file's icon.
					if DllCall("shell32\SHGetFileInfoW", "WStr", ahko_obj.path
						, "UInt", 0, "Ptr", fileinfo, "UInt", fisize, "UInt", 0x100)
					{
						hicon := NumGet(fileinfo, 0, "Ptr")
						; GetIconDimensions(hicon, &W, &H)
						; MsgBox W "," H
						pBitmapIcon := Gdip_CreateBitmapFromHICON(hicon)
					}
				}
			}
			G := Gdip_GraphicsFromImage(pBitmapBtn)
			pBrush := Gdip_BrushCreateSolid(0xFFAAAAAA)
			Gdip_FillRoundedRectangle(G, pBrush, 1, 1, w - 2, h - 2, 16)
			Gdip_DeleteBrush(pBrush)
			pBrush := Gdip_BrushCreateSolid(0xFF010101)
			Gdip_FillRoundedRectangle(G, pBrush, 3, 3, w - 6, h - 6, 16)
			Gdip_DeleteBrush(pBrush)
			Gdip_SetCompositingMode(G)
			if (pBitmapIcon) {
				Gdip_SetSmoothingMode(G, 4)
				Gdip_SetInterpolationMode(G, 7)
				Gdip_DrawImage(G, pBitmapIcon, 50, 30, 100, 100)
				Gdip_DisposeImage(pBitmapIcon)
			}
			if (IsObject(ahko_obj)) {
				xy := size_percent(this.buttonSize, 6)
				wh := size_percent(this.buttonSize, 13)
				; this.titleHeight,
				Gdip_TextToGraphics(G, StrUpper(key), "x" xy " y" xy " w" wh " h" wh " cffffffff s" size_percent(this.buttonSize, 12) " R4")
				Gdip_TextToGraphics(G, name, "x" size_percent(this.buttonSize, 2.5) " y" size_percent(this.buttonSize, 70) " w" size_percent(this.buttonSize, 95) " h" size_percent(this.buttonSize, 24) " vCenter Center cffffffff s" size_percent(this.buttonSize, 11) " R4", "Microsoft JhengHei")
			} else {
				Gdip_TextToGraphics(G, name, "x" size_percent(this.buttonSize, 2) " y" size_percent(this.buttonSize, 2) " w" size_percent(this.buttonSize, 96) " h" size_percent(this.titleHeight, 96) " vCenter Center cffffffff s" size_percent(this.buttonSize, 11) " R4", "Microsoft JhengHei")
			}
			gui_pic_show_bitmap(btn, pBitmapBtn, 0, 0, w, h)
			Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapBtn), DeleteObject(G)
		}
		if (callback) {
			btn.OnEvent("Click", callback)
		}
		Return btn
	}

	gui_add_grid_btn(guiobj, ahko_obj, sub_grid := "")
	{
		callback_maker() {
			callback(*) {
				guiobj.uHide()
				if (sub_grid != "" && InStr(ahko_obj.attrib, "D")) {
					sub_grid.uShow()
				} else if (ahko_obj != "") {
					SplitPath(ahko_obj.path, , &atDir, &ext)
					Try {
						if (StrCompare(ext, "ahk") != 0) {
							Run(ahko_obj.path, atDir)
						} else {
							Run('"' A_ScriptFullPath '" /script /force "' ahko_obj.path '"')
						}
					}
				} else {
					this.Show()
				}
			}
			return callback
		}
		callback := callback_maker()
		if (!guiobj.HasOwnProp("callback")) {
			guiobj.callback := map()
		}

		guiobj.callback[ahko_obj.key] := callback
		btn := this.gui_add_btn(guiobj, ahko_obj,
			this.item_map[ahko_obj.key].x * (this.buttonSize + this.gmargin),
			this.item_map[ahko_obj.key].y * (this.buttonSize + this.gmargin) + this.titleHeight + this.gmargin,
			this.buttonSize, this.buttonSize, ,
			ahko_obj.name, ahko_obj.key,
			callback)
	}

	gui_showat()
	{
		global isFullScreen
		; MsgBox(this.showat)
		CoordMode("Mouse", "Screen")
		if (this.showat == "0") {
			Return ""
		}
		if (this.showat >= 1 and this.showat <= 9) {
			if (isFullScreen.monitors.Length >= this.showat) {
				Return showat_monitor(this.showat)
			} else {
				Return ""
			}
		}
		if (this.showat == "10") {
			MouseGetPos(&mx, &my)
			For k, v in isFullScreen.monitors
			{
				; MsgBox("m" k ":mx" mx ",my" my "`nl" v.l "r" v.r "t" v.t "b" v.b)
				if (mx >= v.l && mx <= v.r && my >= v.t && my <= v.b) {
					Return showat_monitor(k)
				}
			}
		}
		if (this.showat == "11") {
			try {
				WinGetPos(&wx, &wy, &ww, &wh, "A")
			} catch TargetError as e {
				Return ""
			} else {
				wx += ww // 3
				wy += wh // 3
				For k, v in isFullScreen.monitors
				{
					if (wx >= v.l and wx <= v.r and wy >= v.t and wy <= v.b) {
						Return showat_monitor(k)
					}
				}
			}
		}
		Return ""
		showat_monitor(n) {
			Return "x" Round(isFullScreen.monitors[n].l + isFullScreen.monitors[n].r - this.grid_gui.size.w) // 2 " y" Round(isFullScreen.monitors[n].t + isFullScreen.monitors[n].b - this.grid_gui.size.h) // 2
		}
	}

	; for callback this=button
	uShow(*) {
		if (this.HasOwnProp("father_gui")) {
			this.father_gui.uShow()
			; SetTimer(this.gridWaitNotActive, 100)
		}
		this.Gui.uHide()
	}

	_subHide() {
		For v in this.grid_sub_gui
		{
			if (!v.isHide) {
				v.uHide()
			}
		}
	}
	subHide(*) {
		static _class := this
		if IsObject(this) {
			this._subHide()
		} else {
			_class._subHide()
		}
	}
	Show() {
		this.subHide()
		this.grid_gui.uShow()
		; SetTimer(this.gridWaitNotActive, 100)
	}

	gridWaitNotActive {
		get {
			cb() {
				active_count := 0
				if (!this.grid_gui.isHide) {
					active_count += 1
					if (!WinActive("ahk_id " this.grid_gui.hwnd)) {
						this.grid_gui.uHide()
						SetTimer(this.gridWaitNotActive, 0)
						Return
					}
				}
				For v in this.grid_sub_gui
				{
					if (!v.isHide) {
						active_count += 1
						if (!WinActive("ahk_id " v.hwnd)) {
							v.uHide()
							SetTimer(this.gridWaitNotActive, 0)
							Return
						}
					}
				}
				if (!active_count) {
					SetTimer(this.gridWaitNotActive, 0)
				}
			}
			Return cb
		}
	}
}

size_percent(s, percent) {
	return Round(s * percent / 100)
}

gui_pic_show_bitmap(GuiCtrlObj, pBitmap, sx := 0, sy := 0, sw := 0, sh := 0)
{
	Gdip_GetImageDimensions(pBitmap, &W, &H)
	if Min(W, H) <= 0 {
		return
	}
	percentW := sw / W
	percentH := sh / H
	percent := Min(percentW, percentH)
	if (percent == 0) {
		percent := 1
	}

	picW := W * percent
	picH := H * percent

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
	RegExMatch(Options, "i)w\K\d+", &W) ? W := W[] : W := 16
	RegExMatch(Options, "i)h\K\d+", &H) ? (H := H[]) : H := 16
	RegExMatch(Options, "i)s\K\d+", &S) ? W := H := S[] : (0)
	RegExMatch(Options, "i)l\K\d+", &L) ? (L := L[]) : L := 0
	RegExMatch(Options, "i)t\K\d+", &T) ? (T := T[]) : T := 0
	RegExMatch(Options, "i)r\K\d+", &R) ? (R := R[]) : R := 0
	RegExMatch(Options, "i)b\K\d+", &B) ? (B := B[]) : B := 0
	RegExMatch(Options, "i)a\K\d+", &A) ? (A := A[]) : A := 4
	Psz := A_PtrSize = "" ? 4 : A_PtrSize
	DW := "UInt"
	Ptr := A_PtrSize = "" ? DW : "Ptr"
	button_il_Buffer := Buffer(20 + Psz, 0)
	normal_il := DllCall("ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1)
	NumPut(Ptr, normal_il, button_il_Buffer, 0)	; Width & Height
	NumPut(DW, L, button_il_Buffer, 0 + Psz)		; Left Margin
	NumPut(DW, T, button_il_Buffer, 4 + Psz)		; Top Margin
	NumPut(DW, R, button_il_Buffer, 8 + Psz)		; Right Margin
	NumPut(DW, B, button_il_Buffer, 12 + Psz)	; Bottom Margin
	NumPut(DW, A, button_il_Buffer, 16 + Psz)	; Alignment
	SendMessage(BCM_SETIMAGELIST := 5634, 0, button_il_Buffer.Ptr, , "ahk_id " Handle)
	return IL_Add(normal_il, File, Index)
}
