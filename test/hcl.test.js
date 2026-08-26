import test from "node:test";
import assert from "node:assert/strict";

import {
  parseHcl,
  variableDefinitions,
  outputDefinitions,
  resourceDefinitions,
  moduleBlocks,
  referencedVariables,
  syntaxIssues,
  maskSource,
  blocksOfType,
} from "../src/hcl.js";

test("parses variable blocks with types, descriptions and defaults", () => {
  const source = `variable "name" {
  type        = string
  description = "Resource prefix."
}

variable "tags" {
  type        = map(string)
  description = "Tags."
  default     = {}
}
`;
  const variables = variableDefinitions(source);
  assert.equal(variables.length, 2);
  assert.deepEqual(variables[0], {
    name: "name",
    type: "string",
    description: "Resource prefix.",
    default: undefined,
    sensitive: false,
  });
  assert.equal(variables[1].default, "{}");
});

test("parses outputs and resource labels", () => {
  const source = `output "vpc_id" {
  description = "VPC id."
  value       = aws_vpc.this.id
}

resource "aws_subnet" "private" {
  count = 2
}
`;
  assert.deepEqual(outputDefinitions(source)[0], {
    name: "vpc_id",
    description: "VPC id.",
    value: "aws_vpc.this.id",
  });
  assert.deepEqual(resourceDefinitions(source), [
    { type: "aws_subnet", name: "private", blockNames: [] },
  ]);
  assert.equal(blocksOfType(parseHcl(source).blocks, "resource").length, 1);
});

test("module blocks expose inputs but not meta arguments", () => {
  const source = `module "network" {
  source    = "../../modules/network"
  name      = local.name
  az_count  = 3
  providers = { aws = aws }
}
`;
  const [module] = moduleBlocks(source);
  assert.equal(module.name, "network");
  assert.equal(module.source, "../../modules/network");
  assert.deepEqual(Object.keys(module.inputs).sort(), ["az_count", "name"]);
});

test("strings, comments and heredocs do not confuse the scanner", () => {
  const source = `variable "note" {
  type        = string
  description = "A string with { braces } and a # hash"
  default     = "not a comment // either"
}

# a comment with { unbalanced brace
resource "aws_instance" "this" {
  user_data = <<-EOT
    line with }
    var.ghost
  EOT
}
`;
  assert.deepEqual(syntaxIssues(source), []);
  const variables = variableDefinitions(source);
  assert.equal(variables[0].description, "A string with { braces } and a # hash");
  assert.equal(variables[0].default, '"not a comment // either"');
});

test("referencedVariables sees interpolations but ignores comments", () => {
  const source = `locals {
  arn = "arn:aws:logs:\${var.region}:\${var.name}"
}

# var.commented is a comment, not a usage
resource "x" "y" {
  value = var.tags
}
`;
  const names = referencedVariables(source).sort();
  assert.deepEqual(names, ["name", "region", "tags"]);
});

test("syntaxIssues reports unclosed and mismatched delimiters", () => {
  assert.equal(syntaxIssues('resource "x" "y" {\n}\n').length, 0);
  assert.ok(syntaxIssues('resource "x" "y" {\n').some((issue) => /unclosed/.test(issue)));
  assert.ok(syntaxIssues('resource "x" "y" {\n]\n}\n').some((issue) => /unexpected/.test(issue)));
  assert.ok(syntaxIssues('resource "x" "y" {\n}').some((issue) => /newline/.test(issue)));
});

test("maskSource preserves offsets and newlines", () => {
  const source = 'a = "secret"\nb = 1 # comment\n';
  const masked = maskSource(source);
  assert.equal(masked.length, source.length);
  assert.equal(masked.split("\n").length, source.split("\n").length);
  assert.ok(!masked.includes("secret"));
  assert.ok(!masked.includes("comment"));
});
