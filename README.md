# rusto

`rusto` is a cross-platform quick launcher for Windows and Ubuntu, rebuilt from the original AHK `ahko` reference with Rust + Tauri v2 + Svelte + Tailwind CSS.

## Development

```bash
npm install
npm run check
npm run build
npm run tauri dev
```

On Windows, ensure the Rust toolchain managed by rustup is earlier in `PATH` than any Chocolatey/system Rust installation, for example `C:\Users\xiany\.cargo\bin` before `C:\ProgramData\chocolatey\bin`.
