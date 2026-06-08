#Include Gdip_All.ahk
pGDI := Gdip_Startup()

class ahko_gridview_class
{
	showat := "10"
	grid_opt := "+AlwaysOnTop -DPIScale +Owner +E0x08000000"
	grid_gui := Gui(this.grid_opt)
	grid_sub_gui := []

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
	_mouseCheckTimer := ""
	_ih := ""
	_skipMisfireCount := 0

	__New() {
		for k, v in this.item_pos {
			this.item_map[v.key] := { idx: k, x: v.x, y: v.y }
		}
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
			this._skipMisfireCount := 2
		}
		g.btnCall := []
		g.isHide := True
		g.uShow := uShow
		g.uHide := uHide
	}

	set_gui_transparent(g)
	{
		g.BackColor := "00FF00"
		WinSetTransColor "00FF00 220", g.Hwnd
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
		btn := guiobj.add("Picture", "x" x " y" y " w" w " h" h " 0xE 0x200 -Border",)

		pBitmapBtn := Gdip_CreateBitmap(w, h)
		local pBitmapIcon := 0
		if (IsObject(ahko_obj)) {
			if ahko_obj.icon {
				pBitmapIcon := Gdip_CreateBitmapFromFile(ahko_obj.icon)
			} else {
				fileinfo := Buffer(fisize := A_PtrSize + 688)
				if DllCall("shell32\SHGetFileInfoW", "WStr", ahko_obj.path
					, "UInt", 0, "Ptr", fileinfo, "UInt", fisize, "UInt", 0x100)
				{
					hicon := NumGet(fileinfo, 0, "Ptr")
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
			Gdip_TextToGraphics(G, StrUpper(key), "x" xy " y" xy " w" wh " h" wh " cffffffff s" size_percent(this.buttonSize, 12) " R4")
			Gdip_TextToGraphics(G, name, "x" size_percent(this.buttonSize, 2.5) " y" size_percent(this.buttonSize, 70) " w" size_percent(this.buttonSize, 95) " h" size_percent(this.buttonSize, 24) " vCenter Center cffffffff s" size_percent(this.buttonSize, 11) " R4", "Microsoft JhengHei")
		} else {
			Gdip_TextToGraphics(G, name, "x" size_percent(this.buttonSize, 2) " y" size_percent(this.buttonSize, 2) " w" size_percent(this.buttonSize, 96) " h" size_percent(this.titleHeight, 96) " vCenter Center cffffffff s" size_percent(this.buttonSize, 11) " R4", "Microsoft JhengHei")
		}
		gui_pic_show_bitmap(btn, pBitmapBtn, 0, 0, w, h)
		Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmapBtn), DeleteObject(G)
		if (callback) {
			btn.OnEvent("Click", callback)
		}
		Return btn
	}

	gui_add_grid_btn(guiobj, ahko_obj, sub_grid := "")
	{
		callback_maker() {
			callback(*) {
				this._skipMisfireCount := 2
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
		this._startMisfireDetection()
	}

	_isAnyVisible() {
		if (!this.grid_gui.isHide)
			return true
		For v in this.grid_sub_gui {
			if (!v.isHide)
				return true
		}
		return false
	}

	_isAhkoHwnd(hwnd) {
		if (hwnd == this.grid_gui.Hwnd)
			return true
		For v in this.grid_sub_gui {
			if (hwnd == v.Hwnd)
				return true
		}
		return false
	}

	_hideAll() {
		this._stopMisfireDetection()
		this._subHide()
		if (!this.grid_gui.isHide) {
			this.grid_gui.uHide()
		}
	}

	_startMisfireDetection() {
		this._stopMisfireDetection()
		this._mouseCheckTimer := ObjBindMethod(this, "_checkMouseClick")
		SetTimer(this._mouseCheckTimer, 50)
		this._ih := InputHook("L")
		this._ih.KeyOpt("{All}", "E")
		this._ih.OnEnd := ObjBindMethod(this, "_onKeyboardInput")
		this._ih.Start()
	}

	_stopMisfireDetection() {
		if (this._mouseCheckTimer) {
			SetTimer(this._mouseCheckTimer, 0)
			this._mouseCheckTimer := ""
		}
		if (this._ih) {
			this._ih.OnEnd := ""
			this._ih.Stop()
			this._ih := ""
		}
	}

	_checkMouseClick() {
		if (!this._isAnyVisible()) {
			this._stopMisfireDetection()
			return
		}
		if (this._skipMisfireCount > 0) {
			this._skipMisfireCount -= 1
			DllCall("GetAsyncKeyState", "int", 0x01)
			DllCall("GetAsyncKeyState", "int", 0x02)
			return
		}
		if (DllCall("GetAsyncKeyState", "int", 0x01) & 1) {
			MouseGetPos(, , &winId)
			if (!this._isAhkoHwnd(winId)) {
				this._hideAll()
			}
		}
		if (DllCall("GetAsyncKeyState", "int", 0x02) & 1) {
			MouseGetPos(, , &winId)
			if (!this._isAhkoHwnd(winId)) {
				this._hideAll()
			}
		}
	}

	_onKeyboardInput(ih, vk := 0, sc := 0) {
		if (!this._isAnyVisible()) {
			this._stopMisfireDetection()
			return
		}
		this._hideAll()
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
