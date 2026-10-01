import assert from "node:assert/strict";
import test from "node:test";
import { diagramSource, readSource, readLocales, enhanceContent, headingIds, assembleContent } from "../../scripts/docs-content.mjs";
import { localizeDiagram } from "../../scripts/diagram-locales.mjs";

for (const slug of ["architecture", "install-cli"]) {
  test(`${slug}: translated diagrams keep their graph structure and executable commands`, () => {
    const { $ } = readSource(slug);
    const source = diagramSource($, $(".mermaid"));
    if (slug === "architecture") assert(source.includes("agents/squad/*.agent.md<br/>"));
    const translated = localizeDiagram(source, "fr", slug);
    assert.equal(localizeDiagram(source, "en", slug), source);
    const skeleton = value => value.split("\n").map(line => line
      .replace(/"[^"]*"/g, '"label"')
      .replace(/(participant \w+ as ).*/, "$1label")
      .replace(/(->>|-->>)([^:]+):.*/, "$1$2:label"));
    assert.deepEqual(skeleton(translated), skeleton(source));
    const commands = value => value.split("\n").filter(line => /: (copilot |hve-squad:squad-)/.test(line));
    assert.deepEqual(commands(translated), commands(source));
    assembleContent($);
    enhanceContent($, headingIds($), readLocales().fr.ui, "../", "fr", slug);
    assert.equal($(".diagram-render[hidden]").length, 1);
    assert.equal($(".diagram-source[open]").length, 1);
    assert.equal($(".diagram-code code").text(), translated);
  });
}

test("missing diagram locales fail explicitly", () => {
  assert.throws(() => localizeDiagram("flowchart TD", "es", "architecture"), /Missing diagram translation/);
});
