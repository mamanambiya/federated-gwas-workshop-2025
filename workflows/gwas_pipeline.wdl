version 1.0

## Federated GWAS Pipeline
## GA4GH Hackathon 2025 - African Genomics Team

import "tasks/quality_control.wdl" as QC
import "tasks/population_stratification.wdl" as PopStrat
import "tasks/association_testing.wdl" as Assoc
import "tasks/results_processing.wdl" as Results

workflow GWASPipeline {
    meta {
        author: "Mamana Mbiyavanga"
        email: "mamana.mbiyavanga@uct.ac.za"
        description: "Federated genome-wide association studies (GWAS) analysis pipeline"
        version: "1.0.0"
    }

    input {
        # Input files
        File genotype_file          # PLINK bed/bim/fam or VCF file
        File phenotype_file         # Tab-separated phenotype file
        File? covariate_file        # Optional covariate file
        
        # Trait information
        String trait_name           # Name of the trait column in phenotype file
        String trait_type = "quantitative"  # "quantitative" or "binary"
        
        # Quality control parameters
        Float maf_threshold = 0.01           # Minor allele frequency threshold
        Float call_rate_threshold = 0.95     # Variant call rate threshold
        Float hwe_pvalue = 1e-6              # Hardy-Weinberg equilibrium p-value
        Float relatedness_threshold = 0.125   # Relatedness threshold for pruning
        
        # Population stratification
        Int num_pcs = 10                     # Number of principal components
        
        # Association testing
        String association_method = "linear"  # "linear", "logistic", or "firth"
        Float pvalue_threshold = 5e-8         # Genome-wide significance threshold
        
        # Output options
        String output_prefix = "gwas_results"
        Boolean include_plots = true
        
        # Runtime parameters
        Int cpu = 4
        Int memory_gb = 16
        String docker_image = "mamana/gwas-tools:latest"
    }

    # Step 1: Quality Control
    call QC.QualityControlTask {
        input:
            genotype_file = genotype_file,
            maf_threshold = maf_threshold,
            call_rate_threshold = call_rate_threshold,
            hwe_pvalue = hwe_pvalue,
            relatedness_threshold = relatedness_threshold,
            output_prefix = output_prefix + "_qc",
            cpu = cpu,
            memory_gb = memory_gb,
            docker_image = docker_image
    }

    # Step 2: Population Stratification (PCA)
    call PopStrat.PopulationStratificationTask {
        input:
            genotype_file = QualityControlTask.filtered_genotype_prefix,
            num_pcs = num_pcs,
            output_prefix = output_prefix + "_pca",
            cpu = cpu,
            memory_gb = memory_gb,
            docker_image = docker_image
    }

    # Step 3: Association Testing
    call Assoc.AssociationTestingTask {
        input:
            genotype_file = QualityControlTask.filtered_genotype_prefix,
            phenotype_file = phenotype_file,
            covariate_file = covariate_file,
            pcs_file = PopulationStratificationTask.pcs_file,
            trait_name = trait_name,
            trait_type = trait_type,
            association_method = association_method,
            output_prefix = output_prefix + "_assoc",
            cpu = cpu,
            memory_gb = memory_gb,
            docker_image = docker_image
    }

    # Step 4: Results Processing and Visualization
    call Results.ResultsProcessingTask {
        input:
            gwas_results = AssociationTestingTask.association_results,
            pvalue_threshold = pvalue_threshold,
            include_plots = include_plots,
            output_prefix = output_prefix + "_final",
            cpu = cpu,
            memory_gb = memory_gb,
            docker_image = docker_image
    }

    output {
        # Quality control outputs
        File qc_report = QualityControlTask.qc_report
        File qc_plots = QualityControlTask.qc_plots
        File filtered_genotype_bed = QualityControlTask.filtered_bed
        File filtered_genotype_bim = QualityControlTask.filtered_bim
        File filtered_genotype_fam = QualityControlTask.filtered_fam

        # Population stratification outputs
        File pcs_file = PopulationStratificationTask.pcs_file
        File eigenvalues = PopulationStratificationTask.eigenvalues
        File pca_plots = PopulationStratificationTask.pca_plots
        File pca_report = PopulationStratificationTask.pca_report

        # Association testing outputs
        File association_results = AssociationTestingTask.association_results
        File association_summary = AssociationTestingTask.association_summary

        # Final processed results
        File manhattan_plot_pdf = ResultsProcessingTask.manhattan_plot_pdf
        File manhattan_plot_png = ResultsProcessingTask.manhattan_plot_png
        File qq_plot_pdf = ResultsProcessingTask.qq_plot_pdf
        File qq_plot_png = ResultsProcessingTask.qq_plot_png
        File top_hits = ResultsProcessingTask.top_hits
        File meta_analysis_ready = ResultsProcessingTask.meta_analysis_ready
        File results_summary = ResultsProcessingTask.results_summary
    }
} 