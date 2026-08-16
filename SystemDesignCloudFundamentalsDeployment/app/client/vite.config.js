// Vite config.
//   * `/api/*` is proxied to the Express backend in dev, so client code
//     calls "/api/users" and doesn't have to know about ports/CORS.
//   * `build.outDir` is the default (dist/); the root package.json copies
//     dist/ to server/public/ during `npm run build` / `postinstall`.

import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": "http://localhost:3000",
    },
  },
});
