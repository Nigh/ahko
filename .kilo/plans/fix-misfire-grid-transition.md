# Fix: Misfire detection false positive on grid transition

## Bug Summary

When clicking a folder button in the main grid to enter a sub-grid, the misfire timer detects the same click as "outside ahko" and closes the window.

## Root Cause

The button click callback (`gui_add_grid_btn` line 222) runs **synchronously** and hides the main grid + shows the sub-grid. The 50ms misfire timer fires **after** this transition. At that point:

1. `GetAsyncKeyState(0x01) & 1` returns true — the mouse was pressed since the last timer call
2. `MouseGetPos` resolves to the window **behind** ahko — the sub-grid's transparent background (`00FF00` + `WinSetTransColor 220`) is click-through
3. `!_isAhkoHwnd(winId)` → true → `_hideAll()` fires — false positive

## Fix Plan

Add a `_skipMisfireCount` counter. Grid transitions set this counter. The timer checks/decrements it first; if > 0, it **consumes `GetAsyncKeyState` flags** (to clear the "was pressed" bit) and returns without acting.

### Critical detail: `GetAsyncKeyState` flag consumption

`GetAsyncKeyState(hWnd) & 1` returns whether the key was pressed **since the last call**. The bit is cleared on call. If we simply `return` during the skip window without calling `GetAsyncKeyState`, the "was pressed" bit from the original click **persists** and triggers a false positive after the skip window ends. The fix must call `GetAsyncKeyState` during the skip to consume the stale flag.

### File: `ahko_gridview_ui.ahk`

1. **Add property declaration** (after line 34):
   ```ahk
   _skipMisfireCount := 0
   ```

2. **Modify `_checkMouseClick`** (line 382) — add skip logic that consumes flags:
   ```ahk
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
   ```

3. **Set skip in `set_gui_default_prop` `uShow` closure** (line 138) — covers all grid show transitions:
   ```ahk
   uShow(*) {
       g.isHide := False
       g.Show(this.gui_showat() " NA")
       this._skipMisfireCount := 2
   }
   ```
   This single change covers: folder-open (`sub_grid.uShow()`), back-to-main (`father_gui.uShow()`), and hotkey-show (`grid_gui.uShow()`).

4. **Set skip in `gui_add_grid_btn` callback** (line 222) — defense-in-depth, set BEFORE the hide:
   ```ahk
   callback(*) {
       this._skipMisfireCount := 2
       guiobj.uHide()
       ; ... rest unchanged
   }
   ```

### Summary of changes

| Location | Change |
|----------|--------|
| Class property (after line 34) | Add `_skipMisfireCount := 0` |
| `_checkMouseClick` (line 382) | Check/decrement `_skipMisfireCount`, consume `GetAsyncKeyState` flags, return early |
| `set_gui_default_prop` `uShow` closure (line 138) | Set `this._skipMisfireCount := 2` after show |
| `gui_add_grid_btn` callback (line 222) | Set `this._skipMisfireCount := 2` before `guiobj.uHide()` |

### Trace: folder button click (main → sub)

1. `Show()` → main grid visible, `_startMisfireDetection()` starts 50ms timer
2. User clicks folder button → `Click` event fires callback
3. Callback: `this._skipMisfireCount := 2`, `guiobj.uHide()`, `sub_grid.uShow()` (also sets `_skipMisfireCount := 2`)
4. Timer tick 1: `_skipMisfireCount = 2 > 0` → decrement to 1, consume `GetAsyncKeyState` flags, return
5. Timer tick 2: `_skipMisfireCount = 1 > 0` → decrement to 0, consume `GetAsyncKeyState` flags, return
6. Timer tick 3: `_skipMisfireCount = 0` → `GetAsyncKeyState(0x01) & 1` → 0 (flags consumed, user released) → no false positive

### Trace: title back button (sub → main)

1. User clicks title button on sub-grid → `uShow` class method fires
2. `this.father_gui.uShow()` → closure sets `_skipMisfireCount := 2`, shows main grid
3. `this.Gui.uHide()` → hides sub-grid
4. Timer ticks: same as above — flags consumed during skip, no false positive

### Why this is safe

- `_skipMisfireCount` only skips mouse-based detection; keyboard InputHook is unaffected
- The skip window (100ms = 2×50ms ticks) is long enough for click release but short enough to not mask real misfires
- `GetAsyncKeyState` is called during skip to consume stale "was pressed" flags
- Setting skip in both `uShow` closure and button callback covers all transition paths
