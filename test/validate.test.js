import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";

import { validateBaseline, MODULES } from "../src/validate.js";

const ROOT = process.cwd();
const TEXT = new Set([".tf", ".md", ".yml", ".yaml", ".mjs", ".json"]);

function readTree(directory = ROOT, files = {}) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (["node_modules", ".git", ".terraform", "fonts", "demo"].includes(entry.name)) continue;
    const full = join(directory, entry.name);
    if (entry.isDirectory()) readTree(full, files);
    else if (TEXT.has(entry.name.slice(entry.name.indexOf("."))) || entry.name.endsWith(".tfvars.example")) {
      files[relative(ROOT, full).split("\\").join("/")] = readFileSync(full, "utf8");
    }
  }
  return files;
}

const realFiles = readTree();
const clone = () => ({ ...readTree() });

test("the repository passes its own structural checks", () => {
  const result = validateBaseline(realFiles);
  assert.deepEqual(result.errors, []);
  assert.equal(result.ok, true);
  assert.equal(result.stats.modules, 6);
  assert.equal(result.stats.examples, 2);
  assert.ok(result.stats.resources >= 30, `resources: ${result.stats.resources}`);
  assert.ok(result.stats.variables >= 50);
});

test("every module has the four required files", () => {
  for (const module of MODULES) {
    for (const file of ["main.tf", "variables.tf", "outputs.tf", "README.md"]) {
      assert.ok(realFiles[`modules/${module}/${file}`], `${module}/${file}`);
    }
  }
});

test("a public database is rejected", () => {
  const files = clone();
  files["modules/rds/main.tf"] = files["modules/rds/main.tf"].replace("publicly_accessible = false", "publicly_accessible = true");
  const result = validateBaseline(files);
  assert.equal(result.ok, false);
  assert.ok(result.errors.some((error) => /publicly_accessible/.test(error.message)));
});

test("an undocumented variable is rejected", () => {
  const files = clone();
  files["modules/network/variables.tf"] = files["modules/network/variables.tf"].replace('  description = "VPC CIDR block."\n', "");
  const result = validateBaseline(files);
  assert.ok(result.errors.some((error) => /"cidr" has no description/.test(error.message)));
});

test("an undeclared or unused variable is caught", () => {
  const files = clone();
  files["modules/network/main.tf"] = files["modules/network/main.tf"] + '\nresource "aws_ssm_parameter" "x" {\n  value = var.ghost\n}\n';
  const undeclared = validateBaseline(files);
  assert.ok(undeclared.errors.some((error) => /var.ghost/.test(error.message)));

  const unused = clone();
  unused["modules/network/variables.tf"] += '\nvariable "never_used" {\n  type        = string\n  description = "unused"\n}\n';
  const result = validateBaseline(unused);
  assert.ok(result.warnings.some((warning) => /never_used/.test(warning.message)));
});

test("broken module sources in examples are rejected", () => {
  const files = clone();
  files["examples/dev/main.tf"] = files["examples/dev/main.tf"].replace('source = "../../modules/network"', 'source = "../../modules/network-missing"');
  const result = validateBaseline(files);
  assert.ok(result.errors.some((error) => /unknown module/.test(error.message)));
});

test("committed secrets and trailing whitespace are rejected", () => {
  const files = clone();
  files["modules/rds/main.tf"] = files["modules/rds/main.tf"].replace("password = var.password", 'password = "hunter2-very-secret"');
  files["modules/network/main.tf"] += "\n# trailing space   \n";
  const result = validateBaseline(files);
  assert.ok(result.errors.some((error) => /password literal/.test(error.message)));
  assert.ok(result.errors.some((error) => /trailing whitespace/.test(error.message)));
});

test("missing required files and CI wiring are rejected", () => {
  const files = clone();
  delete files["examples/prod/README.md"];
  files[".github/workflows/ci.yml"] = files[".github/workflows/ci.yml"].split("node scripts/validate.mjs").join("node scripts/other.mjs");
  const result = validateBaseline(files);
  assert.ok(result.errors.some((error) => /examples\/prod\/README.md/.test(error.path)));
  assert.ok(result.errors.some((error) => /does not run scripts\/validate\.mjs/.test(error.message)));
});

test("unbalanced HCL is reported per file", () => {
  const files = clone();
  files["modules/budget/main.tf"] = files["modules/budget/main.tf"] + "\nresource \"aws_budget\" \"broken\" {\n";
  const result = validateBaseline(files);
  assert.ok(result.errors.some((error) => error.path === "modules/budget/main.tf" && /HCL syntax/.test(error.message)));
});
