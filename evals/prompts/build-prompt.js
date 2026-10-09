// Promptfoo prompt builder that dynamically loads Stratos SKILL.md and references/LAYERS.md files
// based on `vars.skill` and `vars.include_references` across three modes (`baseline`, `domain_only`, `stratos_full`).

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..', '..');

function readRepoFile(relativePath) {
  const fullPath = path.join(REPO_ROOT, relativePath);
  return fs.readFileSync(fullPath, 'utf8');
}

function buildSystemPrompt(mode, vars = {}) {
  const targetSkill = vars.skill || 'stratos-core';
  const includeReferences = vars.include_references === true || vars.include_references === 'true';

  if (mode === 'baseline') {
    return [
      'You are an expert Swift and SwiftUI software engineer.',
      'Provide clean, idiomatic, production-ready Swift 6 code and clear architectural explanations.'
    ].join('\n');
  }

  const sections = [
    'You are an expert Swift and SwiftUI software engineer equipped with Stratos API design skills.',
    'Follow every principle, pattern, and rejection criterion in the active skill instructions below.'
  ];

  // In `stratos_full` mode, always include stratos-core alongside domain skills (orthogonal composition).
  // In `domain_only` mode, only load the target skill itself (tests orthogonal vs standalone skill performance).
  if (mode === 'stratos_full' && targetSkill !== 'stratos-core') {
    sections.push(`=== ACTIVE SKILL: stratos-core ===\n${readRepoFile('stratos-core/SKILL.md')}`);
    if (includeReferences) {
      sections.push(`=== REFERENCE: stratos-core/references/LAYERS.md ===\n${readRepoFile('stratos-core/references/LAYERS.md')}`);
    }
  }

  sections.push(`=== ACTIVE SKILL: ${targetSkill} ===\n${readRepoFile(`${targetSkill}/SKILL.md`)}`);

  if (includeReferences) {
    sections.push(`=== REFERENCE: ${targetSkill}/references/LAYERS.md ===\n${readRepoFile(`${targetSkill}/references/LAYERS.md`)}`);
  }

  return sections.join('\n\n');
}

function createPrompt(mode) {
  return async function ({ vars }) {
    const systemContent = buildSystemPrompt(mode, vars);
    return [
      {
        role: 'system',
        content: systemContent
      },
      {
        role: 'user',
        content: vars.user_prompt
      }
    ];
  };
}

module.exports = {
  baseline: createPrompt('baseline'),
  domainOnly: createPrompt('domain_only'),
  stratosFull: createPrompt('stratos_full')
};
