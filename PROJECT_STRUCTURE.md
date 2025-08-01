# Federated GWAS Workshop 2025 - Project Structure

This project follows the same organizational structure as the `prepare_minimac4_data` reference project.

## Directory Structure

```
federated-gwas-workshop-2025/
├── README.md                    # Comprehensive project documentation
├── .gitignore                   # Git ignore patterns
├── cromwell.options.json        # Cromwell execution options
├── PROJECT_STRUCTURE.md         # This file
│
├── workflows/                   # Main WDL workflows
│   └── gwas_pipeline.wdl       # Main GWAS analysis workflow
│
├── tasks/                       # Individual WDL task definitions
│   ├── quality_control.wdl     # QC filtering and validation
│   ├── population_stratification.wdl  # PCA analysis
│   ├── association_testing.wdl # GWAS analysis
│   └── results_processing.wdl  # Post-processing and visualization
│
├── inputs/                      # Input configuration files
│   └── test_local.json         # Test input parameters
│
├── scripts/                     # Execution and utility scripts
│   ├── run_pipeline.sh         # Main pipeline execution script
│   └── validate_inputs.sh      # Input validation script
│
├── docker/                      # Container definitions
│   └── Dockerfile              # GWAS tools container
│
├── docs/                        # Additional documentation
│   └── USAGE.md                # Detailed usage guide
│
└── tests/                       # Test data and scripts (placeholder)
```

## Execution Directories (Auto-created)

These directories will be created automatically during workflow execution:

- `outputs/` - Final workflow outputs
- `cromwell-executions/` - Cromwell execution files
- `cromwell-workflow-logs/` - Workflow execution logs

## Key Files Description

### Main Workflow
- **`workflows/gwas_pipeline.wdl`** - Main workflow orchestrating the entire GWAS analysis pipeline

### Task Definitions
- **`tasks/quality_control.wdl`** - Quality control filtering (MAF, call rate, HWE, relatedness)
- **`tasks/population_stratification.wdl`** - Principal component analysis for ancestry
- **`tasks/association_testing.wdl`** - GWAS association testing (PLINK/BOLT/SAIGE)
- **`tasks/results_processing.wdl`** - Manhattan plots, QQ plots, meta-analysis formatting

### Configuration & Scripts
- **`inputs/test_local.json`** - Example input configuration
- **`scripts/run_pipeline.sh`** - Main execution script
- **`scripts/validate_inputs.sh`** - Pre-execution validation
- **`cromwell.options.json`** - Cromwell runtime options

### Container & Documentation
- **`docker/Dockerfile`** - Container with PLINK, R, bcftools, etc.
- **`README.md`** - Comprehensive project documentation
- **`docs/USAGE.md`** - Detailed usage instructions

## Usage Summary

1. **Prepare inputs**: Create JSON file with file paths and parameters
2. **Validate**: `./scripts/validate_inputs.sh inputs/my_study.json`
3. **Execute**: `./scripts/run_pipeline.sh inputs/my_study.json`
4. **Review**: Check outputs in `outputs/` directory

## Workflow Steps

1. **Quality Control** - Filter variants and samples
2. **Population Stratification** - Calculate principal components
3. **Association Testing** - Perform GWAS analysis
4. **Results Processing** - Generate plots and meta-analysis files

## Features

- 🧬 **Comprehensive GWAS pipeline** from QC to visualization
- 🐳 **Containerized execution** for reproducibility
- 📊 **Professional visualizations** (Manhattan, QQ plots)
- 🔗 **Federated analysis ready** with standardized outputs
- 🔍 **Input validation** and error checking
- 📚 **Extensive documentation** and examples
- 🌍 **African genomics optimized** for diverse populations

This structure enables easy deployment across different computing environments while maintaining consistency with established WDL workflow patterns. 