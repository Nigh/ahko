setup_winW := 540
setup_winH := 620
setup_margin := 28
setup_inputH := 36
setup_radius := 10
setup_font := "Microsoft JhengHei"

clrBg := 0xFF11111B
clrPanel := 0xFF1E1E2E
clrHeader := 0xFF181825
clrAccent := 0xFF89B4FA
clrAccentHover := 0xFFB4D0FB
clrTextPri := 0xFFCDD6F4
clrTextSec := 0xFF6C7086
clrTextInv := 0xFF1E1E2E
clrSurface := 0xFF313244
clrSurfaceHover := 0xFF45475A
clrInputBg := 0xFF313244
clrInputBorder := 0xFF45475A
clrBtnSave := 0xFF89B4FA
clrBtnSaveHover := 0xFFB4D0FB
clrBtnCancel := 0xFF313244
clrBtnCancelHover := 0xFF45475A
clrBtnCancelText := 0xFFCDD6F4
clrCloseBtn := 0xFF45475A
clrCloseBtnHover := 0xFFF38BA8
clrDivider := 0xFF313244

setup_headerH := 68

setup_posY_watchLabel := setup_headerH + 22
setup_posY_pathInput := setup_posY_watchLabel + 28
setup_posY_hotkeyLabel := setup_posY_pathInput + setup_inputH + 22
setup_posY_hotkeyInput := setup_posY_hotkeyLabel + 28
setup_posY_hotkeyText := setup_posY_hotkeyInput + setup_inputH + 8
setup_posY_showAtLabel := setup_posY_hotkeyText + 22 + 20
setup_posY_showAtDDL := setup_posY_showAtLabel + 28
setup_posY_otherLabel := setup_posY_showAtDDL + setup_inputH + 24
setup_posY_fullscreen := setup_posY_otherLabel + 28
setup_posY_autoStart := setup_posY_fullscreen + 34
setup_posY_buttons := setup_posY_autoStart + 34 + 36

setup_pathBtnX := setup_winW - setup_margin - 100
setup_pathBtnW := 100
setup_hotkeyWinX := setup_winW - setup_margin - 100
setup_hotkeyWinW := 100
setup_inputW := setup_winW - setup_margin * 2 - 110
setup_ddlW := setup_winW - setup_margin * 2
setup_ctrlX := setup_margin

setup_saveBtnX := setup_margin
setup_saveBtnY := setup_posY_buttons
setup_saveBtnW := (setup_winW - setup_margin * 2 - 20) // 2
setup_saveBtnH := 44
setup_cancelBtnX := setup_saveBtnX + setup_saveBtnW + 20
setup_cancelBtnY := setup_posY_buttons
setup_cancelBtnW := setup_saveBtnW
setup_cancelBtnH := 44

hover_none := 0
hover_sel := 1
hover_save := 2
hover_cancel := 3
hover_close := 4
setup_hoverState := hover_none

ahko_setup := Gui("-Caption +ToolWindow +AlwaysOnTop -DPIScale +OwnDialogs")
ahko_setup.BackColor := "11111B"
ahko_setup.MarginX := 0
ahko_setup.MarginY := 0

setup_picBg := ahko_setup.Add("Picture", "x0 y0 w" setup_winW " h" setup_winH " 0xE +BackgroundTrans")

ahkoSetup_path := ahko_setup.Add("Edit", "x" setup_ctrlX " y" setup_posY_pathInput " w" setup_inputW " h" setup_inputH " -E0x200 -Border Background313244 cCDD6F4")
ahkoSetup_path.SetFont("s11", setup_font)

setup_picSel := ahko_setup.Add("Picture", "x" setup_pathBtnX " y" setup_posY_pathInput " w" setup_pathBtnW " h" setup_inputH " 0xE +BackgroundTrans")
setup_picSel.OnEvent("Click", setup_path)

