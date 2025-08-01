# GWAS Pipeline Usage Guide

## Quick Start

### 1. Prepare Input Files

Your input files should follow these formats:

#### Genotype File
- **Format**: PLINK binary (.bed/.bim/.fam) or VCF (.vcf.gz)
- **Requirements**: bgzip compressed and indexed if VCF
- **Example**: `/path/to/genotypes.bed`

#### Phenotype File
Tab-separated file with columns:
- `FID`: Family ID
- `IID`: Individual ID  
- `[TRAIT_NAME]`: Trait values (numeric for quantitative, 0/1/2 for binary)

```
FID    IID    BMI    diabetes
FAM1   IND1   25.3   0
FAM2   IND2   30.1   1
FAM3   IND3   22.8   0
```

#### Covariate File
Tab-separated file with columns:
- `FID`: Family ID
- `IID`: Individual ID
- Additional covariate columns (age, sex, etc.)

```
FID    IID    age    sex    batch
FAM1   IND1   45     1      A
FAM2   IND2   52     2      B
FAM3   IND3   38     1      A
```

### 2. Create Input JSON

Copy and modify `inputs/test_local.json`:

```json
{
  "GWASPipeline.genotype_file": "/path/to/your/genotypes.bed",
  "GWASPipeline.phenotype_file": "/path/to/your/phenotypes.txt",
  "GWASPipeline.covariate_file": "/path/to/your/covariates.txt",
  "GWASPipeline.trait_name": "BMI",
  "GWASPipeline.trait_type": "quantitative",
  "GWASPipeline.output_prefix": "my_gwas_study"
}
```

### 3. Run Pipeline

```bash
# Basic run
./scripts/run_pipeline.sh inputs/my_study.json

# Or specify input file
./scripts/run_pipeline.sh inputs/custom_inputs.json
```

## Configuration Options

### Quality Control Parameters

```json
{
  "GWASPipeline.maf_threshold": 0.01,           // Minor allele frequency
  "GWASPipeline.call_rate_threshold": 0.95,    // Variant call rate
  "GWASPipeline.hwe_pvalue": 1e-6,             // Hardy-Weinberg equilibrium
  "GWASPipeline.relatedness_threshold": 0.125   // Kinship coefficient
}
```

### Population Stratification

```json
{
  "GWASPipeline.num_pcs": 10                    // Number of principal components
}
```

### Association Testing

```json
{
  "GWASPipeline.association_method": "linear",  // "linear", "logistic", "bolt", "saige"
  "GWASPipeline.trait_type": "quantitative",   // "quantitative" or "binary"
  "GWASPipeline.pvalue_threshold": 5e-8         // Genome-wide significance
}
```

### Runtime Configuration

```json
{
  "GWASPipeline.cpu": 4,                        // CPU cores
  "GWASPipeline.memory_gb": 16,                 // Memory in GB
  "GWASPipeline.docker_image": "mamana/gwas-tools:latest"
}
```

## Output Files

### Quality Control
- `*_qc_report.txt` - QC summary statistics
- `*_qc_plots.pdf` - MAF, call rate, HWE distributions
- `*_samples.txt` - List of samples passing QC

### Population Stratification  
- `*_pca_plots.pdf` - PC plots and scree plot
- `*_for_gwas.txt` - Principal components for GWAS
- `*_outliers.txt` - Population outliers

### Association Results
- `*_processed.txt` - Processed GWAS results
- `*_summary.txt` - Analysis summary
- `*_manhattan.pdf` - Manhattan plot
- `*_qq.pdf` - QQ plot

### Meta-Analysis Ready
- `*_meta_ready.txt` - Standardized format for meta-analysis
- `*_top_hits.txt` - Genome-wide significant results

## Troubleshooting

### Common Issues

1. **Memory Errors**
   - Increase `memory_gb` parameter
   - Use fewer CPU cores to allow more memory per core

2. **Container Issues**
   - Ensure Docker is running
   - Pull container manually: `docker pull mamana/gwas-tools:latest`

3. **File Format Issues**
   - Ensure VCF files are bgzip compressed
   - Check that sample IDs match between files
   - Verify phenotype file has correct trait name

4. **Execution Errors**
   - Check cromwell execution logs
   - Verify input file paths are absolute
   - Ensure sufficient disk space

### Performance Tips

- Use PLINK binary format (.bed/.bim/.fam) for faster processing
- Filter to common variants (MAF > 0.05) for initial analysis
- Consider chromosome-wise analysis for very large datasets
- Use appropriate significance thresholds (5e-8 for GWAS)

## Advanced Usage

### Cloud Execution

For Terra/AnVIL:
1. Import WDL workspace
2. Upload input files to bucket
3. Modify input JSON with gs:// paths
4. Run workflow

### HPC/Slurm

```bash
# Submit to cluster
sbatch --job-name=gwas-pipeline scripts/submit_slurm.sh inputs/production.json
```

### Custom Containers

Build your own container:
```bash
cd docker/
docker build -t my-gwas-tools .
```

Update input JSON:
```json
{
  "GWASPipeline.docker_image": "my-gwas-tools:latest"
}
``` 