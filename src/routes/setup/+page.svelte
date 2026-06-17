<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { listen } from "@tauri-apps/api/event";
  import { getCurrentWindow } from "@tauri-apps/api/window";
  import { defaultCustomOpeners } from "$lib/default-openers";
  import { onMount } from "svelte";

  type CustomOpener = { extensions: string[]; program: string; args: string[] };
  type MonitorInfo = {
    id: string;
    name: string;
    is_primary: boolean;
    width: number;
    height: number;
    x: number;
    y: number;
  };
  type PlatformCapabilities = {
    session_type: string;
    desktop: string;
    launcher_screen_supported: boolean;
    launcher_screen_note: string;
  };
  type AppConfig = {
    watch_folder: string;
    toggle_hotkey: string;
    back_hotkey: string;
    hide_hotkey: string;
    show_at: string;
    show_monitor_id: string;
    enable_in_fullscreen: boolean;
    autostart: boolean;
    custom_openers: CustomOpener[];
  };

  let config = $state<AppConfig>({
    watch_folder: "",
    toggle_hotkey: "Alt+Q",
    back_hotkey: "`",
    hide_hotkey: "Esc",
    show_at: "mouse",
    show_monitor_id: "",
    enable_in_fullscreen: false,
    autostart: false,
    custom_openers: defaultCustomOpeners(),
  });
  let monitors = $state<MonitorInfo[]>([]);
  let platform = $state<PlatformCapabilities | null>(null);

  const isLinux =
    (import.meta as ImportMeta & { env?: { TAURI_ENV_PLATFORM?: string } }).env?.TAURI_ENV_PLATFORM ===
    "linux";

  async function load() {
    config = await invoke("load_config");
  }
  async function save() {
    try {
      await invoke("save_config", { config });
      await closeWindow();
    } catch (e) {
      alert(String(e));
    }
  }
  async function closeWindow() {
    await getCurrentWindow().close();
  }
  function onTitleBarPointerDown(e: PointerEvent) {
    if (e.button !== 0) return;
    const t = e.target;
    if (t instanceof Element && t.closest("button")) return;
    void getCurrentWindow().startDragging();
  }
  function addOpener() {
    config.custom_openers = [...config.custom_openers, { extensions: [], program: "", args: ["{file}"] }];
  }
  function removeOpener(i: number) {
    config.custom_openers = config.custom_openers.filter((_, idx) => idx !== i);
  }
  function monitorLabel(m: MonitorInfo) {
    const tag = m.is_primary ? " (primary)" : "";
    return `${m.name}${tag}`;
  }
  function ensureFixedMonitor() {
    if (config.show_at !== "fixed" || config.show_monitor_id || monitors.length === 0) return;
    const primary = monitors.find((m) => m.is_primary) ?? monitors[0];
    config = { ...config, show_monitor_id: primary.id };
  }
  async function refreshMonitors() {
    monitors = await invoke("list_monitors");
    if (
      config.show_at === "fixed" &&
      config.show_monitor_id &&
      !monitors.some((m) => m.id === config.show_monitor_id)
    ) {
      config = { ...config, show_monitor_id: "" };
    }
    ensureFixedMonitor();
  }
  onMount(() => {
    void (async () => {
      platform = await invoke("get_platform_capabilities");
      await load();
      await refreshMonitors();
    })();
    const unsubs: (() => void)[] = [];
    void listen<MonitorInfo[]>("monitors-changed", (event) => {
      monitors = event.payload;
      if (
        config.show_at === "fixed" &&
        config.show_monitor_id &&
        !monitors.some((m) => m.id === config.show_monitor_id)
      ) {
        config = { ...config, show_monitor_id: "" };
      }
      ensureFixedMonitor();
    }).then((u) => unsubs.push(u));
    return () => {
      for (const u of unsubs) u();
    };
  });
</script>

<main
  class="box-border flex h-[100dvh] flex-col overflow-hidden rounded-lg border-2 border-primary/25 bg-base-100 text-base-content scheme-dark"
