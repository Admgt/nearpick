const fs = require("node:fs");
const path = require("node:path");
const {spawnSync} = require("node:child_process");

const rootDir = path.join(__dirname, "..");
const reportFileArg = process.argv.find((arg) => arg.startsWith("--report-file="));
const reportFile = reportFileArg ? path.resolve(rootDir, reportFileArg.split("=")[1]) : null;
const packageLockPath = path.join(rootDir, "package-lock.json");

function parseVersion(version) {
  return String(version || "")
      .split(".")
      .map((part) => Number.parseInt(part, 10) || 0);
}

function compareVersions(left, right) {
  const leftParts = parseVersion(left);
  const rightParts = parseVersion(right);
  const length = Math.max(leftParts.length, rightParts.length);
  for (let index = 0; index < length; index += 1) {
    const leftPart = leftParts[index] || 0;
    const rightPart = rightParts[index] || 0;
    if (leftPart > rightPart) {
      return 1;
    }
    if (leftPart < rightPart) {
      return -1;
    }
  }
  return 0;
}

function getInstalledVersion(packageName) {
  if (!fs.existsSync(packageLockPath)) {
    return null;
  }

  const packageLock = JSON.parse(fs.readFileSync(packageLockPath, "utf8"));
  return packageLock.packages?.[`node_modules/${packageName}`]?.version || null;
}

function shouldSuppress(packageName, details) {
  const installedVersion = getInstalledVersion(packageName);
  if (packageName === "node-forge" && installedVersion &&
      compareVersions(installedVersion, "1.3.3") >= 0) {
    return {
      installedVersion,
      reason: "Az audit adatbazis elavultnak tunik: a package-lock node-forge 1.3.3+ verziot rogzit.",
    };
  }

  return null;
}

const auditCommand = process.platform === "win32" ?
  {
    command: "cmd.exe",
    args: ["/d", "/s", "/c", "npm audit --omit=dev --audit-level=high --json"],
  } :
  {
    command: "npm",
    args: ["audit", "--omit=dev", "--audit-level=high", "--json"],
  };

const audit = spawnSync(auditCommand.command, auditCommand.args, {
  cwd: rootDir,
  encoding: "utf8",
  shell: false,
});

if (audit.error) {
  console.error(`A functions dependency audit nem futtathato: ${audit.error.message}`);
  process.exit(1);
}

if (reportFile) {
  fs.mkdirSync(path.dirname(reportFile), {recursive: true});
  fs.writeFileSync(reportFile, audit.stdout || "", "utf8");
}

let report = null;
try {
  report = JSON.parse(audit.stdout || "{}");
} catch (error) {
  console.error("A functions dependency audit report nem feldolgozhato JSON.");
  if (audit.stdout) {
    console.error(audit.stdout);
  }
  if (audit.stderr) {
    console.error(audit.stderr.trim());
  }
  process.exit(audit.status || 1);
}

const vulnerabilities = Object.entries(report.vulnerabilities || {})
    .filter(([, details]) => details && ["high", "critical"].includes(details.severity));

const unsuppressed = [];
const suppressed = [];

for (const [name, details] of vulnerabilities) {
  const suppression = shouldSuppress(name, details);
  if (suppression) {
    suppressed.push({name, details, suppression});
  } else {
    unsuppressed.push([name, details]);
  }
}

if (suppressed.length > 0) {
  console.log("Functions dependency audit: ismert audit-eltarasok elnyomva:");
  for (const entry of suppressed) {
    console.log(
        `- ${entry.name}@${entry.suppression.installedVersion}: ${entry.suppression.reason}`,
    );
  }
}

if (unsuppressed.length > 0) {
  console.error("A functions dependency audit magas kockazatu vagy kritikus talalatot jelzett:");
  for (const [name, details] of unsuppressed) {
    const via = (details.via || [])
        .map((item) => typeof item === "string" ? item : item.name)
        .join(", ");
    console.error(`- ${name} [${details.severity}]${via ? ` via ${via}` : ""}`);
  }
  process.exit(1);
}

if (audit.status !== 0 && vulnerabilities.length === 0) {
  console.error("A functions dependency audit hibaval tert vissza, de nincs high/critical talalat.");
  if (audit.stderr) {
    console.error(audit.stderr.trim());
  }
  process.exit(audit.status);
}

console.log("Functions dependency audit rendben.");
