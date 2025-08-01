# Quick Start: GWAS Analysis with gensetB Dataset

## 🚀 Ready-to-Run Test

The GWAS pipeline is now configured with the gensetB dataset from your tests directory.

## 📊 Dataset Overview

- **Sample Size**: 2,002 individuals
- **Variants**: 1,154,245 SNPs (genome-wide coverage)
- **Data Size**: 561MB genotype data
- **Phenotype**: Quantitative trait (range: -3.13 to +3.11, mean: -0.02)
- **Sex Distribution**: 971 males, 1,031 females
- **Chromosomes**: Genome-wide coverage (chr1-22)

## ⚡ Three Ways to Run

### 1. Full Interactive Test (Recommended)
```bash
./scripts/test_gensetB.sh
```
*Includes validation, dataset info, and interactive confirmation*

### 2. Direct Pipeline Execution
```bash
./scripts/run_pipeline.sh inputs/test_gensetB.json
```
*Direct execution of the GWAS pipeline*

### 3. Validation Only (Quick Check)
```bash
./scripts/validate_inputs.sh inputs/test_gensetB.json
```
*Verify configuration without running analysis*

## ⏱️ Expected Timeline

- **Total Runtime**: 30-60 minutes
- **Quality Control**: 5-10 min (filtering ~1.1M → ~800K variants)
- **Population Stratification**: 10-15 min (calculating 10 PCs)
- **Association Testing**: 15-30 min (linear regression)
- **Results Processing**: 2-5 min (plots + meta-analysis files)

## 📁 Generated Outputs

### Quality Control Results
- `*_qc_report.txt` - Summary statistics
- `*_qc_plots.pdf` - MAF, call rate, HWE distributions

### Population Stratification
- `*_pca_plots.pdf` - PC plots and scree plot
- `*_for_gwas.txt` - Principal components for analysis

### GWAS Results
- `*_manhattan.pdf` - Manhattan plot
- `*_qq.pdf` - QQ plot (genomic inflation)
- `*_processed.txt` - Full association results
- `*_top_hits.txt` - Significant associations

### Meta-Analysis Ready
- `*_meta_ready.txt` - Standardized summary statistics
- `*_summary.txt` - Analysis report

## 🔧 Pre-configured Settings

The test is optimized for the gensetB dataset:

```json
{
  "trait_name": "quantitative_trait",
  "trait_type": "quantitative",
  "maf_threshold": 0.01,
  "call_rate_threshold": 0.95,
  "hwe_pvalue": 1e-6,
  "relatedness_threshold": 0.125,
  "num_pcs": 10,
  "association_method": "linear"
}
```

## 🎯 What to Expect

### Quality Control
- ~300K variants removed (low MAF/HWE/call rate)
- ~50-100 samples removed (relatedness/missing data)
- Final dataset: ~800K variants, ~1900 samples

### Population Structure
- 10 principal components calculated
- Population outliers identified and removed
- PC plots showing genetic ancestry structure

### Association Results
- Genome-wide association testing completed
- Manhattan plot with potential association signals
- QQ plot for assessing genomic inflation (λ)
- Summary statistics ready for meta-analysis

## 🔄 Federated Analysis Ready

The pipeline generates privacy-preserving outputs perfect for federated GWAS:
- ✅ Only summary statistics (no individual data)
- ✅ Standardized meta-analysis format
- ✅ Harmonized allele coding
- ✅ Compatible with common meta-analysis tools

## 🚨 System Requirements

- **CPU**: 4+ cores recommended
- **Memory**: 16GB+ recommended
- **Storage**: 2GB+ free space for outputs
- **Docker**: Required for containerized execution

## 🆘 Need Help?

```bash
# Check dataset details
cat tests/README.md

# View full documentation
cat README.md

# Check project structure
cat PROJECT_STRUCTURE.md
```

## 🎉 Ready to Start!

Run the interactive test to begin your GWAS analysis:

```bash
./scripts/test_gensetB.sh
```

The pipeline will guide you through validation, execution, and results interpretation! 