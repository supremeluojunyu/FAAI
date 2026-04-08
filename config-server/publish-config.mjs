import fs from "node:fs/promises";

const source = new URL("./public/app-config.json", import.meta.url);
const target = new URL("./public/current.json", import.meta.url);

const content = await fs.readFile(source, "utf-8");
await fs.writeFile(target, content);
console.log("config published:", target.pathname);
