#!/bin/bash

## Test Script for gensetB Dataset
## GA4GH Hackathon 2025 - African Genomics Team

set -euo pipefail

echo "🧬 Testing GWAS Pipeline with gensetB Dataset"
echo "============================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "workflows/gwas_pipeline.wdl" ]]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Dataset information
DATASET="gensetB"
INPUT_JSON="inputs/test_${DATASET}.json"

echo "📊 Dataset Information:"
echo "  Name: $DATASET"
echo "  Samples: $(wc -l < tests/data/${DATASET}.fam)"
echo "  Variants: $(wc -l < tests/data/${DATASET}.bim)"
echo "  Size: $(du -h tests/data/${DATASET}.bed | cut -f1)"
echo ""

# Validate input files
echo "🔍 Step 1: Validating input files..."
if ./scripts/validate_inputs.sh "$INPUT_JSON"; then
    echo "✅ Input validation passed!"
else
    echo "❌ Input validation failed!"
    exit 1
fi

echo ""

# Show configuration
echo "⚙️  Step 2: Configuration Overview"
echo "  Input JSON: $INPUT_JSON"
echo "  Genotype file: tests/data/${DATASET}.bed"
echo "  Phenotype file: tests/data/${DATASET}_phenotypes.txt"
echo "  Covariate file: tests/data/${DATASET}_covariates.txt"
echo "  Trait: quantitative_trait (continuous)"
echo ""

# Estimate runtime
echo "⏱️  Step 3: Runtime Estimation"
echo "  Expected pipeline duration: ~30-60 minutes"
echo "  Quality Control: ~5-10 minutes"
echo "  Population Stratification: ~10-15 minutes"
echo "  Association Testing: ~15-30 minutes"
echo "  Results Processing: ~2-5 minutes"
echo ""

# Ask for confirmation
read -p "🚀 Ready to run GWAS pipeline on $DATASET dataset? [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Pipeline execution cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting GWAS Pipeline execution..."
echo "   This may take 30-60 minutes depending on your system."
echo "   Progress will be logged to outputs/test_${DATASET}_$(date +%Y%m%d_%H%M%S)/cromwell.log"
echo ""

# Run the pipeline
./scripts/run_pipeline.sh "$INPUT_JSON"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "🎉 gensetB GWAS Analysis Completed Successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Check outputs/ directory for results"
    echo "  2. Review QC reports for data quality"
    echo "  3. Examine Manhattan and QQ plots"
    echo "  4. Check top hits for biological significance"
    echo "  5. Use meta-analysis ready files for federated analysis"
    echo ""
    echo "📊 Key Output Files:"
    echo "  - *_qc_report.txt: Quality control summary"
    echo "  - *_manhattan.pdf: Manhattan plot"
    echo "  - *_qq.pdf: QQ plot"
    echo "  - *_top_hits.txt: Genome-wide significant results"
    echo "  - *_meta_ready.txt: Meta-analysis ready format"
else
    echo ""
    echo "❌ Pipeline failed with exit code: $EXIT_CODE"
    echo "   Check the cromwell execution logs for details"
fi

exit $EXIT_CODE 