ahkoSetup_hotkey := ahko_setup.Add("Hotkey", "x" setup_ctrlX " y" setup_posY_hotkeyInput " w" setup_inputW " h" setup_inputH " -E0x200")
ahkoSetup_hotkey.SetFont("s11 cCDD6F4", setup_font)

ahkoSetup_hotkeyWin := ahko_setup.Add("CheckBox", "x" setup_hotkeyWinX " y" setup_posY_hotkeyInput " w" setup_hotkeyWinW " h" setup_inputH " -E0x200 Background313244 cCDD6F4", "Win")
ahkoSetup_hotkeyWin.SetFont("s11", setup_font)

ahkoSetup_hotkeyText := ahko_setup.Add("Text", "x" setup_ctrlX " y" setup_posY_hotkeyText " w" setup_ddlW " h" 26 " +BackgroundTrans cB4D0FB")
ahkoSetup_hotkeyText.SetFont("s13 w700", setup_font)

showAtDDL := ["Primary monitor", "Follow mouse", "Follow active window"]
For k_ddl, v_ddl in isFullScreen.monitors
{
	showAtDDL.Push("Monitor #" k_ddl)
}
ahkoSetup_showAt := ahko_setup.Add("DropDownList", "x" setup_ctrlX " y" setup_posY_showAtDDL " w" setup_ddlW " h" 220 " -E0x200", showAtDDL)
ahkoSetup_showAt.SetFont("s11 cCDD6F4", setup_font)

ahkoSetup_enable_fullscreen := ahko_setup.Add("CheckBox", "x" setup_ctrlX " y" setup_posY_fullscreen " w" setup_ddlW " h" 28 " -E0x200 Background1E1E2E cCDD6F4", "Enable in fullscreen")
ahkoSetup_enable_fullscreen.SetFont("s11", setup_font)

ahkoSetup_autoStart := ahko_setup.Add("CheckBox", "x" setup_ctrlX " y" setup_posY_autoStart " w" setup_ddlW " h" 28 " -E0x200 Background1E1E2E cCDD6F4", "Startup with Windows")
ahkoSetup_autoStart.SetFont("s11", setup_font)

setup_picSave := ahko_setup.Add("Picture", "x" setup_saveBtnX " y" setup_saveBtnY " w" setup_saveBtnW " h" setup_saveBtnH " 0xE +BackgroundTrans")
setup_picCancel := ahko_setup.Add("Picture", "x" setup_cancelBtnX " y" setup_cancelBtnY " w" setup_cancelBtnW " h" setup_cancelBtnH " 0xE +BackgroundTrans")
setup_picClose := ahko_setup.Add("Picture", "x" setup_winW - 48 " y" 18 " w" 32 " h" 32 " 0xE +BackgroundTrans")

setup_picSave.OnEvent("Click", ahko_setup_save)
setup_picCancel.OnEvent("Click", ahko_setup_cancel)
setup_picClose.OnEvent("Click", ahko_setup_cancel)
ahkoSetup_hotkey.OnEvent("Change", hotkeyText_update)
ahkoSetup_hotkeyWin.OnEvent("Click", hotkeyText_update)
ahkoSetup_showAt.OnEvent("Change", showAt_update)
ahkoSetup_enable_fullscreen.OnEvent("Click", enable_fullscreen_update)
ahkoSetup_autoStart.OnEvent("Click", autoStartup_update)

OnMessage(0x0201, setup_WM_LBUTTONDOWN)

setup_btnHitAreas := Map()
setup_btnHitAreas[hover_sel] := { x: setup_pathBtnX, y: setup_posY_pathInput, w: setup_pathBtnW, h: setup_inputH }
setup_btnHitAreas[hover_save] := { x: setup_saveBtnX, y: setup_saveBtnY, w: setup_saveBtnW, h: setup_saveBtnH }
setup_btnHitAreas[hover_cancel] := { x: setup_cancelBtnX, y: setup_cancelBtnY, w: setup_cancelBtnW, h: setup_cancelBtnH }
setup_btnHitAreas[hover_close] := { x: setup_winW - 48, y: 18, w: 32, h: 32 }

