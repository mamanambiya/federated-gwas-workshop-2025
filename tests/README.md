# Test Data for GWAS Pipeline

This directory contains test datasets for validating the GWAS pipeline functionality.

## gensetB Dataset

### Overview
- **Samples**: 2,003 individuals
- **Variants**: 1,154,245 SNPs
- **Genome coverage**: Genome-wide data
- **File size**: ~600MB total
- **Sample IDs**: HG00096, HG00097, ... (1000 Genomes Project format)

### Files Description

#### Genotype Data (PLINK Binary Format)
- `data/gensetB.bed` - Binary genotype file (551MB)
- `data/gensetB.bim` - Variant information file (31MB)
- `data/gensetB.fam` - Sample information file (61KB)

#### Phenotype Data
- `data/gensetB_phenotypes.txt` - Quantitative trait phenotypes
  - **Format**: Tab-separated (FID, IID, quantitative_trait)
  - **Trait**: Continuous values ranging from ~-3 to +3
  - **Samples**: 2,003 (including header)

#### Covariate Data
- `data/gensetB_covariates.txt` - Sample covariates
  - **Format**: Tab-separated (FID, IID, sex, age, batch)
  - **Sex**: 1=male, 2=female (from original .fam file)
  - **Age**: Simulated ages 20-49 years
  - **Batch**: Simulated batch effects (A, B, C)

### Dataset Characteristics

#### Sample Demographics
```bash
# Check sex distribution
awk 'NR>1 {if($3==1) male++; else female++} END {print "Males:", male, "Females:", female}' data/gensetB_covariates.txt
```

#### Variant Information
```bash
# Check chromosome distribution
awk '{print $1}' data/gensetB.bim | sort | uniq -c | head -10
```

#### Phenotype Distribution
```bash
# Check phenotype statistics
awk 'NR>1 {print $3}' data/gensetB_phenotypes.txt | sort -n | head -10
```

## Running Tests

### Quick Test (Validation Only)
```bash
# Validate input configuration
./scripts/validate_inputs.sh inputs/test_gensetB.json
```

### Full Pipeline Test
```bash
# Run complete GWAS analysis
./scripts/test_gensetB.sh
```

### Custom Test Run
```bash
# Run with custom parameters
./scripts/run_pipeline.sh inputs/test_gensetB.json
```

## Expected Runtime

- **Total Time**: 30-60 minutes (depending on system)
- **Quality Control**: 5-10 minutes
- **Population Stratification**: 10-15 minutes  
- **Association Testing**: 15-30 minutes
- **Results Processing**: 2-5 minutes

## Expected Outputs

### Quality Control
- Filtered to ~800K-1M variants (after MAF/HWE filters)
- ~1900-2000 samples (after relatedness filtering)
- QC plots showing MAF, call rate, HWE distributions

### Population Structure
- 10 principal components
- Population outliers identified
- PC plots showing population structure

### Association Results
- Genome-wide association results
- Manhattan plot with potential signals
- QQ plot for genomic inflation assessment
- Meta-analysis ready summary statistics

### Performance Benchmarks

System requirements for optimal performance:
- **CPU**: 4+ cores recommended
- **Memory**: 16GB+ recommended 
- **Storage**: 2GB+ free space for outputs
- **Runtime**: 30-60 minutes typical

## Troubleshooting

### Common Issues

1. **Memory Errors**
   - Reduce CPU cores: `"GWASPipeline.cpu": 2`
   - Increase memory: `"GWASPipeline.memory_gb": 32`

2. **Long Runtime**
   - Normal for this dataset size
   - Monitor progress in cromwell logs

3. **File Path Issues**
   - Ensure correct relative paths in `inputs/test_gensetB.json`
   - Check file permissions

### Validation Checks

The pipeline includes comprehensive validation:
- File existence and format validation
- Sample ID consistency across files
- Phenotype/covariate data integrity
- PLINK binary file validity

## Dataset Notes

- This is a **real genomic dataset** suitable for testing
- Phenotypes are **continuous/quantitative** (appropriate for linear regression)
- Contains population structure requiring PC correction
- Sufficient variant density for genome-wide analysis
- Sample size appropriate for detecting moderate effect sizes

## Federated Analysis Ready

The pipeline outputs are designed for federated GWAS:
- Summary statistics only (no individual-level data)
- Standardized meta-analysis format
- Privacy-preserving results sharing
- Compatible with common meta-analysis tools 