#!/bin/bash

## Test Script for GitHub Container Registry (GHCR)
## GA4GH Hackathon 2025 - African Genomics Team

set -euo pipefail

echo "🐳 Testing GWAS Pipeline with GitHub Container Registry"
echo "======================================================"
echo ""

# Check if we're in the right directory
if [[ ! -f "workflows/gwas_pipeline.wdl" ]]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Dataset information
DATASET="gensetB"
INPUT_JSON="inputs/test_${DATASET}_ghcr.json"

echo "📊 Dataset Information:"
echo "  Name: $DATASET"
echo "  Samples: $(wc -l < tests/data/${DATASET}.fam)"
echo "  Variants: $(wc -l < tests/data/${DATASET}.bim)"
echo "  Size: $(du -h tests/data/${DATASET}.bed | cut -f1)"
echo ""

echo "🐳 Registry Information:"
echo "  Registry: GitHub Container Registry (ghcr.io)"
echo "  Image: ghcr.io/mamana/gwas-tools:latest"
echo "  Authentication: GitHub Token (automatic for public images)"
echo ""

# Check if image is accessible
echo "🔍 Testing Docker image access..."
if docker pull ghcr.io/mamana/gwas-tools:latest >/dev/null 2>&1; then
    echo "✅ Successfully pulled image from GitHub Container Registry"
elif docker images ghcr.io/mamana/gwas-tools:latest --format "{{.Repository}}" 2>/dev/null | grep -q "ghcr.io/mamana/gwas-tools"; then
    echo "✅ Image already available locally"
else
    echo "⚠️  Cannot pull image from GitHub Container Registry"
    echo "   This is expected if the image hasn't been published yet"
    echo "   Falling back to local build or DockerHub..."
    
    # Check if DockerHub image is available as fallback
    if docker pull mamana/gwas-tools:latest >/dev/null 2>&1; then
        echo "✅ Using DockerHub image as fallback"
        # Update the input JSON to use DockerHub temporarily
        sed 's|ghcr.io/mamana/gwas-tools|mamana/gwas-tools|g' "$INPUT_JSON" > "${INPUT_JSON}.fallback"
        INPUT_JSON="${INPUT_JSON}.fallback"
    else
        echo "❌ No Docker image available. Please build locally first:"
        echo "   ./scripts/test_docker_build.sh"
        exit 1
    fi
fi

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
echo "  Docker registry: GitHub Container Registry"
echo ""

# Compare with DockerHub approach
echo "🔄 Registry Comparison:"
echo "  GitHub Container Registry Benefits:"
echo "    ✅ Integrated with GitHub (same authentication)"
echo "    ✅ Better integration with GitHub Actions"
echo "    ✅ Free private repositories"
echo "    ✅ Better bandwidth limits"
echo "    ✅ Built-in vulnerability scanning"
echo ""
echo "  Usage in WDL:"
echo "    DockerHub:     docker: \"mamana/gwas-tools:latest\""
echo "    GHCR:          docker: \"ghcr.io/mamana/gwas-tools:latest\""
echo ""

# Estimate runtime
echo "⏱️  Step 3: Runtime Estimation"
echo "  Expected pipeline duration: ~30-60 minutes"
echo "  Registry pull time: ~2-5 minutes (first time)"
echo "  Quality Control: ~5-10 minutes"
echo "  Population Stratification: ~10-15 minutes"
echo "  Association Testing: ~15-30 minutes"
echo "  Results Processing: ~2-5 minutes"
echo ""

# Ask for confirmation
read -p "🚀 Ready to run GWAS pipeline with GitHub Container Registry? [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Pipeline execution cancelled."
    
    # Cleanup fallback file if created
    if [[ -f "${INPUT_JSON}.fallback" ]]; then
        rm "${INPUT_JSON}.fallback"
    fi
    
    exit 0
fi

echo ""
echo "🚀 Starting GWAS Pipeline execution..."
echo "   Using GitHub Container Registry: ghcr.io/mamana/gwas-tools:latest"
echo "   This may take 30-60 minutes depending on your system."
echo "   Progress will be logged to outputs/test_${DATASET}_ghcr_$(date +%Y%m%d_%H%M%S)/cromwell.log"
echo ""

# Run the pipeline
./scripts/run_pipeline.sh "$INPUT_JSON"

EXIT_CODE=$?

# Cleanup fallback file if created
if [[ -f "${INPUT_JSON}.fallback" ]]; then
    rm "${INPUT_JSON}.fallback"
fi

if [[ $EXIT_CODE -eq 0 ]]; then
    echo ""
    echo "🎉 gensetB GWAS Analysis with GitHub Container Registry Completed Successfully!"
    echo ""
    echo "📋 Registry Advantages Demonstrated:"
    echo "  ✅ Seamless GitHub integration"
    echo "  ✅ Unified authentication with repository"
    echo "  ✅ Same Docker image, different registry"
    echo "  ✅ Better integration with CI/CD pipeline"
    echo ""
    echo "📊 Key Output Files:"
    echo "  - *_qc_report.txt: Quality control summary"
    echo "  - *_manhattan.pdf: Manhattan plot"
    echo "  - *_qq.pdf: QQ plot"
    echo "  - *_top_hits.txt: Genome-wide significant results"
    echo "  - *_meta_ready.txt: Meta-analysis ready format"
    echo ""
    echo "🔄 Registry Migration Notes:"
    echo "  - Same workflow, different image source"
    echo "  - No changes needed to WDL logic"
    echo "  - Only docker runtime specification changes"
    echo "  - Can mix registries in multi-workflow projects"
else
    echo ""
    echo "❌ Pipeline failed with exit code: $EXIT_CODE"
    echo "   Check the cromwell execution logs for details"
    echo "   Registry issues are rare - likely workflow-specific"
fi

exit $EXIT_CODE 