setup_pic_show(ctrl, pBitmap) {
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(ctrl.Hwnd, hBitmap)
	DeleteObject(hBitmap)
}

setup_drawBtn(pGraphics, x, y, w, h, text, bgColor, textColor, fontSize := 12, radius := 8) {
	pBrush := Gdip_BrushCreateSolid(bgColor)
	Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, radius)
	Gdip_DeleteBrush(pBrush)
	Gdip_TextToGraphics(pGraphics, text, "x" x " y" y " w" w " h" h " c" Format("{:08X}", textColor) " s" fontSize " Center vCenter R4", setup_font)
}

setup_makeBtnBitmap(w, h, text, bgColor, textColor, fontSize := 12, radius := 8) {
	pBitmap := Gdip_CreateBitmap(w, h)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 4)
	pBrush := Gdip_BrushCreateSolid(bgColor)
	Gdip_FillRoundedRectangle(G, pBrush, 0, 0, w, h, radius)
	Gdip_DeleteBrush(pBrush)
	Gdip_TextToGraphics(G, text, "x0 y0 w" w " h" h " c" Format("{:08X}", textColor) " s" fontSize " Center vCenter R4", setup_font)
	Gdip_DeleteGraphics(G)
	return pBitmap
}

setup_renderButtons() {
	global

	pBmpSel := setup_makeBtnBitmap(setup_pathBtnW, setup_inputH, "Select", (setup_hoverState == hover_sel) ? clrAccentHover : clrAccent, clrTextInv, 11, 6)
	setup_pic_show(setup_picSel, pBmpSel)
	Gdip_DisposeImage(pBmpSel)

	pBmpSave := setup_makeBtnBitmap(setup_saveBtnW, setup_saveBtnH, "Save", (setup_hoverState == hover_save) ? clrBtnSaveHover : clrBtnSave, clrTextInv, 14, 8)
	setup_pic_show(setup_picSave, pBmpSave)
	Gdip_DisposeImage(pBmpSave)

	pBmpCancel := setup_makeBtnBitmap(setup_cancelBtnW, setup_cancelBtnH, "Cancel", (setup_hoverState == hover_cancel) ? clrBtnCancelHover : clrBtnCancel, clrBtnCancelText, 14, 8)
	setup_pic_show(setup_picCancel, pBmpCancel)
	Gdip_DisposeImage(pBmpCancel)

	closeBg := (setup_hoverState == hover_close) ? clrCloseBtnHover : clrCloseBtn
	closeTxtColor := (setup_hoverState == hover_close) ? clrTextPri : clrTextSec
	pBmpClose := setup_makeBtnBitmap(32, 32, "X", closeBg, closeTxtColor, 13, 4)
	setup_pic_show(setup_picClose, pBmpClose)
	Gdip_DisposeImage(pBmpClose)
}

