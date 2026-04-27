<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { onMount } from "svelte";

  type CustomOpener = { extensions: string[]; program: string; args: string[] };
  type AppConfig = { watch_folder: string; toggle_hotkey: string; back_hotkey: string; hide_hotkey: string; show_at: string; enable_in_fullscreen: boolean; autostart: boolean; custom_openers: CustomOpener[] };
  type LauncherItem = { name: string; key: string; path: string; is_dir: boolean; icon?: string | null; children: LauncherItem[] };

  const positions: Record<string, string> = { "1": "col-start-1 row-start-1", "2": "col-start-2 row-start-1", "3": "col-start-3 row-start-1", "4": "col-start-4 row-start-1", q: "col-start-1 row-start-2 ml-10", w: "col-start-2 row-start-2 ml-10", e: "col-start-3 row-start-2 ml-10", r: "col-start-4 row-start-2 ml-10", a: "col-start-2 row-start-3", s: "col-start-3 row-start-3", d: "col-start-4 row-start-3", f: "col-start-5 row-start-3", z: "col-start-2 row-start-4 ml-10", x: "col-start-3 row-start-4 ml-10", c: "col-start-4 row-start-4 ml-10", v: "col-start-5 row-start-4 ml-10" };
  let config = $state<AppConfig>({ watch_folder: "", toggle_hotkey: "Alt+Q", back_hotkey: "`", hide_hotkey: "Esc", show_at: "mouse", enable_in_fullscreen: false, autostart: false, custom_openers: [{ extensions: ["py", "pyw"], program: "python3", args: ["{file}"] }] });
  let items = $state<LauncherItem[]>([]);
  let current = $state<LauncherItem[] | null>(null);
  let title = $state("ahko+");
  let settingsOpen = $state(false);
  let message = $state("");

  const visibleItems = $derived(current ?? items);
  async function refresh() { items = await invoke("scan_launcher", { config }); current = null; title = "ahko+"; }
  async function load() { config = await invoke("load_config"); await refresh(); if (!config.watch_folder) settingsOpen = true; }
  async function save() { await invoke("save_config", { config }); message = "Saved"; await refresh(); }
  async function activate(item: LauncherItem) { if (item.is_dir && item.children.length) { current = item.children; title = item.name; return; } await invoke("launch_item", { config, path: item.path }); await invoke("hide_window"); }
  function goBack() { if (current) { current = null; title = "ahko+"; } }
  async function hide() { await invoke("hide_window"); }
  function addOpener() { config.custom_openers = [...config.custom_openers, { extensions: [], program: "", args: ["{file}"] }]; }
  function removeOpener(i: number) { config.custom_openers = config.custom_openers.filter((_, idx) => idx !== i); }
  function keyMatch(event: KeyboardEvent, hotkey: string) { const key = event.key === "Escape" ? "Esc" : event.key; return key.toLowerCase() === hotkey.toLowerCase(); }
  function onKey(event: KeyboardEvent) { const k = event.key.toLowerCase(); const item = visibleItems.find((x) => x.key === k); if (item) { event.preventDefault(); activate(item); } else if (keyMatch(event, config.back_hotkey)) { event.preventDefault(); goBack(); } else if (keyMatch(event, config.hide_hotkey)) { event.preventDefault(); hide(); } }
  onMount(() => { load(); window.addEventListener("keydown", onKey); return () => window.removeEventListener("keydown", onKey); });
</script>

