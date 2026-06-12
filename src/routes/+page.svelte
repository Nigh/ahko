<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { listen } from "@tauri-apps/api/event";
  import { getCurrentWindow } from "@tauri-apps/api/window";
  import { defaultCustomOpeners } from "$lib/default-openers";
  import { onMount } from "svelte";

  type CustomOpener = { extensions: string[]; program: string; args: string[] };
  type AppConfig = {
    watch_folder: string;
    toggle_hotkey: string;
    back_hotkey: string;
    hide_hotkey: string;
    show_at: string;
    enable_in_fullscreen: boolean;
    autostart: boolean;
    custom_openers: CustomOpener[];
  };
  type LauncherItem = { name: string; key: string; path: string; is_dir: boolean; icon?: string | null; children: LauncherItem[] };

  /** Horizontal padding on `main` (`p-2` = 8px each side). Panel width must satisfy panelW + padX <= innerWidth. */
  const padX = 16;

  /** Compact path row height (one cell wide, shorter than launcher tiles). */
  const PATH_BAR_H = 28;

  /** 4×4 slot matrix (16 keys); matches backend `ITEM_KEYS` set. */
  const SLOT_ROWS: string[][] = [
    ["1", "2", "3", "4"],
    ["q", "w", "e", "r"],
    ["a", "s", "d", "f"],
    ["z", "x", "c", "v"],
  ];

  function launcherHeightPx() {
    const sh = window.screen?.height ?? 1080;
    const inner = window.innerHeight;
    return Math.min(Math.round(sh * 0.6), Math.max(220, inner - 16));
  }

  let launcherH = $state(400);
  let viewportW = $state(2000);

  let gapPx = $derived(Math.max(6, Math.min(16, Math.round(launcherH * 0.018))));
  /** Height available for the 4 launcher tile rows (below path row). */
  let gridViewportH = $derived(Math.max(160, launcherH - PATH_BAR_H - gapPx));
  /** Panel width = 5.5*cell + 4.5*gap; cap cell so panel + padX fits viewport. */
  let cellPx = $derived.by(() => {
    const g = Math.max(6, Math.min(16, Math.round(launcherH * 0.018)));
    const fromHeight = (gridViewportH - 3 * g) / 4;
    const avail = Math.max(0, viewportW - padX);
    const fromWidth = (avail - 4.5 * g) / 5.5;
    return Math.max(40, Math.min(fromHeight, fromWidth));
  });
  let rowStaggerPx = $derived((cellPx + gapPx) / 2);
  let rowWidthPx = $derived(4 * cellPx + 3 * gapPx);
  let panelWidthPx = $derived(Math.ceil(3 * rowStaggerPx + rowWidthPx));
  let hasBeenFocused = $state(false);

  function syncLauncherSize() {
    launcherH = launcherHeightPx();
    viewportW = window.innerWidth;
  }

  let config = $state<AppConfig>({
    watch_folder: "",
    toggle_hotkey: "Alt+Q",
    back_hotkey: "`",
    hide_hotkey: "Esc",
    show_at: "mouse",
    enable_in_fullscreen: false,
    autostart: false,
    custom_openers: defaultCustomOpeners(),
  });
  let items = $state<LauncherItem[]>([]);
  let current = $state<LauncherItem[] | null>(null);
  /** Folder name when `current` is set (single-level drill; matches `goBack`). */
  let currentFolderName = $state<string | null>(null);

  const visibleItems = $derived(current ?? items);

  const pathBadge = $derived(currentFolderName ?? "root");

  /** Emoji / icon row: ~60% of tile height. */
  let iconFontPx = $derived(Math.round(Math.max(14, cellPx * 0.6)));

  /** Title: auto size for two clamped lines in remaining tile height. */
  let titleFontPx = $derived(Math.round(Math.max(10, Math.min(15.5, cellPx * 0.125))));

  const itemByKey = $derived.by(() => {
    const m = new Map<string, LauncherItem>();
    for (const it of visibleItems) m.set(it.key, it);
    return m;
  });

  async function refresh() {
    items = await invoke("scan_launcher", { config });
    current = null;
    currentFolderName = null;
  }

  async function load() {
    config = await invoke("load_config");
    await refresh();
    return config;
  }

  async function activate(item: LauncherItem) {
    if (item.is_dir && item.children.length) {
      current = item.children;
      currentFolderName = item.name;
      return;
    }
    await invoke("launch_item", { config, path: item.path });
    await invoke("hide_window");
  }

  function goBack() {
    if (current) {
      current = null;
      currentFolderName = null;
    }
  }

  async function hide() {
    await invoke("hide_window");
  }

  async function openSetup() {
    await invoke("open_setup_window");
  }

  /** Same outcome as window blur: leave submenu and hide launcher. */
  async function dismissLikeBlur() {
    current = null;
    currentFolderName = null;
    await hide();
  }

  function onMainPointerDown(e: PointerEvent) {
    const t = e.target;
    if (!(t instanceof Element)) return;
    const panel = (e.currentTarget as HTMLElement).querySelector(".launcher-panel");
    if (!panel?.contains(t)) {
      e.preventDefault();
      void dismissLikeBlur();
      return;
    }
    // Click inside panel — do not dismiss (empty slots are part of the panel)
  }

  function keyMatch(event: KeyboardEvent, hotkey: string) {
    const key = event.key === "Escape" ? "Esc" : event.key;
    return key.toLowerCase() === hotkey.toLowerCase();
  }

  function onKey(event: KeyboardEvent) {
    const k = event.key.toLowerCase();
    const item = visibleItems.find((x) => x.key === k);
    if (item) {
      event.preventDefault();
      void activate(item);
    } else if (keyMatch(event, config.back_hotkey)) {
      event.preventDefault();
      goBack();
    } else if (keyMatch(event, config.hide_hotkey)) {
      event.preventDefault();
      void hide();
    }
  }

  onMount(() => {
    syncLauncherSize();

    void (async () => {
      const c = await load();
      if (!c.watch_folder) {
        await invoke("open_setup_window");
      }
    })();

    const unsubs: (() => void)[] = [];
    void listen("config-changed", () => {
      void load();
    }).then((u) => unsubs.push(u));
    void listen("reload-request", () => {
      void load();
    }).then((u) => unsubs.push(u));
    void listen("show-request", () => {
      window.focus();
      setTimeout(() => window.focus(), 500);
    }).then((u) => unsubs.push(u));

    void getCurrentWindow()
      .onFocusChanged(({ payload: focused }) => {
        if (focused) {
          hasBeenFocused = true;
          return;
        }
        if (hasBeenFocused) {
          current = null;
          currentFolderName = null;
          void hide();
        }
      })
      .then((u) => unsubs.push(u));

    window.addEventListener("keydown", onKey);
    window.addEventListener("resize", syncLauncherSize);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("resize", syncLauncherSize);
      for (const u of unsubs) u();
    };
  });