setup_renderBg() {
	global

	pBitmap := Gdip_CreateBitmap(setup_winW, setup_winH)
	G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_SetSmoothingMode(G, 4)
	Gdip_SetInterpolationMode(G, 7)

	pBrushBg := Gdip_BrushCreateSolid(clrBg)
	Gdip_FillRectangle(G, pBrushBg, 0, 0, setup_winW, setup_winH)
	Gdip_DeleteBrush(pBrushBg)

	pBrushPanel := Gdip_BrushCreateSolid(clrPanel)
	Gdip_FillRoundedRectangle(G, pBrushPanel, 0, 0, setup_winW, setup_winH, setup_radius)
	Gdip_DeleteBrush(pBrushPanel)

	pBrushHeader := Gdip_BrushCreateSolid(clrHeader)
	Gdip_FillRoundedRectangle(G, pBrushHeader, 0, 0, setup_winW, setup_headerH, setup_radius)
	Gdip_DeleteBrush(pBrushHeader)
	pBrushHeaderFill := Gdip_BrushCreateSolid(clrHeader)
	Gdip_FillRectangle(G, pBrushHeaderFill, 0, setup_headerH - setup_radius, setup_winW, setup_radius)
	Gdip_DeleteBrush(pBrushHeaderFill)

	Gdip_TextToGraphics(G, "ahko Setup", "x24 y16 w300 h40 c" Format("{:08X}", clrTextPri) " s22 Bold R4", setup_font)

	pPenDiv := Gdip_CreatePen(clrDivider, 1)
	Gdip_DrawLine(G, pPenDiv, setup_margin, setup_headerH + 1, setup_winW - setup_margin, setup_headerH + 1)
	Gdip_DeletePen(pPenDiv)

	Gdip_TextToGraphics(G, "Watch Folder", "x" setup_ctrlX " y" setup_posY_watchLabel " w300 h28 c" Format("{:08X}", clrTextPri) " s16 Bold R4", setup_font)

	pBrushInput := Gdip_BrushCreateSolid(clrInputBg)
	Gdip_FillRoundedRectangle(G, pBrushInput, setup_ctrlX, setup_posY_pathInput, setup_inputW, setup_inputH, 6)
	Gdip_DeleteBrush(pBrushInput)
	pPenInput := Gdip_CreatePen(clrInputBorder, 1)
	Gdip_DrawRoundedRectangle(G, pPenInput, setup_ctrlX, setup_posY_pathInput, setup_inputW, setup_inputH, 6)
	Gdip_DeletePen(pPenInput)

	Gdip_TextToGraphics(G, "Hotkey", "x" setup_ctrlX " y" setup_posY_hotkeyLabel " w200 h28 c" Format("{:08X}", clrTextPri) " s16 Bold R4", setup_font)

	pBrushInput2 := Gdip_BrushCreateSolid(clrInputBg)
	Gdip_FillRoundedRectangle(G, pBrushInput2, setup_ctrlX, setup_posY_hotkeyInput, setup_inputW, setup_inputH, 6)
	Gdip_DeleteBrush(pBrushInput2)
	pPenInput2 := Gdip_CreatePen(clrInputBorder, 1)
	Gdip_DrawRoundedRectangle(G, pPenInput2, setup_ctrlX, setup_posY_hotkeyInput, setup_inputW, setup_inputH, 6)
	Gdip_DeletePen(pPenInput2)

	pBrushWin := Gdip_BrushCreateSolid(clrSurface)
	Gdip_FillRoundedRectangle(G, pBrushWin, setup_hotkeyWinX, setup_posY_hotkeyInput, setup_hotkeyWinW, setup_inputH, 6)
	Gdip_DeleteBrush(pBrushWin)
	pPenWin := Gdip_CreatePen(clrInputBorder, 1)
	Gdip_DrawRoundedRectangle(G, pPenWin, setup_hotkeyWinX, setup_posY_hotkeyInput, setup_hotkeyWinW, setup_inputH, 6)
	Gdip_DeletePen(pPenWin)

	Gdip_TextToGraphics(G, "Display Location", "x" setup_ctrlX " y" setup_posY_showAtLabel " w300 h28 c" Format("{:08X}", clrTextPri) " s16 Bold R4", setup_font)

	pBrushDDL := Gdip_BrushCreateSolid(clrInputBg)
	Gdip_FillRoundedRectangle(G, pBrushDDL, setup_ctrlX, setup_posY_showAtDDL, setup_ddlW, setup_inputH, 6)
	Gdip_DeleteBrush(pBrushDDL)
	pPenDDL := Gdip_CreatePen(clrInputBorder, 1)
	Gdip_DrawRoundedRectangle(G, pPenDDL, setup_ctrlX, setup_posY_showAtDDL, setup_ddlW, setup_inputH, 6)
	Gdip_DeletePen(pPenDDL)

	Gdip_TextToGraphics(G, "Other", "x" setup_ctrlX " y" setup_posY_otherLabel " w200 h28 c" Format("{:08X}", clrTextPri) " s16 Bold R4", setup_font)

	Gdip_TextToGraphics(G, "github.com/Nigh/ahko", "x" setup_ctrlX " y" setup_winH - 28 " w" setup_ddlW " h20 c" Format("{:08X}", clrTextSec) " s9 Right R4", "Segoe UI")

	setup_pic_show(setup_picBg, pBitmap)
	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)
}

