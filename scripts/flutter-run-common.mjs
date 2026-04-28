import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));

export const repoDir = path.resolve(scriptDir, "..");
export const flutterDir = path.join(repoDir, "jules_flutter");

export function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: flutterDir,
    stdio: "inherit",
    ...options,
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }

  return result;
}

export function capture(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: flutterDir,
    encoding: "utf8",
    ...options,
  });

  if (result.status !== 0) {
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
    process.exit(result.status ?? 1);
  }

  return result.stdout;
}

export function parseCliArgs(argv) {
  const flutterArgs = [];
  let deviceName = "";
  let dryRun = false;

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--") {
      flutterArgs.push(...argv.slice(index + 1));
      break;
    }
    if (token === "--dry-run") {
      dryRun = true;
      continue;
    }
    if (token === "--device") {
      deviceName = argv[index + 1]?.trim() || "";
      index += 1;
      continue;
    }
    flutterArgs.push(token);
  }

  return { deviceName, dryRun, flutterArgs };
}

export function readFlutterDevices() {
  const raw = capture("flutter", ["devices", "--machine"]);
  return JSON.parse(raw);
}

export function runFlutterOnDevice(device, flutterArgs, dryRun, extraEnv = {}) {
  const command = ["run", "-d", device.id, ...flutterArgs];
  if (dryRun) {
    console.log(`[dry-run] flutter ${command.join(" ")}`);
    return;
  }
  run("flutter", command, { env: { ...process.env, ...extraEnv } });
}
