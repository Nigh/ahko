# Fix Setup GUI: title font, hotkey text, close button shape, hover effects

## Problems

1. **Section title font too small** — "Watch Folder", "Hotkey", "Display Location", "Other" use `s14` GDI+ text, visually too small on the dark panel.
2. **Hotkey result text not prominent** — `ahkoSetup_hotkeyText` is `s10 w600` on a `+BackgroundTrans` Text control with `c89B4FA`. Low contrast and small.
3. **Close button should be square** — Currently drawn with `radius=16` (fully rounded circle). Needs square shape with small radius (e.g. 4).
4. **Hover effects broken** — `setup_WM_MOUSEMOVE` never fires when mouse is over child controls (Edit, Hotkey, DDL, CheckBox, Picture). Windows sends `WM_MOUSEMOVE` to the child control under the cursor, not the parent GUI. The `OnMessage(0x0200, ...)` handler is bypassed entirely.

## Solution

### Fix 1: Section title font size
- Change `s14` to `s16` in all section title `Gdip_TextToGraphics` calls in `setup_renderBg()` (lines 202, 211, 227, 236)
- Increase the label height allocation from 24 to 28 in the GDI+ draw calls
- Adjust `setup_posY_*` spacing if needed to prevent overlap

### Fix 2: Hotkey result text
- Change `ahkoSetup_hotkeyText` from `s10 w600` to `s13 w700` (line 87)
- Increase height from 22 to 26
- Use brighter accent color `clrAccentHover` (0xFFB4D0FB) instead of `c89B4FA` for more visibility

### Fix 3: Close button square shape
- In `setup_renderButtons()` line 168: change `setup_makeBtnBitmap(32, 32, "X", closeBg, closeTxtColor, 13, 16)` — change `16` (radius) to `4`

### Fix 4: Hover via timer (replacing broken WM_MOUSEMOVE)
The root cause: child controls (Edit, Hotkey, DDL, CheckBox, Picture) intercept `WM_MOUSEMOVE` before the parent GUI sees it. The `OnMessage(0x0200, ...)` handler never fires when mouse is over any child.

**Fix:** Replace `OnMessage(0x0200, ...)` with a `SetTimer` that polls mouse position every 30ms using `GetCursorPos` + `WindowFromPoint`. This is the same pattern used by `ahko_gridview_ui.ahk` for its misfire detection (line 363-366).

Changes:
- Remove `OnMessage(0x0200, setup_WM_MOUSEMOVE)` and `OnMessage(0x02A3, setup_WM_MOUSELEAVE)`
- Remove `setup_WM_MOUSEMOVE` and `setup_WM_MOUSELEAVE` functions
- Remove `setup_trackMouseEvent` function
- Add `setup_hoverTimer` — a `SetTimer` callback that:
  1. Gets cursor screen pos via `GetCursorPos`
  2. Gets window pos via `WinGetPos`
  3. Converts to client coords
  4. Calls `setup_hitTest(mx, my)`
  5. If hover state changed, calls `setup_renderButtons()` and updates cursor
  6. If cursor left the window entirely, resets to `hover_none`
- Start timer in `ahko_setup_show()`, stop in `ahko_setup_cancel()` / `ahko_setup_save()`
- Keep `OnMessage(0x0201, setup_WM_LBUTTONDOWN)` for drag (this one works because it's handled before child controls)

## Files to modify
- `ahko_setup_gui.ahk` — all 4 fixes in this single file

## Verification
- Run `AutoHotkey64.exe app.ahk`, trigger setup via tray
- Verify section titles are clearly readable at `s16`
- Verify hotkey result text is large and bright
- Verify close button is square
- Verify hover effects work on Select, Save, Cancel, Close buttons
- Verify drag still works on title bar
- Verify all native controls still function (Edit, Hotkey, DDL, CheckBox)
