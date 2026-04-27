# Generate Test Variations

## Task
Generate N test variations to comprehensively test [FEATURE].

## Process

1. **Identify Test Dimensions**
   - What parameters vary?
   - What are valid values for each?
   - What combinations are important?

2. **Create Template JSON**
   ```json
   {
     "_comment": "Template for [feature] testing",
     "_variations": {
       "param1": ["value1", "value2"],
       "param2": [0, 10, 20]
     },
     "root": { ... }
   }
   ```

3. **Generate Variations**
   - Use script or tool to generate combinations
   - Save each variation with descriptive name
   - Example: `container_vertical_spaced_8.json`

4. **Validate All Variations**
   ```bash
   for file in test-configs/generated/*.json; do
       echo "Validating $file"
       jq empty "$file" || echo "Invalid: $file"
   done
   ```

## Example: Container Arrangements

**Dimensions**:
- Container type: 5 values (vertical, horizontal, box, stack, gallery)
- Strategy: 7 values (spaced, space_between, ...)
- Spacing: 4 values (0, 8, 16, 24)

**Total**: 5 × 7 × 4 = 140 test files

**Generation**:
```bash
./scripts/generate-container-tests.sh
```

## Output
- `test-configs/generated/` - All generated test files
- `test-configs/generated/INDEX.md` - Index of all tests
- `test-configs/generated/summary.json` - Test metadata

## Validation
- All JSON files parseable
- All variations unique
- Coverage complete (all combinations)
- File names match content