</script>

<main
  class="m-0 box-border flex h-[100dvh] min-h-[100dvh] w-full max-h-[100dvh] max-w-[100dvw] select-none items-center justify-center overflow-hidden bg-transparent p-2 text-base-content"
  style="box-sizing: border-box;"
  onpointerdown={onMainPointerDown}
>
  <div
    class="launcher-panel isolate flex max-h-full max-w-full shrink-0 flex-col justify-center box-border [contain:paint]"
    style={`height: ${launcherH}px; width: ${panelWidthPx}px; gap: ${gapPx}px;`}
  >
    <div
      class="flex shrink-0 flex-row"
      style={`margin-left: 0px; width: ${rowWidthPx}px; height: ${PATH_BAR_H}px; gap: ${gapPx}px;`}
    >
      <div
        class="relative box-border flex min-w-0 shrink-0 items-center justify-center overflow-hidden rounded-lg border-2 border-base-300 bg-base-200 px-1.5 font-mono font-medium leading-none tracking-tight text-base-content/60"
        style={`width: ${cellPx}px; height: ${PATH_BAR_H}px; font-size: ${titleFontPx}px;`}
        aria-live="polite"
        title={pathBadge}
      >
        <span class="truncate">{pathBadge}</span>
      </div>
      <button
        type="button"
        class="relative box-border flex shrink-0 items-center justify-center overflow-hidden rounded-lg border-2 border-primary bg-base-100 font-semibold leading-none text-primary outline-none transition-colors duration-150 ease-out hover:border-primary hover:bg-primary/80 hover:text-primary-content hover:ring-2 hover:ring-inset hover:ring-primary active:bg-base-100"
        style={`width: ${cellPx}px; height: ${PATH_BAR_H}px; font-size: ${titleFontPx}px;`}
        onclick={() => openSetup()}
      >
        Setup
      </button>
    </div>
    {#each SLOT_ROWS as row, ri}
      <div
        class="flex shrink-0 flex-row"
        style={`margin-left: ${(ri * rowStaggerPx).toFixed(2)}px; width: ${rowWidthPx}px; height: ${cellPx}px; gap: ${gapPx}px;`}
      >
        {#each row as slotKey}
          {@const item = itemByKey.get(slotKey)}
          {#if item}
            <button
              type="button"
              class="relative box-border flex min-h-0 min-w-0 shrink-0 flex-col overflow-hidden rounded-2xl border-2 border-primary bg-base-100 text-base-content outline-none transition-colors duration-150 ease-out hover:border-primary hover:bg-primary/80 hover:text-primary-content hover:ring-2 hover:ring-inset hover:ring-primary active:bg-base-100"
              style={`width: ${cellPx}px; height: ${cellPx}px;`}
              onclick={() => activate(item)}
            >
              <span
                class="pointer-events-none absolute left-1.5 top-1.5 z-10 inline-flex h-6 min-w-6 items-center justify-center rounded border-2 border-primary bg-base-200 px-1 font-black uppercase leading-none text-primary"
                style={`font-size: ${titleFontPx}px;`}
                >{item.key}</span
              >
              <div class="absolute inset-x-0 bottom-0 flex flex-col items-center pb-1.5" style="top: 28px;">
                <span class="leading-none" style={`font-size: ${iconFontPx}px`}>{item.icon ? "🖼️" : item.is_dir ? "📁" : "🚀"}</span>
                <span
                  class="mt-0.5 line-clamp-2 w-full text-center font-semibold leading-snug px-1.5"
                  style={`font-size: ${titleFontPx}px`}
                  >{item.name}</span
                >
              </div>
            </button>
          {:else}
            <div
              class="relative box-border flex shrink-0 flex-col overflow-hidden rounded-2xl border-2 border-base-300 bg-base-200"
              style={`width: ${cellPx}px; height: ${cellPx}px;`}
              aria-hidden="true"
            >
              <span
                class="pointer-events-none absolute left-1.5 top-1.5 inline-flex h-6 min-w-6 items-center justify-center rounded border-2 border-base-300 bg-base-200 px-1 font-black uppercase leading-none text-base-content/40"
                style={`font-size: ${titleFontPx}px;`}
                >{slotKey}</span
              >
            </div>
          {/if}
        {/each}
      </div>
    {/each}
  </div>
</main>
