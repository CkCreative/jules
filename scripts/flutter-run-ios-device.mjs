#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { readFlutterDevices, runFlutterOnDevice, parseCliArgs } from "./flutter-run-common.mjs";

const args = parseCliArgs(process.argv.slice(2));
const devices = readFlutterDevices();
const iphone = devices.find(d => d.targetPlatform === "ios" && !d.emulator);

if (!iphone) {
  console.error("No physical iPhone found. Use 'npm run dev:simulator' for Simulator.");
  process.exit(1);
}

// Basic signing identity check
function getIdentities() {
  const result = spawnSync("security", ["find-certificate", "-a", "-c", "Apple Development", "-p"], { encoding: "utf8" });
  if (result.status !== 0) return [];
  // Simplified extraction of Team ID (OU)
  return result.stdout.match(/OU=([^,]+)/g)?.map(m => m.split('=')[1]) || [];
}

const identities = getIdentities();
const env = {};
if (identities.length > 0) {
  env.FLUTTER_XCODE_DEVELOPMENT_TEAM = identities[0];
  console.log(`Using Development Team: ${identities[0]}`);
}

console.log(`Using iOS device: ${iphone.name}`);
runFlutterOnDevice(iphone, args.flutterArgs, args.dryRun, env);
