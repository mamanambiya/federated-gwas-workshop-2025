# GWAS Tools Container

**Docker image for federated genome-wide association studies (GWAS) analysis**

[![Docker Build](https://github.com/your-org/federated-gwas-workshop-2025/actions/workflows/docker-build.yml/badge.svg)](https://github.com/your-org/federated-gwas-workshop-2025/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/mamana/gwas-tools)](https://hub.docker.com/r/mamana/gwas-tools)

## Overview

This container provides a complete environment for GWAS analysis optimized for federated research and African genomics populations. It includes all necessary tools for quality control, population stratification, association testing, and results visualization.

## Included Tools

### Genomics Software
- **PLINK 2.0** - Genetic association analysis
- **bcftools** - VCF/BCF manipulation and statistics
- **htslib** - High-throughput sequencing data processing

### Analysis Environment
- **R** with essential packages:
  - `data.table` - Fast data manipulation
  - `ggplot2` - Professional visualizations
  - `dplyr` - Data transformation
  - `RColorBrewer` - Color palettes
  - `gridExtra` - Plot arrangements

- **Python 3** with scientific libraries:
  - `pandas` - Data analysis
  - `numpy` - Numerical computing
  - `scipy` - Scientific computing
  - `matplotlib` - Plotting
  - `seaborn` - Statistical visualizations

## Quick Start

### Pull and Run
```bash
# Pull the latest image
docker pull mamana/gwas-tools:latest

# Run interactive shell
docker run -it --rm mamana/gwas-tools:latest
```

### With WDL Workflow
```bash
# The container is designed to work with WDL workflows
java -jar cromwell.jar run gwas_pipeline.wdl -i inputs.json
```

### Volume Mounting for Data
```bash
# Mount your data directory
docker run -it --rm \
  -v /path/to/your/data:/data \
  -v /path/to/outputs:/outputs \
  mamana/gwas-tools:latest
```

## Use Cases

### Quality Control
- Variant and sample filtering by MAF, call rate, HWE
- Relatedness estimation and removal
- Missing data assessment
- Population outlier detection

### Population Stratification
- Principal component analysis (PCA)
- Ancestry inference
- Population structure visualization
- Outlier identification

### Association Testing
- Linear regression (quantitative traits)
- Logistic regression (binary traits)
- Covariate adjustment
- Population stratification correction

### Results Processing
- Manhattan plot generation
- QQ plot analysis
- Genomic inflation assessment
- Meta-analysis format preparation

## Supported Input Formats

- **Genotypes**: PLINK binary (.bed/.bim/.fam), VCF/BCF
- **Phenotypes**: Tab-separated text files
- **Covariates**: Tab-separated text files

## Output Formats

- **Summary Statistics**: Tab-separated, meta-analysis ready
- **Plots**: PDF, PNG formats
- **Reports**: HTML, text summaries
- **Intermediate**: PLINK binary, text formats

## Tags and Versions

- `latest` - Latest stable build from main branch
- `v1.0.0`, `v1.1.0` - Specific release versions
- `main-abc123` - Development builds with commit SHA

## Container Size
- **Base size**: ~2GB
- **Includes**: Complete R environment, PLINK 2.0, bcftools, Python scientific stack

## Architecture Support
- `linux/amd64` (Intel/AMD 64-bit)
- `linux/arm64` (ARM 64-bit, Apple Silicon)

## Performance Recommendations

### Resource Allocation
- **CPU**: 4+ cores recommended
- **Memory**: 16GB+ for large cohorts (>10K individuals)
- **Storage**: 2GB+ for outputs

### Optimization Tips
- Use PLINK binary format for faster processing
- Mount data volumes for I/O performance
- Allocate sufficient memory for large datasets
- Use multi-core processing when available

## Integration Examples

### Terra/AnVIL
```json
{
  "runtime": {
    "docker": "mamana/gwas-tools:latest",
    "memory": "16GB",
    "cpu": 4
  }
}
```

### Cromwell Local
```hocon
runtime {
  docker: "mamana/gwas-tools:latest"
  cpu: 4
  memory: "16GB"
}
```

### Nextflow
```nextflow
process gwas_qc {
  container 'mamana/gwas-tools:latest'
  
  input:
  path genotypes
  
  output:
  path "*.qc.*"
  
  script:
  """
  plink2 --bfile genotypes --maf 0.01 --make-bed --out filtered
  """
}
```

## Federated Analysis Features

This container is specifically designed for federated GWAS:
- **Privacy-preserving**: Generates only summary statistics
- **Standardized outputs**: Compatible with meta-analysis tools
- **Data sovereignty**: Raw data never leaves your institution
- **Harmonized formats**: Consistent allele coding and statistics

## Source Code

- **GitHub**: [federated-gwas-workshop-2025](https://github.com/your-org/federated-gwas-workshop-2025)
- **Documentation**: Complete WDL workflows and usage guides
- **Issues**: Bug reports and feature requests welcome

## Citation

If you use this container in your research, please cite:

```
@software{federated_gwas_tools_2025,
  title = {Federated GWAS Tools Container},
  author = {GA4GH Hackathon 2025 - African Genomics Team},
  year = {2025},
  url = {https://hub.docker.com/r/mamana/gwas-tools}
}
```

## License

MIT License - see repository for full details.

## Support

- **Documentation**: See GitHub repository
- **Issues**: GitHub Issues
- **Community**: GA4GH Forum 