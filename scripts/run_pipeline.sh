#!/bin/bash

## Federated GWAS Analysis Pipeline Execution Script
## GA4GH Hackathon 2025 - African Genomics Team

set -euo pipefail

echo "🧬 Federated GWAS Analysis Pipeline"
echo "GA4GH Hackathon 2025 - African Genomics Team"
echo ""

# Check if workflow file exists
if [[ ! -f "workflows/gwas_pipeline.wdl" ]]; then
    echo "❌ Workflow file not found: workflows/gwas_pipeline.wdl"
    exit 1
fi

# Default inputs
INPUTS=${1:-"inputs/test_local.json"}

if [[ ! -f "$INPUTS" ]]; then
    echo "❌ Input file not found: $INPUTS"
    echo "Usage: $0 [input_file.json]"
    echo ""
    echo "Example input files:"
    echo "  inputs/test_local.json - Test with local data"
    echo "  inputs/production.json - Production run"
    exit 1
fi

echo "Workflow: workflows/gwas_pipeline.wdl"
echo "Inputs: $INPUTS"
echo ""

# Check for Cromwell
if [[ ! -f "cromwell.jar" ]]; then
    echo "📥 Downloading Cromwell..."
    wget -O cromwell.jar https://github.com/broadinstitute/cromwell/releases/download/85/cromwell-85.jar
fi

# Pull container
echo "🐳 Checking Docker container..."
if command -v docker &> /dev/null; then
    docker pull ghcr.io/mamanambiya/gwas-tools:latest || echo "Warning: Could not pull container. Continuing with local version."
else
    echo "Warning: Docker not found. Make sure the container is available in your execution environment."
fi

# Create output directory with timestamp
OUTPUT_DIR="outputs/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Validate WDL syntax (if womtool is available)
if command -v womtool &> /dev/null; then
    echo "🔍 Validating WDL syntax..."
    womtool validate workflows/gwas_pipeline.wdl
fi

echo "🚀 Starting GWAS workflow execution..."
echo "Output directory: $OUTPUT_DIR"
echo ""

# Run the workflow
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i "$INPUTS" \
    --options cromwell.options.json 2>&1 | tee "$OUTPUT_DIR/cromwell.log"

EXIT_CODE=${PIPESTATUS[0]}

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "✅ GWAS workflow completed successfully!"
    echo ""
    echo "📊 Results summary:"
    echo "  - Execution log: $OUTPUT_DIR/cromwell.log"
    echo "  - Workflow outputs: check cromwell-executions/ directory"
    echo "  - Output directory: $OUTPUT_DIR"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Review QC reports and plots"
    echo "  2. Examine association results and Manhattan plots"  
    echo "  3. Share meta-analysis ready files for federated analysis"
    echo "  4. Review top hits for biological interpretation"
else
    echo ""
    echo "❌ GWAS workflow failed with exit code: $EXIT_CODE"
    echo "Check the log file for details: $OUTPUT_DIR/cromwell.log"
    exit $EXIT_CODE
fi 