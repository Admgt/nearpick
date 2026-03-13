const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const rootDir = path.join(__dirname, "..");
const ignoredDirs = new Set(["node_modules", "reports", "scripts"]);
const jsFiles = [];

function collectJsFiles(dir) {
  const entries = fs.readdirSync(dir, {withFileTypes: true});
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!ignoredDirs.has(entry.name)) {
        collectJsFiles(fullPath);
      }
      continue;
    }

    if (entry.isFile() && entry.name.endsWith(".js")) {
      jsFiles.push(fullPath);
    }
  }
}

collectJsFiles(rootDir);

const errors = [];

for (const file of jsFiles) {
  const content = fs.readFileSync(file, "utf8");
  try {
    new vm.Script(content, {filename: file});
  } catch (error) {
    errors.push(
        `Szintaktikai hiba: ${path.relative(rootDir, file)}\n${error.message}`,
    );
  }

  if (/\bvar\b/.test(content)) {
    errors.push(`Kerulendo 'var' hasznalat: ${path.relative(rootDir, file)}`);
  }
}

if (errors.length > 0) {
  console.error(errors.join("\n\n"));
  process.exit(1);
}

console.log(`Functions lint rendben (${jsFiles.length} JS fajl ellenorizve).`);
