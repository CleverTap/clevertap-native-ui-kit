#!/bin/bash
# Generate test JSON configurations from templates

set -e

TEMPLATES_DIR=".claude/agents/testing/templates"
OUTPUT_DIR="test-configs/generated"

echo "Generating test configurations..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate container variations
for container_type in vertical horizontal box stack gallery; do
    for strategy in spaced space_between space_evenly space_around start center end; do
        output_file="$OUTPUT_DIR/container_${container_type}_${strategy}.json"

        # Use jq to modify template
        jq --arg type "$container_type" --arg strat "$strategy" '
            .root.containerType = $type |
            .root.arrangement.strategy = $strat
        ' "$TEMPLATES_DIR/container-test.json" > "$output_file"

        echo "Generated: $output_file"
    done
done

# Generate element variations
for element_type in text image button video spacer divider; do
    output_file="$OUTPUT_DIR/element_${element_type}.json"

    jq --arg type "$element_type" '
        .root.elementType = $type |
        del(.root.containerType) |
        del(.root.children)
    ' "$TEMPLATES_DIR/element-test.json" > "$output_file"

    echo "Generated: $output_file"
done

echo "Test generation complete!"
echo "Generated $(find $OUTPUT_DIR -name '*.json' | wc -l) test files"
