---
name: review
description: Review code changes against project standards and conventions
user-invocable: true
disable-model-invocation: false
---

# Review Skill

Performs comprehensive code review of changes against Native Display System project standards, conventions, and best practices.

## Usage

```bash
# Review all uncommitted changes
/review

# Review specific file
/review android/sdk/src/main/kotlin/models/Container.kt

# Review staged changes only
/review --staged

# Review specific commit
/review abc1234
```

## What This Skill Does

1. **Analyzes Changes**
   - Reads git diff to understand modifications
   - Identifies affected files and components
   - Determines change type (feature, fix, refactor)

2. **Validates Against Standards**
   - Checks code style and conventions
   - Verifies JSON configurations
   - Ensures cross-platform parity
   - Validates documentation

3. **Security Review**
   - Checks for security vulnerabilities
   - Identifies potential injection issues
   - Reviews data validation
   - Checks for exposed secrets

4. **Generates Report**
   - Lists issues by severity (critical, high, medium, low)
   - Provides file locations and line numbers
   - Suggests fixes for issues
   - Highlights good practices

## Review Categories

### 1. Code Quality

#### Android (Kotlin)
- ✅ Proper use of `@Serializable` for models
- ✅ Jetpack Compose best practices
- ✅ Kotlin idioms and conventions
- ✅ Null safety
- ✅ Coroutine usage
- ❌ Direct use of `!!` operator (null assertion)
- ❌ Mutable state in Composables
- ❌ Large functions (>50 lines)

#### iOS (Swift)
- ✅ Proper use of `Codable` for models
- ✅ SwiftUI best practices
- ✅ Swift idioms and conventions
- ✅ Optional handling
- ✅ Async/await usage
- ❌ Force unwrapping with `!`
- ❌ Retain cycles in closures
- ❌ Large functions (>50 lines)

### 2. Architecture Compliance

Validates against `.claude/reference/` documentation:

#### CLIENT_USAGE_MODEL.md
- JSON parsing flow correct
- Model structure matches spec
- Rendering pipeline follows design