>
  <div class="flex shrink-0 items-center border-b border-base-300/70">
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div
      class="flex min-w-0 flex-1 cursor-grab items-center px-5 py-3 active:cursor-grabbing"
      onpointerdown={onTitleBarPointerDown}
    >
      <h1 class="text-xl font-black text-base-content">Setup</h1>
    </div>
    <button
      type="button"
      class="mr-5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md border border-base-300 bg-base-200 text-base-content/70 transition-colors hover:border-primary/50 hover:bg-base-300 hover:text-base-content"
      aria-label="Close"
      onclick={() => closeWindow()}
    >
      ×
    </button>
  </div>

  <div class="min-h-0 flex-1 overflow-y-auto overscroll-contain px-5 pt-4 pb-4">
    <label class="text-sm text-base-content/50" for="watch-folder">Watch folder</label>
    <input
      id="watch-folder"
      class="mb-3 mt-1 w-full rounded-lg border border-base-300/80 bg-base-100/90 p-3 text-base-content outline-none transition-colors focus:border-primary/50"
      bind:value={config.watch_folder}
      placeholder="C:\Apps or /home/me/apps"
    />
    <fieldset class="mb-3 rounded-lg border border-base-300/70 p-3">
      <legend class="px-1 text-sm text-base-content/50">Launcher screen</legend>
      {#if platform && !platform.launcher_screen_supported}
        <p class="mb-3 rounded-lg border border-warning/40 bg-base-200/80 p-3 text-xs text-base-content/70">
          {platform.launcher_screen_note}
          <span class="mt-1 block text-base-content/50">
            Session: {platform.session_type} · Desktop: {platform.desktop}
          </span>
        </p>
      {/if}
      <div class="space-y-2 text-sm">
        <label class="flex items-center gap-2">
          <input type="radio" bind:group={config.show_at} value="mouse" />
          Follow mouse cursor
        </label>
        <label class="flex items-center gap-2">
          <input type="radio" bind:group={config.show_at} value="focus" />
          Follow focused window
        </label>
        <label class="flex items-center gap-2">
          <input type="radio" bind:group={config.show_at} value="fixed" onchange={ensureFixedMonitor} />
          Fixed screen
        </label>
      </div>
      {#if config.show_at === "fixed"}
        <label class="mt-3 block text-sm text-base-content/50" for="show-monitor">Screen</label>
        <select
          id="show-monitor"
          class="mt-1 w-full rounded-lg border border-base-300/80 bg-base-200/80 p-2 text-base-content outline-none transition-colors focus:border-primary/50"
          bind:value={config.show_monitor_id}
        >
          {#if monitors.length === 0}
            <option value="">No screens detected</option>
          {:else}
            {#each monitors as monitor (monitor.id)}
              <option value={monitor.id}>{monitorLabel(monitor)}</option>
            {/each}
          {/if}
        </select>
      {/if}
    </fieldset>
    <div class={`grid gap-2 ${isLinux ? "grid-cols-2" : "grid-cols-3"}`}>
      {#if !isLinux}
        <label class="text-sm text-base-content/50"
          >Show<input
            class="mt-1 w-full rounded-lg border border-base-300/80 bg-base-100/90 p-2 text-base-content outline-none focus:border-primary/50"
            bind:value={config.toggle_hotkey}
          /></label
        >
      {/if}
      <label class="text-sm text-base-content/50"
        >Back<input
          class="mt-1 w-full rounded-lg border border-base-300/80 bg-base-100/90 p-2 text-base-content outline-none focus:border-primary/50"
          bind:value={config.back_hotkey}
        /></label
      >
      <label class="text-sm text-base-content/50"
        >Hide<input
          class="mt-1 w-full rounded-lg border border-base-300/80 bg-base-100/90 p-2 text-base-content outline-none focus:border-primary/50"
          bind:value={config.hide_hotkey}
        /></label
      >
    </div>
    <p class="my-3 rounded-lg border border-base-300 bg-base-200/80 p-3 text-xs text-base-content/50">
      {#if isLinux}
        Linux: wake the launcher with a <strong class="text-base-content/70">desktop shortcut</strong> or
        <strong class="text-base-content/70">system keyboard shortcut</strong> (see README). Back / Hide apply while the launcher is
        focused.
      {:else}
        Back and hide keys apply while the launcher is focused. See README for assigning a shortcut to wake or focus the app on
        Windows.
      {/if}
    </p>
    <label class="flex items-center gap-2 text-sm"
      ><input type="checkbox" bind:checked={config.enable_in_fullscreen} /> Enable in fullscreen (reserved)</label
    >
    <label class="mt-2 flex items-center gap-2 text-sm"
      ><input type="checkbox" bind:checked={config.autostart} /> Autostart (reserved)</label
    >

    <section class="mt-5">
      <div class="flex items-center justify-between">
        <h2 class="font-bold text-base-content">Custom openers</h2>
        <button
          class="rounded-md border border-primary/40 bg-base-100 px-3 py-1 text-sm text-primary transition-colors hover:border-primary/60 hover:bg-base-300"
          onclick={addOpener}>Add</button
        >
      </div>
      <p class="mt-2 text-xs text-base-content/50">
        On Linux, <code class="rounded border border-base-300 bg-base-100 px-1 text-base-content/70">.AppImage</code> files launch by
        <strong>direct spawn</strong> when no row here matches their extension. Add a custom opener only if you need a different
        command or wrapper.
      </p>
      <div class="mt-3 space-y-3">
        {#each config.custom_openers as opener, i}
          <div class="rounded-lg border border-base-300/70 bg-base-100/60 p-3">
            <input
              class="mb-2 w-full rounded-md border border-base-300/80 bg-base-200/80 p-2 text-base-content outline-none focus:border-primary/45"
              placeholder="extensions: py,pyw"
              value={opener.extensions.join(",")}
              oninput={(e) =>
                (opener.extensions = e.currentTarget.value
                  .split(",")
                  .map((x) => x.trim())
                  .filter(Boolean))}
            />
            <input
              class="mb-2 w-full rounded-md border border-base-300/80 bg-base-200/80 p-2 text-base-content outline-none focus:border-primary/45"
              placeholder="program"
              bind:value={opener.program}
            />
            <input
              class="w-full rounded-md border border-base-300/80 bg-base-200/80 p-2 text-base-content outline-none focus:border-primary/45"
              placeholder="args"
              value={opener.args.join(" ")}
              oninput={(e) => (opener.args = e.currentTarget.value.split(" ").filter(Boolean))}
            />
            <button
              class="mt-2 text-sm text-primary/90 transition-colors hover:text-primary"
              onclick={() => removeOpener(i)}>Remove</button
            >
          </div>
        {/each}
      </div>
    </section>
  </div>

  <div
    class="relative z-20 shrink-0 border-t border-base-300/70 bg-base-100 px-5 py-4 shadow-[0_-12px_24px_oklch(20%_0_0/0.85)]"
  >
    <button
      class="w-full rounded-lg border-2 border-primary/70 bg-primary py-3 font-black text-primary-content transition-colors hover:border-primary hover:bg-primary/90"
      onclick={save}>Save</button
    >
  </div>
</main>
