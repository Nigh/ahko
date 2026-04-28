<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
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
  let message = $state("");

  /** In-app wake shortcut only applies where global registration exists; Linux uses OS bindings instead. */
  const isLinux =
    (import.meta as ImportMeta & { env?: { TAURI_ENV_PLATFORM?: string } }).env?.TAURI_ENV_PLATFORM ===
    "linux";

  async function load() {
    config = await invoke("load_config");
  }
  async function save() {
    await invoke("save_config", { config });
    message = "Saved";
  }
  function addOpener() {
    config.custom_openers = [...config.custom_openers, { extensions: [], program: "", args: ["{file}"] }];
  }
  function removeOpener(i: number) {
    config.custom_openers = config.custom_openers.filter((_, idx) => idx !== i);
  }
  onMount(() => {
    void load();
  });
</script>

<main class="min-h-screen bg-zinc-950 p-6 text-zinc-200">
  <div
    class="mx-auto max-w-lg rounded-3xl border-2 border-pink-400/25 bg-zinc-900/95 p-6 shadow-2xl shadow-zinc-950/50"
  >
    <h1 class="mb-4 text-2xl font-black text-zinc-100">Setup</h1>
    <label class="text-sm text-zinc-500" for="watch-folder">Watch folder</label>
    <input
      id="watch-folder"
      class="mb-3 mt-1 w-full rounded-xl border border-zinc-700/80 bg-zinc-800/90 p-3 text-zinc-100 outline-none transition-colors focus:border-pink-400/50"
      bind:value={config.watch_folder}
      placeholder="C:\Apps or /home/me/apps"
    />
    <div class={`grid gap-2 ${isLinux ? "grid-cols-2" : "grid-cols-3"}`}>
      {#if !isLinux}
        <label class="text-sm text-zinc-500"
          >Show<input
            class="mt-1 w-full rounded-xl border border-zinc-700/80 bg-zinc-800/90 p-2 text-zinc-100 outline-none focus:border-pink-400/50"
            bind:value={config.toggle_hotkey}
          /></label
        >
      {/if}
      <label class="text-sm text-zinc-500"
        >Back<input
          class="mt-1 w-full rounded-xl border border-zinc-700/80 bg-zinc-800/90 p-2 text-zinc-100 outline-none focus:border-pink-400/50"
          bind:value={config.back_hotkey}
        /></label
      >
      <label class="text-sm text-zinc-500"
        >Hide<input
          class="mt-1 w-full rounded-xl border border-zinc-700/80 bg-zinc-800/90 p-2 text-zinc-100 outline-none focus:border-pink-400/50"
          bind:value={config.hide_hotkey}
        /></label
      >
    </div>
    <p class="my-3 rounded-xl border border-zinc-800 bg-zinc-900/80 p-3 text-xs text-zinc-500">
      {#if isLinux}
        Linux: wake the launcher with a <strong class="text-zinc-400">desktop shortcut</strong> or
        <strong class="text-zinc-400">system keyboard shortcut</strong> (see README). Back / Hide apply while the launcher is
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
    <div class="mt-5 flex items-center justify-between">
      <h2 class="font-bold text-zinc-100">Custom openers</h2>
      <button
        class="rounded-lg border border-pink-400/40 bg-zinc-800 px-3 py-1 text-sm text-pink-200 transition-colors hover:bg-zinc-700 hover:border-pink-300/60"
        onclick={addOpener}>Add</button
      >
    </div>
    <p class="mt-2 text-xs text-zinc-500">
      On Linux, <code class="rounded border border-zinc-700 bg-zinc-800 px-1 text-zinc-400">.AppImage</code> files launch by
      <strong>direct spawn</strong> when no row here matches their extension. Add a custom opener only if you need a different
      command or wrapper.
    </p>
    {#each config.custom_openers as opener, i}
      <div class="mt-3 rounded-2xl border border-zinc-700/70 bg-zinc-800/60 p-3">
        <input
          class="mb-2 w-full rounded-lg border border-zinc-700/80 bg-zinc-900/80 p-2 text-zinc-100 outline-none focus:border-pink-400/45"
          placeholder="extensions: py,pyw"
          value={opener.extensions.join(",")}
          oninput={(e) =>
            (opener.extensions = e.currentTarget.value
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean))}
        />
        <input
          class="mb-2 w-full rounded-lg border border-zinc-700/80 bg-zinc-900/80 p-2 text-zinc-100 outline-none focus:border-pink-400/45"
          placeholder="program"
          bind:value={opener.program}
        />
        <input
          class="w-full rounded-lg border border-zinc-700/80 bg-zinc-900/80 p-2 text-zinc-100 outline-none focus:border-pink-400/45"
          placeholder="args"
          value={opener.args.join(" ")}
          oninput={(e) => (opener.args = e.currentTarget.value.split(" ").filter(Boolean))}
        />
        <button
          class="mt-2 text-sm text-pink-400/90 transition-colors hover:text-pink-300"
          onclick={() => removeOpener(i)}>Remove</button
        >
      </div>
    {/each}
    <button
      class="mt-5 w-full rounded-xl border-2 border-pink-400/70 bg-pink-500 py-3 font-black text-zinc-950 transition-colors hover:border-pink-300 hover:bg-pink-400"
      onclick={save}>Save</button
    >
    <p class="mt-2 text-center text-sm text-pink-300/90">{message}</p>
  </div>
</main>
