#!/bin/bash

## Input Validation Script for GWAS Pipeline
## GA4GH Hackathon 2025 - African Genomics Team

set -euo pipefail

echo "🔍 GWAS Pipeline Input Validation"
echo "================================="
echo ""

# Function to check if file exists
check_file() {
    local file_path="$1"
    local file_type="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo "❌ $file_type file not found: $file_path"
        return 1
    else
        echo "✅ $file_type file found: $file_path"
        return 0
    fi
}

# Function to validate JSON file
validate_json() {
    local json_file="$1"
    
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$json_file" > /dev/null 2>&1; then
            echo "✅ Input JSON is valid: $json_file"
            return 0
        else
            echo "❌ Invalid JSON format: $json_file"
            return 1
        fi
    else
        echo "⚠️  Cannot validate JSON (python3 not found)"
        return 0
    fi
}

# Function to check PLINK files
check_plink_files() {
    local bed_file="$1"
    local base_name="${bed_file%.bed}"
    
    check_file "$bed_file" "PLINK .bed"
    check_file "${base_name}.bim" "PLINK .bim"
    check_file "${base_name}.fam" "PLINK .fam"
}

# Function to validate phenotype file format
validate_phenotype_file() {
    local pheno_file="$1"
    local trait_name="$2"
    
    if [[ ! -f "$pheno_file" ]]; then
        echo "❌ Phenotype file not found: $pheno_file"
        return 1
    fi
    
    # Check if header exists and contains FID, IID
    if head -1 "$pheno_file" | grep -q "FID.*IID"; then
        echo "✅ Phenotype file has valid header"
    else
        echo "❌ Phenotype file missing FID/IID columns in header"
        return 1
    fi
    
    # Check if trait exists in header
    if head -1 "$pheno_file" | grep -q "$trait_name"; then
        echo "✅ Trait '$trait_name' found in phenotype file"
    else
        echo "❌ Trait '$trait_name' not found in phenotype file header"
        echo "Available columns: $(head -1 "$pheno_file")"
        return 1
    fi
    
    # Count samples
    local n_samples=$(($(wc -l < "$pheno_file") - 1))
    echo "📊 Number of samples in phenotype file: $n_samples"
}

# Function to validate covariate file
validate_covariate_file() {
    local covar_file="$1"
    
    if [[ ! -f "$covar_file" ]]; then
        echo "❌ Covariate file not found: $covar_file"
        return 1
    fi
    
    # Check if header exists and contains FID, IID
    if head -1 "$covar_file" | grep -q "FID.*IID"; then
        echo "✅ Covariate file has valid header"
    else
        echo "❌ Covariate file missing FID/IID columns in header"
        return 1
    fi
    
    # Count samples and covariates
    local n_samples=$(($(wc -l < "$covar_file") - 1))
    local n_covars=$(($(head -1 "$covar_file" | tr '\t' '\n' | wc -l) - 2))
    echo "📊 Number of samples in covariate file: $n_samples"
    echo "📊 Number of covariates: $n_covars"
}

# Main validation function
validate_inputs() {
    local json_file="$1"
    local errors=0
    
    echo "Validating input file: $json_file"
    echo ""
    
    # Validate JSON format
    if ! validate_json "$json_file"; then
        ((errors++))
    fi
    
    # Extract values from JSON (simple grep approach)
    local genotype_file=$(grep -o '"GWASPipeline.genotype_file":[^,]*' "$json_file" | cut -d'"' -f4)
    local phenotype_file=$(grep -o '"GWASPipeline.phenotype_file":[^,]*' "$json_file" | cut -d'"' -f4)
    local covariate_file=$(grep -o '"GWASPipeline.covariate_file":[^,]*' "$json_file" | cut -d'"' -f4)
    local trait_name=$(grep -o '"GWASPipeline.trait_name":[^,]*' "$json_file" | cut -d'"' -f4)
    local trait_type=$(grep -o '"GWASPipeline.trait_type":[^,]*' "$json_file" | cut -d'"' -f4)
    
    echo "Configuration:"
    echo "  Genotype file: $genotype_file"
    echo "  Phenotype file: $phenotype_file"
    echo "  Covariate file: $covariate_file"
    echo "  Trait name: $trait_name"
    echo "  Trait type: $trait_type"
    echo ""
    
    # Validate genotype files
    echo "📁 Validating genotype files..."
    if [[ "$genotype_file" == *.bed ]]; then
        if ! check_plink_files "$genotype_file"; then
            ((errors++))
        fi
    elif [[ "$genotype_file" == *.vcf.gz ]] || [[ "$genotype_file" == *.vcf ]]; then
        if ! check_file "$genotype_file" "VCF"; then
            ((errors++))
        fi
        # Check for index file
        if [[ "$genotype_file" == *.vcf.gz ]]; then
            if [[ -f "${genotype_file}.csi" ]] || [[ -f "${genotype_file}.tbi" ]]; then
                echo "✅ VCF index file found"
            else
                echo "⚠️  VCF index file not found (.csi or .tbi)"
            fi
        fi
    else
        echo "❌ Unsupported genotype file format: $genotype_file"
        echo "    Supported formats: .bed/.bim/.fam, .vcf.gz, .vcf"
        ((errors++))
    fi
    
    echo ""
    
    # Validate phenotype file
    echo "📋 Validating phenotype file..."
    if ! validate_phenotype_file "$phenotype_file" "$trait_name"; then
        ((errors++))
    fi
    
    echo ""
    
    # Validate covariate file
    echo "📊 Validating covariate file..."
    if ! validate_covariate_file "$covariate_file"; then
        ((errors++))
    fi
    
    echo ""
    
    # Validate trait type
    echo "🧬 Validating trait configuration..."
    if [[ "$trait_type" == "quantitative" ]] || [[ "$trait_type" == "binary" ]]; then
        echo "✅ Valid trait type: $trait_type"
    else
        echo "❌ Invalid trait type: $trait_type"
        echo "    Valid options: quantitative, binary"
        ((errors++))
    fi
    
    echo ""
    
    # Summary
    if [[ $errors -eq 0 ]]; then
        echo "🎉 All validations passed! Ready to run GWAS pipeline."
        return 0
    else
        echo "💥 Found $errors validation error(s). Please fix before running pipeline."
        return 1
    fi
}

# Usage
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <input.json>"
    echo ""
    echo "Example:"
    echo "  $0 inputs/test_local.json"
    exit 1
fi

validate_inputs "$1" 