setup_path(*) {
	global ahkoSetup_path, ahko_setup
	ahko_setup.Opt("+OwnDialogs")
	newpath := RegExReplace(DirSelect(, 0), "\\$")
	if (newpath != "") {
		ahkoSetup_path.Value := newpath
	}
}

hotkeyText_update(*) {
	global
	local hotkey_str := ""
	if (ahkoSetup_hotkeyWin.Value) {
		hotkey_str .= "Win + "
	}
	if (InStr(ahkoSetup_hotkey.Value, "^")) {
		hotkey_str .= "Ctrl + "
	}
	if (InStr(ahkoSetup_hotkey.Value, "!")) {
		hotkey_str .= "Alt + "
	}
	if (InStr(ahkoSetup_hotkey.Value, "+")) {
		hotkey_str .= "Shift + "
	}
	hotkey_str .= RegExReplace(ahkoSetup_hotkey.Value, "#|\^|\!|\+|\<|\>")
	ahkoSetup_hotkeyText.Value := hotkey_str
}

showat_from_ddl(dd) {
	if (dd >= 4) {
		return dd - 3
	} else if (dd >= 1) {
		if (dd == 1) {
			return 0
		}
		if (dd == 2) {
			return 10
		}
		if (dd == 3) {
			return 11
		}
	}
	return 1
}
ddl_from_showat(sw) {
	if (sw == 0) {
		return 1
	}
	if (sw == 10) {
		return 2
	}
	if (sw == 11) {
		return 3
	}
	if (sw >= 1 && sw <= 9) {
		return sw + 3
	}
	return 1
}
showAt_update(*) {
	global showat
	if (ahkoSetup_showAt.Value >= 4) {
		showat := showat_from_ddl(ahkoSetup_showAt.Value)
		ahko_setup.Show(showat_monitor(showat))
	} else {
		showat := showat_from_ddl(ahkoSetup_showAt.Value)
	}
	showat_monitor(n) {
		global isFullScreen, ahko_setup
		ahko_setup.GetPos(, , &w, &h)
		Return "x" Round(isFullScreen.monitors[n].l + isFullScreen.monitors[n].r - w) // 2 " y" Round(isFullScreen.monitors[n].t + isFullScreen.monitors[n].b - h) // 2
	}
}

ahko_setup_show(*) {
	global
	if (IsSet(ahko_gridview) && !ahko_gridview.grid_gui.isHide) {
		ahko_gridview._hideAll()
	}
	ahkoSetup_showAt.Value := ddl_from_showat(showat)
	ahkoSetup_path.Value := path
	ahkoSetup_hotkey.Value := RegExReplace(hotkeys, "#")
	ahkoSetup_hotkeyWin.Value := RegExMatch(hotkeys, "#")
	hotkeyText_update()
	local autostart := (RunWait('schtasks /query /tn "ahko"', , "Hide") == 0)
	ahkoSetup_enable_fullscreen.Value := fullscreen_enable
	ahkoSetup_autoStart.Value := autostart ? 1 : 0
	setup_hoverState := hover_none
	setup_renderBg()
	setup_renderButtons()
	ahko_setup.Show("w" setup_winW " h" setup_winH " NA")
	SetTimer(setup_hoverTick, 30)
}

ahko_setup_cancel(*) {
	global
	SetTimer(setup_hoverTick, 0)
	ahko_setup.Hide()
}

