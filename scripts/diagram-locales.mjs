const labels = {
  fr: {
    architecture: [
      ["hve-squad-plugin (this repo)", "hve-squad-plugin (ce dépôt)"],
      ["(27 agents)", "(27 agents)"],
      ["(squad skill, 7 invocation skills)", "(compétence squad, 7 compétences d’invocation)"],
      ["(enforcement backstop)", "(contrôles complémentaires)"],
      ["registers @hve-squad/mcp", "enregistre @hve-squad/mcp"],
      ["Copilot CLI / VS Code / desktop app (one session, two paths)", "Copilot CLI / VS Code / application (une session, deux chemins)"],
      ["Direct agent-dispatch path", "Délégation directe aux agents"],
      ["(user or agent names hve-squad:squad-*)", "(l’utilisateur ou l’agent désigne hve-squad:squad-*)"],
      ["Autonomous tool-call path", "Appel autonome d’outils"],
      ["(model calls squad_* mid-conversation)", "(le modèle appelle squad_* pendant la conversation)"],
      ["(stdio, delegated mode)", "(stdio, mode délégué)"],
      ["5 coarse tools:", "5 outils de haut niveau :"],
      ["Copilot Studio / M365 (separate deployment, not via this plugin)", "Copilot Studio / M365 (déploiement distinct, hors de ce plugin)"],
      ["hve-squad-mcp embedded/HTTP mode", "hve-squad-mcp en mode intégré/HTTP"],
      ['"direct dispatch"', '"délégation directe"'],
      ['"tool call"', '"appel d’outil"'],
      ["returns persona + routing row<br/>+ framed dispatch request", "renvoie le persona + la règle de routage<br/>+ la demande de délégation encadrée"],
      ["same host's runSubagent/task<br/>runs the actual dispatch", "runSubagent/task du même hôte<br/>effectue la délégation réelle"],
      ["registers (stdio)", "enregistre (stdio)"],
    ],
    "install-cli": [
      ["participant U as User", "participant U as Utilisateur"],
      ["participant MP as Marketplace (this repo)", "participant MP as Marketplace (ce dépôt)"],
      ["participant Reg as Local plugin registry", "participant Reg as Registre local des plugins"],
      ["fetch .github/plugin/marketplace.json", "récupère .github/plugin/marketplace.json"],
      ["2 entries — hve-squad (ref main), hve-squad-hve-core (pinned sha)", "2 entrées — hve-squad (réf. main), hve-squad-hve-core (SHA épinglé)"],
      ["fetch plugin.json, then agents/, skills/, hooks.json, .mcp.json", "récupère plugin.json, puis agents/, skills/, hooks.json, .mcp.json"],
      ["register 27 agents + squad skill + hooks + MCP server", "enregistre 27 agents + la compétence squad + les hooks + le serveur MCP"],
      ["fetch content at the pinned commit SHA", "récupère le contenu au SHA du commit épinglé"],
      ["register hve-core agents + skills", "enregistre les agents et compétences hve-core"],
      ["namespaces active, squad roles resolvable", "espaces de noms actifs, rôles de la squad résolus"],
      ["dispatches Squad Coordinator, which can now reach hve-core roles", "invoque Squad Coordinator, qui peut désormais appeler les rôles hve-core"],
    ],
  },
};

export function localizeDiagram(source, language, page) {
  if (language === "en") return source;
  const replacements = labels[language]?.[page];
  if (!replacements) throw new Error(`Missing diagram translation: ${language}/${page}`);
  let result = source;
  for (const [original, translation] of replacements) {
    if (!result.includes(original)) throw new Error(`Diagram label changed in ${page}: ${original}`);
    result = result.replaceAll(original, translation);
  }
  return result;
}