#### JSON_STRUCTURE_REFERENCE.md
- Color format is ARGB (#AARRGGBB)
- All nodes have layout definitions
- Proper dimension units used
- Valid container/element types

#### LAYOUT_SEPARATION.md
- Layout and content properly separated
- Layout calculation independent
- Style resolution follows cascading rules

### 3. Cross-Platform Parity

Ensures Android and iOS implementations are consistent:
- ✅ Same container types supported
- ✅ Same element types supported
- ✅ Same style properties
- ✅ Same dimension units
- ✅ Same color format handling
- ❌ Platform-specific features without equivalent
- ❌ Different behavior for same input

### 4. Security Review

Checks for common security issues:
- ❌ SQL injection vulnerabilities
- ❌ XSS vulnerabilities
- ❌ Command injection
- ❌ Path traversal
- ❌ Exposed secrets or API keys
- ❌ Insecure data storage
- ❌ Missing input validation

### 5. Performance

Identifies performance concerns:
- ❌ N+1 rendering loops
- ❌ Unnecessary recomposition (Compose)
- ❌ Unnecessary re-renders (SwiftUI)
- ❌ Large object allocations in loops
- ❌ Synchronous blocking calls
- ❌ Missing lazy loading

### 6. Documentation

Ensures proper documentation:
- ✅ Public APIs documented
- ✅ Complex logic explained
- ✅ Examples provided
- ✅ README updated if needed
- ❌ Missing KDoc/DocC comments
- ❌ Outdated comments

## Review Output Format

```
📋 Code Review Report
=====================

Platform: Android
Files Changed: 5
Lines Added: +150
Lines Removed: -45

🔴 CRITICAL Issues: 0
🟠 HIGH Issues: 1
🟡 MEDIUM Issues: 3
🟢 LOW Issues: 2

---

🟠 HIGH: Missing input validation
Location: android/sdk/src/main/kotlin/evaluator/VariableEvaluator.kt:67
Issue: Variable path not validated before parsing
Fix: Add validation to check for empty or malformed paths
Impact: Could cause crashes with malformed input

🟡 MEDIUM: Inconsistent naming
Location: android/sdk/src/main/kotlin/models/Container.kt:23
Issue: Property named `child_arrangement` instead of `childArrangement`
Fix: Rename to follow camelCase convention
Impact: Inconsistent with project style

🟡 MEDIUM: Missing null check
Location: android/sdk/src/main/kotlin/resolver/StyleResolver.kt:45
Issue: Accessing parent.style without null check
Fix: Use safe call operator: parent?.style
Impact: Potential NPE if parent is null

🟡 MEDIUM: Large function
Location: android/sdk/src/main/kotlin/rendering/Renderer.kt:120
Issue: Function has 78 lines, should be split
Fix: Extract layout calculation and styling into separate functions
Impact: Reduces readability and maintainability

🟢 LOW: TODO comment
Location: android/sdk/src/main/kotlin/models/Background.kt:34
Issue: TODO comment for gradient implementation
Fix: Track as issue or implement now
Impact: Incomplete feature

🟢 LOW: Unused import
Location: android/sdk/src/main/kotlin/utils/ColorParser.kt:8
Issue: Import android.graphics.Color not used
Fix: Remove unused import
Impact: Code cleanliness

---

✅ GOOD PRACTICES:
- Proper use of @Serializable on all models
- Good test coverage for new features
- Clear function naming
- Proper error handling in parser

📊 CROSS-PLATFORM PARITY:
✅ Container implementation matches iOS
✅ Style resolution logic consistent
⚠️  iOS equivalent not yet implemented for gradient backgrounds

🔒 SECURITY:
✅ No security issues detected
✅ Input validation present
✅ No exposed secrets

---

OVERALL: 6 issues found (0 critical, 1 high, 3 medium, 2 low)
RECOMMENDATION: Fix HIGH issue before merging
```

## Review Checklist

### Before Review
- [ ] Changes staged or committed
- [ ] Build passes
- [ ] Tests pass

### During Review
- [ ] Code follows project conventions
- [ ] Architecture patterns respected
- [ ] Cross-platform parity maintained
- [ ] Security concerns addressed
- [ ] Performance considerations
- [ ] Documentation updated

### After Review
- [ ] All CRITICAL and HIGH issues fixed
- [ ] MEDIUM issues addressed or tracked
- [ ] LOW issues noted for future cleanup

## Integration with Workflow

### Pre-Commit Review
```bash
# Make changes
# Stage changes
git add .

# Review before committing
/review --staged

# Fix issues
# Review again
/review --staged

# When clean, commit
/commit
```

### Pre-PR Review
```bash
# Complete feature
# Build and test
/build
/test

# Review all changes
/review

# Fix issues
# Review again
/review

# Create PR when clean
```

## Review Rules

### Automatic CRITICAL

These issues automatically get CRITICAL severity:
- Exposed secrets or API keys
- SQL injection vulnerabilities
- Command injection vulnerabilities
- Hardcoded credentials
- Missing authentication checks

### Automatic HIGH

These issues automatically get HIGH severity:
- Missing input validation on user input
- Force unwrapping without validation (Swift)
- Null assertion operator without check (Kotlin)
- Synchronous network calls on main thread
- Potential memory leaks

### Automatic MEDIUM

These issues automatically get MEDIUM severity:
- Functions over 50 lines
- Missing error handling
- Inconsistent naming
- Missing documentation on public APIs
- Unused imports or variables

### Automatic LOW

These issues automatically get LOW severity:
- TODO comments
- Minor style inconsistencies
- Optional optimizations
- Suggestions for improvement

## False Positive Handling

If review flags something incorrectly:
1. Add comment explaining why it's correct
2. Use `// review-ignore: reason` marker
3. Document in commit message

## Custom Review Rules

Add project-specific rules to `.claude/review-rules.md`:
```markdown
# Custom Review Rules

## Color Format
- All colors must be ARGB format
- Check: #AARRGGBB or #RRGGBB
- Invalid: rgb(), rgba(), color names

## Layout Required
- All nodes must have layout property
- Check: node.layout is defined
- Invalid: missing layout object
```

## Review Metrics

Tracks over time:
- Average issues per PR
- Issue severity distribution
- Time to fix issues
- Common issue patterns

## Best Practices

1. **Review early** - catch issues before they compound
2. **Review often** - small reviews are faster
3. **Fix critical first** - prioritize by severity
4. **Learn from reviews** - track common issues
5. **Automate checks** - use pre-commit hooks
6. **Document exceptions** - explain unusual code

## Related Skills

- `/build` - Build before review
- `/test` - Test before review
- `/commit` - Commit after review passes

## Configuration

Review configuration in `.claude/settings.json`:
```json
{
  "review": {
    "maxFunctionLines": 50,
    "requireDocumentation": true,
    "enforceNamingConventions": true,
    "checkCrossPlatformParity": true,
    "securityChecks": true
  }
}
```

## Exclusions

Files excluded from review (auto-generated, third-party):
- `*.generated.kt`
- `*.generated.swift`
- `build/`
- `.build/`
- `node_modules/`
- `Pods/`

## Review History

Review results saved to:
```
.claude/reviews/
├── 2024-01-15-feature-gallery.md
├── 2024-01-16-fix-styling.md
└── 2024-01-17-refactor-layout.md
```

## Continuous Improvement

Use review data to:
1. Identify common mistakes
2. Update documentation
3. Add linting rules
4. Improve code templates
5. Enhance training materials

## Advanced Features

### Diff-Based Review
Reviews only changed lines, not entire files

### Context-Aware Review
Understands feature context from commit history

### Pattern Recognition
Identifies common anti-patterns from past reviews

### Suggestion Mode
Provides fix suggestions with code snippets