ahko_setup_save(*) {
	global
	SetTimer(setup_hoverTick, 0)
	if (ahko_setup_check()) {
		hotkeyStr := ""
		if (ahkoSetup_hotkeyWin.Value) {
			hotkeyStr := "#"
		}
		hotkeyStr .= ahkoSetup_hotkey.Value
		IniWrite("path=" ahkoSetup_path.Value, "setting.ini", "dir")
		IniWrite("key=" hotkeyStr, "setting.ini", "hotkey")
		IniWrite("fullscreen=" fullscreen_enable, "setting.ini", "hotkey")
		IniWrite("showat=" showat, "setting.ini", "settings")
		MsgBox("In order for the changes to take effect`nahko is about to be restarted", "OK", "Owner" ahko_setup.Hwnd)
		Reload
	}
}

ahko_setup_check(*) {
	global
	if (!DirExist(ahkoSetup_path.Value)) {
		MsgBox("Invalid watch folder", "Error", "Owner" ahko_setup.Hwnd)
		Return False
	}
	if (RegExReplace(ahkoSetup_hotkey.Value, "#|\^|\!|\+|\<|\>") = "") {
		MsgBox("Invalid hotkey", "Error", "Owner" ahko_setup.Hwnd)
		Return False
	}
	Return true
}

ahko_setup_autostart(b) {
	global
	;@Ahk2Exe-IgnoreBegin
	MsgBox("Only compiled script could be set auto start !", "Error", "Owner" ahko_setup.Hwnd)
	Return
	;@Ahk2Exe-IgnoreEnd
	DirCreate(A_Temp "\ahko_temp")
	FileInstall(".\set_auto_run.ahk", A_Temp "\ahko_temp\set_auto_run.ahk", 1)
	if (b) {
		RunWait('"' A_ScriptFullPath '" /script /force "' A_Temp "\ahko_temp\set_auto_run.ahk" '"' " --name=ahko --target=" A_ScriptFullPath)
	} else {
		RunWait('"' A_ScriptFullPath '" /script /force "' A_Temp "\ahko_temp\set_auto_run.ahk" '"' " --name=ahko --remove")
	}
	try {
		FileDelete(A_Temp "\ahko_temp\startup.exe")
	}
}
autoStartup_update(*) {
	global
	ahko_setup_autostart(ahkoSetup_autoStart.Value)
}
enable_fullscreen_update(*) {
	global
	fullscreen_enable := ahkoSetup_enable_fullscreen.Value
}

setup_hitTest(mx, my) {
	global
	for id, r in setup_btnHitAreas {
		if (mx >= r.x && mx < r.x + r.w && my >= r.y && my < r.y + r.h) {
			return id
		}
	}
	return hover_none
}

setup_hoverTick() {
	global
	if !WinExist("ahk_id " ahko_setup.Hwnd) {
		return
	}
	pt := Buffer(8, 0)
	DllCall("GetCursorPos", "Ptr", pt)
	sx := NumGet(pt, 0, "Int")
	sy := NumGet(pt, 4, "Int")
	WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " ahko_setup.Hwnd)
	mx := sx - wx
	my := sy - wy
	if (mx < 0 || my < 0 || mx >= ww || my >= wh) {
		if (setup_hoverState != hover_none) {
			setup_hoverState := hover_none
			setup_renderButtons()
		}
		return
	}
	newHover := setup_hitTest(mx, my)
	if (newHover != setup_hoverState) {
		setup_hoverState := newHover
		setup_renderButtons()
	}

}

setup_WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
	global
	if (hwnd != ahko_setup.Hwnd) {
		return
	}
	mx := lParam & 0xFFFF
	my := (lParam >> 16) & 0xFFFF
	if (mx > 32767) {
		mx -= 65536
	}
	if (my > 32767) {
		my -= 65536
	}
	if (my < setup_headerH && mx > 0 && mx < setup_winW - 48) {
		PostMessage(0xA1, 2, 0, , "ahk_id " ahko_setup.Hwnd)
	}
}
