#!/usr/bin/env node
// Generate demo/data.js from the real Terraform and documentation files.
//
// The demo cannot read the filesystem, so this script parses the modules and
// examples with src/hcl.js and embeds the result. A test recomputes the hash,
// which means a demo that shows stale inputs fails the suite instead of quietly
// lying to a reviewer.
import { createHash } from "node:crypto";
import { readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import {
  parseHcl,
  variableDefinitions,
  outputDefinitions,
  resourceDefinitions,
  moduleBlocks,
  blocksOfType,
  unquote,
} from "../src/hcl.js";
import { MODULES } from "../src/validate.js";

const SELF = fileURLToPath(import.meta.url);
const ROOT = resolve(dirname(SELF), "..");
const DATA_PATH = join(ROOT, "demo", "data.js");
const TRACKED = ["modules", "examples", "docs"];

function walk(directory, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name === ".git") continue;
    const full = join(directory, entry.name);
    if (entry.isDirectory()) walk(full, files);
    else if (/\.(tf|md)$/.test(entry.name) || entry.name.endsWith(".tfvars.example")) files.push(full);
  }
  return files;
}

export function sourceFiles() {
  return [...TRACKED.flatMap((directory) => walk(join(ROOT, directory))), join(ROOT, "README.md")]
    .map((file) => ({ path: relative(ROOT, file).split("\\").join("/"), content: readFileSync(file, "utf8") }))
    .sort((left, right) => left.path.localeCompare(right.path));
}

export function sourceHash(files = sourceFiles()) {
  const hash = createHash("sha256");
  for (const file of files) hash.update(file.path).update("\0").update(file.content).update("\0");
  return hash.digest("hex");
}

function firstParagraph(markdown) {
  const lines = markdown.split("\n").slice(1);
  const start = lines.findIndex((line) => line.trim() && !line.startsWith("#"));
  if (start === -1) return "";
  const paragraph = [];
  for (let index = start; index < lines.length; index++) {
    if (!lines[index].trim()) break;
    if (lines[index].startsWith("#")) break;
    paragraph.push(lines[index].trim());
  }
  // Strip the inline markdown that would otherwise render as literal backticks.
  return paragraph.join(" ")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1");
}

function title(markdown) {
  const match = markdown.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : "";
}

function moduleData(name) {
  const base = `modules/${name}`;
  const main = readFileSync(join(ROOT, base, "main.tf"), "utf8");
  const readme = readFileSync(join(ROOT, base, "README.md"), "utf8");
  const variables = variableDefinitions(readFileSync(join(ROOT, base, "variables.tf"), "utf8"));
  const outputs = outputDefinitions(readFileSync(join(ROOT, base, "outputs.tf"), "utf8"));
  const resources = resourceDefinitions(main);
  const parsed = parseHcl(main);

  return {
    name,
    title: title(readme) || name,
    description: firstParagraph(readme),
    inputs: variables.map((variable) => ({
      name: variable.name,
      type: variable.type,
      description: variable.description,
      default: variable.default === undefined ? null : variable.default.trim(),
      required: variable.default === undefined,
      sensitive: variable.sensitive,
    })),
    outputs: outputs.map((output) => ({ name: output.name, description: output.description, value: output.value.trim() })),
    resources: resources.map((resource) => ({ type: resource.type, name: resource.name })),
    resourceTypes: [...new Set(resources.map((resource) => resource.type))].sort(),
    sourcePreview: main.split("\n").slice(0, 90).join("\n"),
    providerBlocks: blocksOfType(parsed.blocks, "provider").length,
  };
}

function exampleData(environment) {
  const base = `examples/${environment}`;
  const main = readFileSync(join(ROOT, base, "main.tf"), "utf8");
  const readme = readFileSync(join(ROOT, base, "README.md"), "utf8");
  const modules = moduleBlocks(main);
  const variables = variableDefinitions(readFileSync(join(ROOT, base, "variables.tf"), "utf8"));
  const outputs = outputDefinitions(readFileSync(join(ROOT, base, "outputs.tf"), "utf8"));
  const parsed = parseHcl(main);
  return {
    name: environment,
    title: `examples/${environment}`,
    description: firstParagraph(readme),
    modules: modules.map((module) => ({
      name: module.name,
      source: module.source,
      inputs: Object.fromEntries(Object.entries(module.inputs).map(([key, value]) => [key, unquote(value).trim()])),
    })),
    variables: variables.map((variable) => ({ name: variable.name, type: variable.type, description: variable.description })),
    outputs: outputs.map((output) => ({ name: output.name, description: output.description })),
    providers: blocksOfType(parsed.blocks, "provider").length,
    sourcePreview: main.split("\n").slice(0, 90).join("\n"),
  };
}

function docsData() {
  return walk(join(ROOT, "docs"))
    .filter((file) => file.endsWith(".md"))
    .map((file) => {
      const content = readFileSync(file, "utf8");
      return {
        file: relative(ROOT, file).split("\\").join("/"),
        title: title(content),
        description: firstParagraph(content),
      };
    })
    .sort((left, right) => left.file.localeCompare(right.file));
}

export function buildData() {
  const files = sourceFiles();
  return {
    hash: sourceHash(files),
    generatedFrom: files.map((file) => file.path),
    modules: MODULES.map(moduleData),
    examples: ["dev", "prod"].map(exampleData),
    docs: docsData(),
  };
}

export function renderDataFile(data) {
  return `// Generated by scripts/build-data.mjs from the real Terraform files.
// Do not edit by hand; run \`node scripts/build-data.mjs\` after changing a module.

export const SOURCE_HASH = ${JSON.stringify(data.hash)};

export const PROJECT_DATA = ${JSON.stringify({
    generatedFrom: data.generatedFrom,
    modules: data.modules,
    examples: data.examples,
    docs: data.docs,
  }, null, 2)};
`;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === pathToFileURL(SELF).href) {
  const data = buildData();
  writeFileSync(DATA_PATH, renderDataFile(data));
  console.log(`wrote demo/data.js from ${data.modules.length} modules and ${data.examples.length} examples (hash ${data.hash.slice(0, 12)})`);
}

export { DATA_PATH };
