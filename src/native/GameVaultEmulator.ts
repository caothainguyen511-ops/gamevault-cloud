import { registerPlugin } from "@capacitor/core";

export interface GameVaultEmulatorCapabilities {
  androidApi: number;
  supportedAbi: string;
  runtimeInstalled: boolean;
  wineAvailable: boolean;
  box64Available: boolean;
  box86Available: boolean;
  graphicsBackendAvailable: boolean;
  canLaunchExe: boolean;
  prefixReady: boolean;
  status: string;
  message: string;
}
export interface PrefixResult { ready: boolean; path: string; message: string; }
interface GameVaultEmulatorPlugin {
  getCapabilities(): Promise<GameVaultEmulatorCapabilities>;
  initializePrefix(): Promise<PrefixResult>;
  launchExe(options: { uri: string }): Promise<void>;
}
export const GameVaultEmulator =
  registerPlugin<GameVaultEmulatorPlugin>("GameVaultEmulator");
