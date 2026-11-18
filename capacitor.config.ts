import type { CapacitorConfig } from "@capacitor/cli";
const config: CapacitorConfig = {
  appId: "com.gamevault.cloud",
  appName: "GameVault Cloud",
  webDir: "dist",
  android: { allowMixedContent: false }
};
export default config;