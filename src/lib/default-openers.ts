/** Mirrors Rust `AppConfig::default` custom_openers. */
export type CustomOpener = { extensions: string[]; program: string; args: string[] };

export function defaultCustomOpeners(): CustomOpener[] {
  return [{ extensions: ["py", "pyw"], program: "python3", args: ["{file}"] }];
}
