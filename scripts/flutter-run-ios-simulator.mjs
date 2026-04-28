#!/usr/bin/env node
import { readFlutterDevices, runFlutterOnDevice, parseCliArgs } from "./flutter-run-common.mjs";

const args = parseCliArgs(process.argv.slice(2));
const devices = readFlutterDevices();
const simulator = devices.find(d => d.targetPlatform === "ios" && d.emulator);

if (!simulator) {
  console.error("No iOS Simulator found.");
  process.exit(1);
}

console.log(`Using iOS Simulator: ${simulator.name}`);
runFlutterOnDevice(simulator, args.flutterArgs, args.dryRun);
