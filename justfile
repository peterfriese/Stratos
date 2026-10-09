# Stratos task runner

# List all available recipes
default:
    @just --list

# Run full skill validation (structure, frontmatter, links + Swift 6 snippet compilation)
validate *args:
    swift -module-cache-path /tmp/stratos-clang-module-cache scripts/validate-skills.swift {{args}}

# Run fast structural/frontmatter/link validation only (skips Swift 6 compilation)
validate-quick *args:
    swift -module-cache-path /tmp/stratos-clang-module-cache scripts/validate-skills.swift --skip-snippets {{args}}

# Typecheck all Swift scripts and Markdown/YAML code blocks under Swift 6
verify-snippets *args:
    swift -module-cache-path /tmp/stratos-clang-module-cache scripts/verify-snippets.swift {{args}}

# Ensure Promptfoo evaluation dependencies are installed in evals/
eval-setup:
    cd evals && ([ -d node_modules ] || npm install)

# Run the full Promptfoo evaluation suite across all 3 skills
eval *args: eval-setup
    cd evals && npm run eval {{ if args != "" { "-- " + args } else { "" } }}

# Run stratos-core Promptfoo evaluations only
eval-core *args: eval-setup
    cd evals && npm run eval:core {{ if args != "" { "-- " + args } else { "" } }}

# Run stratos-swiftui Promptfoo evaluations only
eval-swiftui *args: eval-setup
    cd evals && npm run eval:swiftui {{ if args != "" { "-- " + args } else { "" } }}

# Run stratos-swift Promptfoo evaluations only
eval-swift *args: eval-setup
    cd evals && npm run eval:swift {{ if args != "" { "-- " + args } else { "" } }}

# Run the Promptfoo evaluation suite against Gemini Pro
eval-pro *args: eval-setup
    cd evals && npm run eval:pro {{ if args != "" { "-- " + args } else { "" } }}

# Open the interactive Promptfoo web matrix
eval-view *args: eval-setup
    cd evals && npm run eval:view {{ if args != "" { "-- " + args } else { "" } }}

# Verify skills.sh CLI discovers all 3 stratos-* skills
check-discovery:
    npx skills add . --list

# Remove temporary Swift/Clang module cache
clean:
    rm -rf /tmp/stratos-clang-module-cache
