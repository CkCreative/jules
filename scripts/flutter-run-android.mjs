#!/usr/bin/env node
import { readFlutterDevices, runFlutterOnDevice, parseCliArgs } from "./flutter-run-common.mjs";

const args = parseCliArgs(process.argv.slice(2));
const devices = readFlutterDevices();
const android = devices.find(d => d.targetPlatform?.toLowerCase().includes("android"));

if (!android) {
  console.error("No Android device or emulator found.");
  process.exit(1);
}

console.log(`Using Android device: ${android.name}`);
runFlutterOnDevice(android, args.flutterArgs, args.dryRun);
