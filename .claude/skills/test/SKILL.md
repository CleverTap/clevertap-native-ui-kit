---
name: test
description: Run tests for Android or iOS SDK
user-invocable: true
disable-model-invocation: false
---

# Test Skill

Runs unit tests for Android or iOS Native Display SDK with clear result reporting.

## Usage

```bash
# Run both Android and iOS tests
/test

# Run only Android tests
/test android

# Run only iOS tests
/test ios

# Run specific test class (Android)
/test android VariableEvaluatorTest

# Run specific test class (iOS)
/test ios VariableEvaluatorTests
```

## What This Skill Does

1. **Detects Platform**
   - Automatically determines which platform to test based on context
   - Can test both platforms sequentially
   - Shows clear progress for each platform

2. **Runs Tests**
   - **Android**: `cd android && ./gradlew test`
   - **iOS**: `cd ios && swift test`
   - Captures full test output
   - Parses results for success/failure

3. **Reports Results**
   - Shows pass/fail counts
   - Lists failed tests with error messages
   - Provides file paths to failing tests
   - Suggests fixes for common failures

4. **Validation**
   - Ensures test environment is properly set up
   - Checks for required dependencies
   - Verifies test configurations

## Test Output Format

### Success
```
✅ Android Tests: PASSED
   - 45 tests passed
   - 0 tests failed
   - Duration: 12.3s

✅ iOS Tests: PASSED
   - 38 tests passed
   - 0 tests failed
   - Duration: 8.7s
```

### Failure
```
❌ Android Tests: FAILED
   - 43 tests passed
   - 2 tests failed
   - Duration: 11.8s

Failed Tests:
1. VariableEvaluatorTest.testNestedVariables
   Error: Expected "Hello John Doe" but got "Hello {{user.name}}"
   Location: android/sdk/src/test/kotlin/VariableEvaluatorTest.kt:45

2. StyleResolverTest.testInheritance
   Error: Text color not inherited from parent
   Location: android/sdk/src/test/kotlin/StyleResolverTest.kt:78
```

## Test Categories

### Unit Tests
- Model serialization/deserialization
- Variable evaluation
- Style resolution
- Layout calculations
- Template expression parsing

### Integration Tests
- End-to-end JSON parsing
- Complete rendering pipeline
- Cross-platform parity checks

### Performance Tests (if available)
- Rendering performance
- Memory usage
- Large configuration handling

## Common Test Failures

### 1. Serialization Errors
**Symptom**: JSON parsing fails
**Common Causes**:
- Missing @Serializable annotation (Kotlin)
- Missing Codable conformance (Swift)
- Incorrect property names

**Fix**: Check model definitions against JSON_STRUCTURE_REFERENCE.md

### 2. Variable Evaluation Errors
**Symptom**: Template expressions not resolved
**Common Causes**:
- Missing variable definitions
- Incorrect variable path
- Nested variable not supported

**Fix**: Check VariableEvaluator implementation

### 3. Style Resolution Errors
**Symptom**: Styles not applied correctly
**Common Causes**:
- Style cascading logic incorrect
- Theme not applied
- Style class not found

**Fix**: Check StyleResolver implementation

### 4. Layout Calculation Errors
**Symptom**: Dimensions calculated incorrectly
**Common Causes**:
- Wrong unit conversion
- Parent size not considered
- Percentage calculation off

**Fix**: Check LayoutCalculator implementation

## Test Commands

### Android (Gradle)
```bash
# All tests
cd android && ./gradlew test

# Specific module
cd android && ./gradlew :sdk:test

# Specific test class
cd android && ./gradlew test --tests VariableEvaluatorTest

# With detailed output
cd android && ./gradlew test --info

# Clean and test
cd android && ./gradlew clean test
```

### iOS (Swift)
```bash
# All tests
cd ios && swift test

# Specific test
cd ios && swift test --filter VariableEvaluatorTests

# With verbose output
cd ios && swift test --verbose

# Parallel execution
cd ios && swift test --parallel
```

## Test Coverage

When available, shows test coverage:
```
Android Coverage:
- Models: 95%
- Evaluators: 88%
- Resolvers: 92%
- Overall: 91%

iOS Coverage:
- Models: 93%
- Evaluators: 86%
- Resolvers: 90%
- Overall: 89%
```

## Integration with Development Workflow

### 1. Before Committing
```bash
# Always run tests before committing
/test

# If tests pass, commit
/commit
```

### 2. After Implementation
```bash
# Implement feature
# Run tests
/test android

# Fix any failures
# Run tests again
/test android
```

### 3. Cross-Platform Parity
```bash
# After Android implementation
/test android

# After iOS implementation
/test ios

# Verify both pass
/test
```

## CI/CD Integration

This skill's test commands are compatible with CI/CD pipelines:
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI

## Debugging Test Failures

### 1. Read Test Output
- Full error messages shown
- Stack traces included
- File paths provided

### 2. Check Test Files
- Navigate to failing test using file path
- Review test expectations
- Check implementation

### 3. Run Single Test
- Isolate failing test
- Add debug logging
- Re-run until fixed

### 4. Verify Against Spec
- Check `.claude/reference/` docs
- Ensure implementation matches spec
- Update tests if spec changed

## Best Practices

1. **Run tests frequently** during development
2. **Fix tests immediately** when they fail
3. **Add tests for new features** before implementation (TDD)
4. **Keep tests fast** by avoiding heavy operations
5. **Test both platforms** for parity
6. **Use descriptive test names** for clarity
7. **Mock external dependencies** to avoid flakiness

## Related Skills

- `/build` - Build before testing
- `/review` - Review code after tests pass
- `/commit` - Commit after tests pass

## Test Environment

### Android Requirements
- JDK 11 or higher
- Android Gradle Plugin
- Kotlin 1.9+

### iOS Requirements
- Xcode 15+
- Swift 5.9+
- Swift Package Manager

## Troubleshooting

### "Gradle not found"
```bash
cd android && chmod +x gradlew
```

### "Swift command not found"
Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Tests hanging"
- Check for infinite loops
- Look for deadlocks
- Verify async test completion

### "Flaky tests"
- Add proper waits for async operations
- Mock time-dependent code
- Remove test interdependencies
