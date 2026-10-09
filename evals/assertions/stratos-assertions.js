// Reusable deterministic assertions for Stratos Promptfoo evaluations.
// Checks structural and syntactic properties on uncommented Swift code blocks.

function stripSwiftComments(code) {
  const blockComment = new RegExp('/\\*[\\s\\S]*?\\*/', 'g');
  const lineComment = new RegExp('//.*$', 'gm');
  return code
    .replace(blockComment, '')
    .replace(lineComment, '');
}

function extractUncommentedSwiftCode(output) {
  const text = String(output);
  const codeBlocks = [...text.matchAll(/```swift([\s\S]*?)```/g)].map(m => stripSwiftComments(m[1]));
  return codeBlocks.join('\n');
}

/**
 * Verifies "Call Site First" law: the response shows a call-site / usage code snippet
 * BEFORE the primary target type implementation.
 */
function assertCallSiteFirst(output) {
  const text = String(output);
  const codeBlocksWithIndex = [...text.matchAll(/```swift([\s\S]*?)```/g)].map(m => ({
    raw: m[1].trim(),
    index: m.index
  }));

  if (codeBlocksWithIndex.length === 0) {
    return {
      pass: false,
      score: 0,
      reason: 'Expected at least one ```swift code block in output.'
    };
  }

  const firstBlock = codeBlocksWithIndex[0];
  const firstBlockUncommented = stripSwiftComments(firstBlock.raw);
  const textBeforeEndOfFirstBlock = text.slice(0, firstBlock.index) + '\n' + firstBlock.raw;

  // 1. If the heading/prose right before the first block or comment inside it explicitly marks it as Call Site,
  // and it isn't defining the whole implementation in a single block without call site first:
  const hasExplicitCallSiteHeader = /(?:###?\s*.*(?:call\s*site|ideal\s*usage|layer\s*1)|\/\/\s*(?:MARK:\s*-\s*)?(?:1\.\s*)?(?:ideal\s+)?(?:call\s*site|usage|layer\s*1|troposphere|step\s*1))/i.test(textBeforeEndOfFirstBlock);

  const typeDeclRegex = /^\s*(?:public\s+|internal\s+|private\s+|final\s+|@\w+(?:\([^)]*\))?\s+)*(?:struct|class|actor|protocol)\s+(\w+)/gm;
  const declaredTypesInFirstBlock = [...firstBlockUncommented.matchAll(typeDeclRegex)].map(m => m[1]);

  // Pure call-site snippet (no struct/class/actor/protocol declarations at all)
  if (declaredTypesInFirstBlock.length === 0) {
    return {
      pass: true,
      score: 1,
      reason: 'First Swift code block is a dedicated call-site snippet before any type declaration.'
    };
  }

  // Parent/Container/App wrapper view demonstrating the call site of a child view
  const onlyDefinesCallerContainer = declaredTypesInFirstBlock.every(name =>
    /^(?:Parent|Container|SettingsContainer|Host|App|Root|Caller|Example|Demo|Mock)/i.test(name)
  );
  if (onlyDefinesCallerContainer && codeBlocksWithIndex.length >= 2) {
    return {
      pass: true,
      score: 1,
      reason: `First Swift code block defines caller context (${declaredTypesInFirstBlock.join(', ')}) before target implementation.`
    };
  }

  // Single block or multi-block that starts with a `// CALL SITE` section before the first type declaration
  const callSiteCommentRegex = new RegExp('//\\s*(?:MARK:\\s*-\\s*)?(?:1\\.\\s*)?(?:ideal\\s+)?(?:call\\s*site|usage|layer\\s*1|troposphere|step\\s*1)', 'i');
  const callSiteCommentMatch = callSiteCommentRegex.exec(firstBlock.raw);
  const firstTypeMatch = /^\s*(?:public\s+|internal\s+|private\s+|final\s+|@\w+(?:\([^)]*\))?\s+)*(?:struct|class|actor|protocol)\s+\w+/m.exec(firstBlock.raw);
  if (callSiteCommentMatch && firstTypeMatch && callSiteCommentMatch.index < firstTypeMatch.index) {
    return {
      pass: true,
      score: 1,
      reason: 'First Swift code block begins with a Call Site section before the type implementation.'
    };
  }

  if (hasExplicitCallSiteHeader && codeBlocksWithIndex.length >= 2) {
    return {
      pass: true,
      score: 1,
      reason: 'First Swift code block is under an explicit Call Site section prior to the implementation blocks.'
    };
  }

  return {
    pass: false,
    score: 0,
    reason: 'Violated Call Site First: type implementation appeared before showing the intended call site.'
  };
}

