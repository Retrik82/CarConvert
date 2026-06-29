import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import fs from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const presetBackgroundsRoot = resolve(__dirname, "../mobile/assets/backgrounds/presets");
const presetMount = "/backgrounds/presets";

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = join(src, entry.name);
    const to = join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(from, to);
    } else {
      fs.copyFileSync(from, to);
    }
  }
}

/** Serve canonical preset JPEGs from mobile/assets in dev and copy into dist on build. */
function presetBackgroundsPlugin() {
  return {
    name: "preset-backgrounds",
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url?.startsWith(presetMount)) return next();

        const rel = decodeURIComponent(req.url.slice(presetMount.length).replace(/^\//, ""));
        const filePath = resolve(presetBackgroundsRoot, rel);
        if (!filePath.startsWith(presetBackgroundsRoot) || !fs.existsSync(filePath)) {
          return next();
        }

        res.setHeader("Content-Type", "image/jpeg");
        res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
        fs.createReadStream(filePath).pipe(res);
      });
    },
    closeBundle() {
      if (!fs.existsSync(presetBackgroundsRoot)) return;
      copyDir(presetBackgroundsRoot, resolve(__dirname, "dist/backgrounds/presets"));
    },
  };
}

export default defineConfig({
  plugins: [react(), presetBackgroundsPlugin()],
});