<main class="min-h-screen bg-slate-950 p-6 text-slate-100">
  <div class="mx-auto flex max-w-5xl gap-6">
    <section class="flex-1 rounded-3xl border border-white/10 bg-white/10 p-6 shadow-2xl backdrop-blur">
      <div class="mb-5 flex items-center justify-between">
        <div><h1 class="text-3xl font-black tracking-tight">{title}</h1><p class="text-sm text-slate-400">16-key staggered launcher · {config.toggle_hotkey} to show via system shortcut command</p></div>
        <div class="flex gap-2"><button class="rounded-xl bg-cyan-500 px-4 py-2 font-bold text-slate-950" onclick={() => (settingsOpen = !settingsOpen)}>Setup</button><button class="rounded-xl bg-white/10 px-4 py-2" onclick={refresh}>Reload</button></div>
      </div>
      {#if !config.watch_folder}<div class="rounded-2xl border border-amber-400/40 bg-amber-400/10 p-4 text-amber-100">Please set a watch folder first.</div>{/if}
      <div class="grid grid-cols-5 grid-rows-4 gap-4">
        {#each visibleItems as item (item.path)}
          <button class={`group h-32 w-32 rounded-3xl border border-white/10 bg-slate-900/90 p-4 text-left shadow-xl transition hover:-translate-y-1 hover:border-cyan-300 ${positions[item.key] ?? ""}`} onclick={() => activate(item)}>
            <div class="mb-2 inline-flex h-7 min-w-7 items-center justify-center rounded-lg bg-cyan-400 px-2 text-sm font-black uppercase text-slate-950">{item.key}</div>
            <div class="text-4xl">{item.icon ? "🖼️" : item.is_dir ? "📁" : "🚀"}</div>
            <div class="mt-2 truncate font-bold">{item.name}</div>
            <div class="truncate text-xs text-slate-500">{item.is_dir ? `${item.children.length} items` : item.path}</div>
          </button>
        {/each}
      </div>
      <div class="mt-5 flex gap-3 text-sm text-slate-400"><span>{config.back_hotkey}: back</span><span>{config.hide_hotkey}: hide</span></div>
    </section>

    {#if settingsOpen}
      <aside class="w-96 rounded-3xl border border-white/10 bg-slate-900 p-5 shadow-2xl">
        <h2 class="mb-4 text-2xl font-black">Setup</h2>
        <label class="text-sm text-slate-400" for="watch-folder">Watch folder</label><input id="watch-folder" class="mb-3 mt-1 w-full rounded-xl bg-slate-800 p-3" bind:value={config.watch_folder} placeholder="C:\\Apps or /home/me/apps" />
        <div class="grid grid-cols-3 gap-2"><label class="text-sm text-slate-400">Show<input class="mt-1 w-full rounded-xl bg-slate-800 p-2 text-white" bind:value={config.toggle_hotkey} /></label><label class="text-sm text-slate-400">Back<input class="mt-1 w-full rounded-xl bg-slate-800 p-2 text-white" bind:value={config.back_hotkey} /></label><label class="text-sm text-slate-400">Hide<input class="mt-1 w-full rounded-xl bg-slate-800 p-2 text-white" bind:value={config.hide_hotkey} /></label></div>
        <p class="my-3 rounded-xl bg-slate-800 p-3 text-xs text-slate-400">Wayland: bind your system shortcut to launch/toggle this app manually. In-window Back/Hide keys are configurable here.</p>
        <label class="flex items-center gap-2 text-sm"><input type="checkbox" bind:checked={config.enable_in_fullscreen} /> Enable in fullscreen (reserved)</label>
        <label class="mt-2 flex items-center gap-2 text-sm"><input type="checkbox" bind:checked={config.autostart} /> Autostart (reserved)</label>
        <div class="mt-5 flex items-center justify-between"><h3 class="font-bold">Custom openers</h3><button class="rounded-lg bg-white/10 px-3 py-1" onclick={addOpener}>Add</button></div>
        {#each config.custom_openers as opener, i}
          <div class="mt-3 rounded-2xl bg-slate-800 p-3"><input class="mb-2 w-full rounded-lg bg-slate-700 p-2" placeholder="extensions: py,pyw" value={opener.extensions.join(",")} oninput={(e) => (opener.extensions = e.currentTarget.value.split(",").map((x) => x.trim()).filter(Boolean))} /><input class="mb-2 w-full rounded-lg bg-slate-700 p-2" placeholder="program" bind:value={opener.program} /><input class="w-full rounded-lg bg-slate-700 p-2" placeholder="args placeholder" value={opener.args.join(" ")} oninput={(e) => (opener.args = e.currentTarget.value.split(" ").filter(Boolean))} /><button class="mt-2 text-sm text-red-300" onclick={() => removeOpener(i)}>Remove</button></div>
        {/each}
        <button class="mt-5 w-full rounded-xl bg-cyan-400 py-3 font-black text-slate-950" onclick={save}>Save</button><p class="mt-2 text-center text-sm text-cyan-300">{message}</p>
      </aside>
    {/if}
  </div>
</main>