/**
 * Verifies that no primary `init(...)` declaration in the output has Init-Bloat (> 4 parameters).
 */
function assertNoInitBloat(output) {
  const swiftCode = extractUncommentedSwiftCode(output);

  const initMatches = [...swiftCode.matchAll(/init\s*\(([^)]*)\)/g)];
  for (const match of initMatches) {
    const paramsRaw = match[1].trim();
    if (!paramsRaw) continue;
    let depth = 0;
    let paramCount = 1;
    for (const ch of paramsRaw) {
      if (ch === '(' || ch === '<' || ch === '[') depth++;
      else if (ch === ')' || ch === '>' || ch === ']') depth--;
      else if (ch === ',' && depth === 0) paramCount++;
    }
    if (paramCount > 4) {
      return {
        pass: false,
        score: 0,
        reason: `Init-Bloat detected: found init with ${paramCount} parameters (max 4 allowed in Troposphere).`
      };
    }
  }

  return {
    pass: true,
    score: 1,
    reason: 'All initializers have <= 4 parameters (no Init-Bloat).'
  };
}

/**
 * Verifies that uncommented Swift code blocks do NOT use legacy SwiftUI patterns
 * (EnvironmentKey, .foregroundColor, .cornerRadius, .previewLayout).
 */
function assertModernSwiftUICode(output) {
  const swiftCode = extractUncommentedSwiftCode(output);
  const forbidden = ['.foregroundColor(', '.cornerRadius(', '.previewLayout(', 'EnvironmentKey'];
  for (const token of forbidden) {
    if (swiftCode.includes(token)) {
      return {
        pass: false,
        score: 0,
        reason: `Found legacy/soft-deprecated SwiftUI API '${token}' in Swift code.`
      };
    }
  }
  return {
    pass: true,
    score: 1,
    reason: 'Swift code uses modern SwiftUI APIs without legacy EnvironmentKey, .foregroundColor, .cornerRadius, or .previewLayout.'
  };
}

/**
 * Verifies that uncommented Swift code blocks use @Observable/@Bindable and do NOT use
 * legacy ObservableObject, @ObservedObject, or @StateObject.
 */
function assertModernObservationCode(output) {
  const swiftCode = extractUncommentedSwiftCode(output);
  const forbidden = ['ObservableObject', '@ObservedObject', '@StateObject', '@Published'];
  for (const token of forbidden) {
    if (swiftCode.includes(token)) {
      return {
        pass: false,
        score: 0,
        reason: `Found legacy Combine observation API '${token}' in Swift code.`
      };
    }
  }
  return {
    pass: true,
    score: 1,
    reason: 'Swift code uses modern Observation (@Observable / @Bindable) without legacy ObservableObject.'
  };
}

/**
 * Verifies that uncommented Swift code blocks do NOT use NSLock.
 */
function assertNoNSLockInCode(output) {
  const swiftCode = extractUncommentedSwiftCode(output);
  if (swiftCode.includes('NSLock')) {
    return {
      pass: false,
      score: 0,
      reason: 'Found legacy NSLock in Swift code instead of Swift 6 Mutex.'
    };
  }
  return {
    pass: true,
    score: 1,
    reason: 'Swift code does not use legacy NSLock.'
  };
}

module.exports = {
  assertCallSiteFirst,
  assertNoInitBloat,
  assertModernSwiftUICode,
  assertModernObservationCode,
  assertNoNSLockInCode
};
