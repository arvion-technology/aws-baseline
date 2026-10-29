#!/usr/bin/env node
// Validate the baseline two ways:
//
//   1. structural checks from src/validate.js, which always run;
//   2. `terraform fmt -check` and `terraform validate` for each example, when a
//      terraform binary is available.
//
// The Terraform steps are optional on purpose. A client reviewing the repository
// should be able to run `npm test` and this script without installing Terraform;
// CI installs it and gets the stronger check.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { validateBaseline, formatValidation } from "../src/validate.js";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const TEXT_EXTENSIONS = new Set([".tf", ".md", ".yml", ".yaml", ".mjs", ".json", ".example", ".gitignore"]);
const SKIP_DIRS = new Set(["node_modules", ".git", ".terraform"]);

function walk(directory, files = {}) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (SKIP_DIRS.has(entry.name)) continue;
    const full = join(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "fonts" || entry.name === "shots") continue;
      walk(full, files);
      continue;
    }
    const relativePath = relative(ROOT, full).split("\\").join("/");
    if (!TEXT_EXTENSIONS.has(entry.name.slice(entry.name.indexOf("."))) && !entry.name.endsWith(".tfvars.example")) continue;
    if (statSync(full).size > 200_000) continue;
    files[relativePath] = readFileSync(full, "utf8");
  }
  return files;
}

function commandAvailable(command) {
  return spawnSync(command, ["version"], { stdio: "ignore" }).status === 0;
}

const args = new Set(process.argv.slice(2));
const files = walk(ROOT);
const structural = validateBaseline(files);

const terraform = {
  available: commandAvailable("terraform"),
  fmt: "skipped",
  examples: {},
  errors: [],
  warnings: [],
};

if (terraform.available) {
  const fmt = spawnSync("terraform", ["fmt", "-check", "-recursive", "."], { cwd: ROOT, encoding: "utf8" });
  terraform.fmt = fmt.status === 0 ? "passed" : "failed";
  if (fmt.status !== 0) {
    for (const line of (fmt.stdout || "").trim().split("\n").filter(Boolean)) {
      terraform.errors.push({ path: line.replace(/^\.\//, ""), message: "terraform fmt -check failed" });
    }
  }

  for (const environment of ["dev", "prod"]) {
    const directory = join(ROOT, "examples", environment);
    const init = spawnSync("terraform", ["init", "-backend=false", "-input=false", "-no-color"], {
      cwd: directory,
      encoding: "utf8",
      timeout: 180_000,
    });
    if (init.status !== 0) {
      terraform.warnings.push({ environment, message: "terraform init failed; validate skipped" });
      terraform.examples[environment] = "init-failed";
      continue;
    }
    const validate = spawnSync("terraform", ["validate", "-no-color"], { cwd: directory, encoding: "utf8", timeout: 120_000 });
    terraform.examples[environment] = validate.status === 0 ? "passed" : "failed";
    if (validate.status !== 0) {
      for (const line of ((validate.stdout || "") + (validate.stderr || "")).trim().split("\n").filter(Boolean)) {
        terraform.errors.push({ path: `examples/${environment}`, message: line });
      }
    }
  }
}

const allErrors = [...structural.errors, ...terraform.errors];
const allWarnings = [...structural.warnings, ...terraform.warnings];

if (args.has("--json")) {
  console.log(JSON.stringify({ ok: allErrors.length === 0, structural, terraform, errors: allErrors, warnings: allWarnings }, null, 2));
} else {
  console.log(`Terraform baseline, ${structural.stats.modules} modules, ${structural.stats.examples} examples`);
  if (terraform.available) {
    console.log(`terraform fmt: ${terraform.fmt}`);
    for (const [environment, result] of Object.entries(terraform.examples)) {
      console.log(`terraform validate (${environment}): ${result}`);
    }
  } else {
    console.log("terraform: not installed, fmt/validate skipped; structural checks below still apply");
  }
  console.log("");
  process.stdout.write(formatValidation(structural));
  for (const warning of terraform.warnings) console.log(`warn  terraform: ${warning.environment}: ${warning.message}`);
  for (const error of terraform.errors) console.log(`error ${error.path}: ${error.message}`);
  if (allErrors.length) console.log(`\n${allErrors.length} problem(s) found`);
}

process.exit(allErrors.length === 0 ? 0 : 1);
