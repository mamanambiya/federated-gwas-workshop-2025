# Federated GWAS Workshop 2025

🧬 **A comprehensive WDL-based pipeline for federated genome-wide association studies (GWAS)**

Developed for the **GA4GH Hackathon 2025** by the **African Genomics Team** at the University of Cape Town.

## 🎯 Overview

This repository contains a complete, production-ready GWAS analysis pipeline designed for federated genomic research. The pipeline is built using the **Workflow Description Language (WDL)** and includes containerized tools, automated testing, and comprehensive documentation.

### ✨ Key Features

- 🔬 **Complete GWAS Pipeline**: Quality control, population stratification, association testing, and results processing
- 🐳 **Containerized**: Docker containers with PLINK, R, Python, and all dependencies
- 🔄 **Multi-Registry Support**: Compatible with both DockerHub and GitHub Container Registry
- 🤖 **Automated CI/CD**: GitHub Actions for building, testing, and security scanning
- 🧪 **Ready-to-Use Test Data**: Includes gensetB dataset for immediate testing
- 📊 **Rich Visualizations**: Manhattan plots, QQ plots, PCA plots, and QC reports
- 🌍 **Federated Ready**: Designed for distributed genomic analysis
- 📚 **Comprehensive Documentation**: Detailed usage guides and setup instructions

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Cromwell](https://github.com/broadinstitute/cromwell) (85+) or [miniwdl](https://github.com/chanzuckerberg/miniwdl)
- 8GB+ RAM and 4+ CPU cores recommended

### Option 1: Quick Test with Provided Data

```bash
# Clone the repository
git clone https://github.com/mamanambiya/federated-gwas-workshop-2025.git
cd federated-gwas-workshop-2025

# Run with test data (gensetB dataset)
./scripts/test_gensetB.sh
```

### Option 2: Docker Registry Options

```bash
# Using DockerHub (default)
./scripts/run_pipeline.sh inputs/test_gensetB.json

# Using GitHub Container Registry
./scripts/run_pipeline.sh inputs/test_gensetB_ghcr.json
```

### Option 3: Manual Execution

```bash
# Download Cromwell (if not already installed)
wget -O cromwell.jar https://github.com/broadinstitute/cromwell/releases/download/85/cromwell-85.jar

# Run the workflow
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i inputs/test_gensetB.json
```

## 📁 Repository Structure

```
federated-gwas-workshop-2025/
├── .github/workflows/          # CI/CD automation
│   ├── docker-build.yml        # Multi-registry Docker builds
│   └── security-scan.yml       # Security scanning
├── docker/                     # Container configuration
│   ├── Dockerfile              # GWAS tools container
│   └── README.md               # Docker documentation
├── workflows/                  # WDL workflows
│   └── gwas_pipeline.wdl       # Main GWAS pipeline
├── tasks/                      # Individual WDL tasks
│   ├── quality_control.wdl     # QC and filtering
│   ├── population_stratification.wdl  # PCA analysis
│   ├── association_testing.wdl # GWAS analysis
│   └── results_processing.wdl  # Results and plots
├── inputs/                     # Configuration files
│   ├── test_gensetB.json       # DockerHub config
│   ├── test_gensetB_ghcr.json  # GitHub Registry config
│   └── test_local.json         # Local testing template
├── scripts/                    # Execution scripts
│   ├── run_pipeline.sh         # Main execution script
│   ├── test_gensetB.sh         # Test with gensetB data
│   ├── test_ghcr.sh           # GitHub Registry testing
│   ├── test_docker_build.sh    # Local Docker testing
│   └── validate_inputs.sh      # Input validation
├── tests/data/                 # Test datasets
│   ├── gensetB.bed/bim/fam     # PLINK genotype files
│   ├── gensetB_phenotypes.txt  # Phenotype data
│   └── gensetB_covariates.txt  # Covariate data
├── docs/                       # Documentation
│   ├── USAGE.md                # Detailed usage guide
│   ├── DOCKER_CI_SETUP.md      # CI/CD setup instructions
│   └── GITHUB_CONTAINER_REGISTRY.md  # Registry guide
└── README.md                   # This file
```

## 🔬 Pipeline Workflow

### 1. Quality Control (`tasks/quality_control.wdl`)
- **Input validation** and format conversion (VCF → PLINK if needed)
- **Variant filtering**: MAF, call rate, Hardy-Weinberg equilibrium
- **Sample filtering**: Relatedness, missing data
- **QC reports and plots**: Distribution plots, summary statistics

### 2. Population Stratification (`tasks/population_stratification.wdl`)
- **LD pruning**: Remove correlated variants for PCA
- **Principal Component Analysis**: Calculate population structure
- **Outlier detection**: Identify population outliers
- **PCA plots**: Visualize population structure and variance explained

### 3. Association Testing (`tasks/association_testing.wdl`)
- **Covariate integration**: Merge phenotypes, covariates, and PCs
- **Statistical testing**: Linear/logistic regression using PLINK
- **Results processing**: Standardize output format
- **Quality metrics**: Calculate genomic inflation factor (λ)

### 4. Results Processing (`tasks/results_processing.wdl`)
- **Visualization**: Manhattan plots, QQ plots
- **Hit identification**: Genome-wide significant variants
- **Meta-analysis prep**: Standardized output format
- **Summary reports**: Comprehensive analysis summary

## 🐳 Docker Support

### Multi-Registry Configuration

The pipeline supports both DockerHub and GitHub Container Registry:

| Registry | Image | Usage |
|----------|-------|-------|
| **DockerHub** | `mamana/gwas-tools:latest` | Traditional registry |
| **GitHub Container Registry** | `ghcr.io/mamanambiya/gwas-tools:latest` | GitHub-integrated |

### Included Tools

- **PLINK 2.0**: Genomic analysis toolkit
- **bcftools**: VCF/BCF manipulation
- **R**: Statistical computing with genomics packages
- **Python**: Data processing and analysis
- **System tools**: Standard Linux utilities

## 🧪 Test Data

The repository includes the **gensetB** dataset:

- **Samples**: 165 individuals
- **Variants**: 10,000+ SNPs
- **Format**: PLINK binary files (.bed/.bim/.fam)
- **Phenotypes**: Quantitative trait
- **Covariates**: Sex, age, batch effects

## 📊 Expected Outputs

### Quality Control
- `*_qc_report.txt`: Summary statistics
- `*_qc_plots.pdf`: QC distribution plots
- `*.bed/bim/fam`: Filtered genotype files

### Population Stratification
- `*.eigenvec`: Principal components
- `*.eigenval`: Eigenvalues
- `*_plots.pdf`: PCA plots and scree plot

### Association Results
- `*_processed.txt`: GWAS results
- `*_manhattan.pdf/.png`: Manhattan plot
- `*_qq.pdf/.png`: QQ plot
- `*_top_hits.txt`: Significant associations
- `*_meta_ready.txt`: Meta-analysis format

## 🌍 Platform Compatibility

This pipeline is tested and compatible with:

- ✅ **Local execution**: Cromwell, miniwdl
- ✅ **Terra/AnVIL**: Google Cloud platform
- ✅ **DNAstack**: Workbench platform
- ✅ **AWS Batch**: Amazon cloud platform
- ✅ **Azure**: Microsoft cloud platform
- ✅ **HPC clusters**: SLURM, PBS, SGE

## 📚 Documentation

- **[Usage Guide](docs/USAGE.md)**: Detailed instructions for running the pipeline
- **[Docker CI Setup](docs/DOCKER_CI_SETUP.md)**: GitHub Actions configuration
- **[GitHub Container Registry](docs/GITHUB_CONTAINER_REGISTRY.md)**: Registry setup and usage
- **[Project Structure](PROJECT_STRUCTURE.md)**: Directory organization
- **[Quick Start Guide](QUICKSTART_GENSETB.md)**: Fast setup with test data

## 🤝 Contributing

We welcome contributions from the genomics community! This project follows open science principles.

### Getting Started
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Areas for Contribution
- Additional quality control metrics
- Support for additional file formats
- Performance optimizations
- Documentation improvements
- Integration with other genomics tools

## 🔧 Configuration

### Runtime Resources

Default resource allocations:
- **CPU**: 4 cores
- **Memory**: 16GB RAM
- **Disk**: 50GB SSD
- **Docker**: `mamana/gwas-tools:latest`

### Customization

All parameters can be customized via input JSON:

```json
{
  "GWASPipeline.cpu": 8,
  "GWASPipeline.memory_gb": 32,
  "GWASPipeline.maf_threshold": 0.005,
  "GWASPipeline.pvalue_threshold": 1e-8,
  "GWASPipeline.docker_image": "ghcr.io/mamanambiya/gwas-tools:latest"
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Docker permission errors**: Ensure Docker is running and user has permissions
2. **Memory errors**: Increase memory allocation for large datasets
3. **File not found**: Check file paths in input JSON
4. **Network issues**: Verify Docker image accessibility

### Getting Help

- **GitHub Issues**: Report bugs and request features
- **Discussions**: Community support and questions
- **Documentation**: Comprehensive guides in `docs/`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **GA4GH**: Global Alliance for Genomics and Health
- **University of Cape Town**: African genomics research
- **PLINK Development Team**: Genomic analysis tools
- **Broad Institute**: Cromwell workflow engine
- **Docker Community**: Containerization platform

## 📞 Contact

- **Author**: Mamana Mbiyavanga
- **Email**: mamana.mbiyavanga@uct.ac.za
- **Institution**: University of Cape Town
- **GitHub**: [@mamanambiya](https://github.com/mamanambiya)

## 🧬 Citation

If you use this pipeline in your research, please cite:

```
Mbiyavanga, M. et al. (2025). Federated GWAS Workshop 2025: A WDL-based pipeline 
for federated genome-wide association studies. GA4GH Hackathon 2025.
```

---

**Ready to revolutionize federated genomics research!** 🌍🧬 # federated-gwas-workshop-2025
# federated-gwas-workshop-2025
