import test from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";

import { buildData, sourceHash, sourceFiles } from "../scripts/build-data.mjs";
import { PROJECT_DATA, SOURCE_HASH } from "../demo/data.js";

test("the checked-in demo data is not stale", () => {
  const data = buildData();
  assert.equal(SOURCE_HASH, data.hash, "run `node scripts/build-data.mjs` after editing Terraform or docs");
});

test("the demo data describes all modules", () => {
  assert.equal(PROJECT_DATA.modules.length, 6);
  for (const module of PROJECT_DATA.modules) {
    assert.ok(module.title, module.name);
    assert.ok(module.description.length > 40, `${module.name} description too short`);
    assert.ok(module.inputs.length > 0, `${module.name} has no inputs`);
    assert.ok(module.outputs.length > 0, `${module.name} has no outputs`);
    assert.ok(module.resources.length > 0, `${module.name} has no resources`);
    assert.ok(module.sourcePreview.includes(module.name === "ecs-service" ? 'resource "aws_ecs' : "resource"), module.name);
    for (const input of module.inputs) {
      assert.ok(input.name && input.type, `${module.name}: incomplete input`);
      assert.ok(input.description, `${module.name}.${input.name} has no description`);
    }
    for (const output of module.outputs) assert.ok(output.name && output.description, `${module.name} output`);
  }
});

test("the demo data describes both environments", () => {
  assert.equal(PROJECT_DATA.examples.length, 2);
  for (const example of PROJECT_DATA.examples) {
    assert.equal(example.modules.length, 6);
    assert.ok(example.sourcePreview.includes("provider \"aws\""));
    for (const module of example.modules) {
      assert.ok(module.source.startsWith("../../modules/"), module.source);
      assert.ok(Object.keys(module.inputs).length > 0, `${example.name}.${module.name}`);
    }
  }
});

test("docs are included in the explorer", () => {
  assert.deepEqual(PROJECT_DATA.docs.map((doc) => doc.file).sort(), [
    "docs/architecture.md",
    "docs/modules.md",
    "docs/state.md",
  ]);
  for (const doc of PROJECT_DATA.docs) assert.ok(doc.title && doc.description);
});

test("the source hash covers every tracked file", () => {
  const paths = sourceFiles().map((file) => file.path);
  assert.ok(paths.includes("README.md"));
  assert.ok(paths.includes("modules/rds/main.tf"));
  assert.ok(paths.includes("examples/prod/main.tf"));
  assert.equal(new Set(paths).size, paths.length);
  assert.equal(sourceHash(sourceFiles()), sourceHash(sourceFiles()));
});

test("scripts/validate.mjs exits zero on the real tree", () => {
  const output = execFileSync(process.execPath, ["scripts/validate.mjs"], { encoding: "utf8" });
  assert.match(output, /structural checks passed/);
  assert.match(output, /terraform: not installed|terraform fmt:/);
});

test("scripts/validate.mjs --json emits a machine-readable report", () => {
  const output = execFileSync(process.execPath, ["scripts/validate.mjs", "--json"], { encoding: "utf8" });
  const report = JSON.parse(output);
  assert.equal(report.ok, true);
  assert.deepEqual(report.errors, []);
  assert.equal(report.structural.stats.modules, 6);
});
