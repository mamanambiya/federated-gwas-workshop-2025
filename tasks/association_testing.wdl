version 1.0

## Perform genome-wide association study (GWAS) analysis
task AssociationTesting {
    input {
        File genotype_file      # PLINK .bed file
        File phenotype_file     # Phenotype file
        File covariate_file     # Covariate file
        File pcs_file          # Principal components file
        String trait_name
        String trait_type      # "binary" or "quantitative"
        String association_method = "linear"  # "linear", "logistic", "bolt", "saige"
        String output_prefix = "gwas_results"
        Int cpu = 4
        Int memory_gb = 16
        String docker_image = "mamana/gwas-tools:latest"
    }

    command <<<
        set -euo pipefail
        
        echo "🧬 Starting GWAS Association Testing"
        echo "Input genotype file: ~{genotype_file}"
        echo "Phenotype file: ~{phenotype_file}"
        echo "Trait: ~{trait_name} (~{trait_type})"
        echo "Association method: ~{association_method}"
        echo "Output prefix: ~{output_prefix}"
        echo ""
        
        # Set up file paths
        BASENAME=$(basename "~{genotype_file}" .bed)
        DIRNAME=$(dirname "~{genotype_file}")
        
        # Copy PLINK files to working directory
        cp "$DIRNAME/$BASENAME.bed" input.bed
        cp "$DIRNAME/$BASENAME.bim" input.bim
        cp "$DIRNAME/$BASENAME.fam" input.fam
        
        # Step 1: Prepare covariate file by merging covariates with PCs
        echo "📋 Preparing covariate file with principal components..."
        
        cat > merge_covariates.R << 'EOF'
        library(data.table)
        
        # Read files
        covariates <- fread("~{covariate_file}")
        pcs <- fread("~{pcs_file}")
        
        # Merge covariates with PCs
        merged <- merge(covariates, pcs, by=c("FID", "IID"), all.x=TRUE)
        
        # Write merged covariate file
        fwrite(merged, "merged_covariates.txt", sep="\t")
        
        # Create covariate names list for PLINK
        covar_names <- names(merged)[!names(merged) %in% c("FID", "IID")]
        cat(covar_names, sep=",", file="covariate_names.txt")
        
        print(paste("Merged covariates with", length(covar_names), "variables"))
        print(paste("Covariate names:", paste(covar_names, collapse=", ")))
        EOF
        
        Rscript merge_covariates.R
        
        # Step 2: Perform association testing based on method
        echo "🔬 Performing association testing using ~{association_method}..."
        
        if [[ "~{association_method}" == "linear" ]] && [[ "~{trait_type}" == "quantitative" ]]; then
            echo "Running linear regression for quantitative trait..."
            plink2 --bfile input \
                --pheno "~{phenotype_file}" \
                --pheno-name "~{trait_name}" \
                --covar merged_covariates.txt \
                --covar-name $(cat covariate_names.txt) \
                --linear \
                --out "~{output_prefix}" \
                --memory ~{memory_gb * 1000} \
                --threads ~{cpu}
                
        elif [[ "~{association_method}" == "logistic" ]] && [[ "~{trait_type}" == "binary" ]]; then
            echo "Running logistic regression for binary trait..."
            plink2 --bfile input \
                --pheno "~{phenotype_file}" \
                --pheno-name "~{trait_name}" \
                --covar merged_covariates.txt \
                --covar-name $(cat covariate_names.txt) \
                --logistic \
                --out "~{output_prefix}" \
                --memory ~{memory_gb * 1000} \
                --threads ~{cpu}
                
        elif [[ "~{association_method}" == "bolt" ]]; then
            echo "Running BOLT-LMM for mixed model association..."
            
            # Convert PLINK to BOLT format if needed
            # Note: This would require BOLT-LMM to be installed in the container
            echo "Warning: BOLT-LMM requires specific installation. Using PLINK GLM instead."
            
            if [[ "~{trait_type}" == "quantitative" ]]; then
                plink2 --bfile input \
                    --pheno "~{phenotype_file}" \
                    --pheno-name "~{trait_name}" \
                    --covar merged_covariates.txt \
                    --covar-name $(cat covariate_names.txt) \
                    --glm \
                    --out "~{output_prefix}" \
                    --memory ~{memory_gb * 1000} \
                    --threads ~{cpu}
            else
                plink2 --bfile input \
                    --pheno "~{phenotype_file}" \
                    --pheno-name "~{trait_name}" \
                    --covar merged_covariates.txt \
                    --covar-name $(cat covariate_names.txt) \
                    --glm \
                    --out "~{output_prefix}" \
                    --memory ~{memory_gb * 1000} \
                    --threads ~{cpu}
            fi
            
        elif [[ "~{association_method}" == "saige" ]]; then
            echo "Running SAIGE for mixed model association..."
            echo "Warning: SAIGE requires specific installation. Using PLINK GLM instead."
            
            if [[ "~{trait_type}" == "quantitative" ]]; then
                plink2 --bfile input \
                    --pheno "~{phenotype_file}" \
                    --pheno-name "~{trait_name}" \
                    --covar merged_covariates.txt \
                    --covar-name $(cat covariate_names.txt) \
                    --glm \
                    --out "~{output_prefix}" \
                    --memory ~{memory_gb * 1000} \
                    --threads ~{cpu}
            else
                plink2 --bfile input \
                    --pheno "~{phenotype_file}" \
                    --pheno-name "~{trait_name}" \
                    --covar merged_covariates.txt \
                    --covar-name $(cat covariate_names.txt) \
                    --glm \
                    --out "~{output_prefix}" \
                    --memory ~{memory_gb * 1000} \
                    --threads ~{cpu}
            fi
            
        else
            echo "Using default GLM method..."
            plink2 --bfile input \
                --pheno "~{phenotype_file}" \
                --pheno-name "~{trait_name}" \
                --covar merged_covariates.txt \
                --covar-name $(cat covariate_names.txt) \
                --glm \
                --out "~{output_prefix}" \
                --memory ~{memory_gb * 1000} \
                --threads ~{cpu}
        fi
        
        # Step 3: Process association results
        echo "📊 Processing association results..."
        
        cat > process_results.R << 'EOF'
        library(data.table)
        library(ggplot2)
        
        # Find the association results file
        result_files <- list.files(pattern="~{output_prefix}.*\\.assoc|\\.linear|\\.logistic|\\.glm")
        
        if(length(result_files) == 0) {
            # Try alternative patterns
            result_files <- list.files(pattern="~{output_prefix}")
            result_files <- result_files[grepl("\\.(assoc|linear|logistic|glm)", result_files)]
        }
        
        if(length(result_files) == 0) {
            stop("No association results file found!")
        }
        
        # Use the first matching file
        result_file <- result_files[1]
        cat("Processing results file:", result_file, "\n")
        
        # Read association results
        results <- fread(result_file)
        
        # Standardize column names based on file type
        if("P" %in% names(results)) {
            setnames(results, "P", "PVALUE")
        }
        if("#CHROM" %in% names(results)) {
            setnames(results, "#CHROM", "CHR")
        }
        if("POS" %in% names(results)) {
            setnames(results, "POS", "BP")
        }
        if("ID" %in% names(results)) {
            setnames(results, "ID", "SNP")
        }
        
        # Ensure required columns exist
        required_cols <- c("CHR", "BP", "SNP", "PVALUE")
        missing_cols <- required_cols[!required_cols %in% names(results)]
        
        if(length(missing_cols) > 0) {
            cat("Warning: Missing columns:", paste(missing_cols, collapse=", "), "\n")
            cat("Available columns:", paste(names(results), collapse=", "), "\n")
        }
        
        # Filter out missing p-values and extreme values
        results <- results[!is.na(PVALUE) & PVALUE > 0 & PVALUE <= 1]
        
        # Calculate -log10(p-values)
        results[, LOG10P := -log10(PVALUE)]
        
        # Add genomic control lambda
        chisq <- qchisq(1 - results$PVALUE, 1)
        lambda <- median(chisq, na.rm=TRUE) / qchisq(0.5, 1)
        
        # Sort by p-value
        results <- results[order(PVALUE)]
        
        # Save processed results
        fwrite(results, "~{output_prefix}_processed.txt", sep="\t")
        
        # Create summary statistics
        cat("GWAS Association Testing Summary\n", file="~{output_prefix}_summary.txt")
        cat("==============================\n", file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Trait:", "~{trait_name}", "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Trait type:", "~{trait_type}", "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Association method:", "~{association_method}", "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Total variants tested:", nrow(results), "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Genomic inflation factor (lambda):", round(lambda, 4), "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        
        # Count significant hits
        sig_5e8 <- sum(results$PVALUE < 5e-8, na.rm=TRUE)
        sig_1e6 <- sum(results$PVALUE < 1e-6, na.rm=TRUE)
        sig_1e5 <- sum(results$PVALUE < 1e-5, na.rm=TRUE)
        
        cat(paste("Genome-wide significant hits (p < 5e-8):", sig_5e8, "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Suggestive hits (p < 1e-6):", sig_1e6, "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        cat(paste("Nominally significant hits (p < 1e-5):", sig_1e5, "\n"), file="~{output_prefix}_summary.txt", append=TRUE)
        
        # Top 10 hits
        cat("\nTop 10 association signals:\n", file="~{output_prefix}_summary.txt", append=TRUE)
        cat("CHR\tBP\tSNP\tPVALUE\tLOG10P\n", file="~{output_prefix}_summary.txt", append=TRUE)
        
        top10 <- head(results[, .(CHR, BP, SNP, PVALUE, LOG10P)], 10)
        for(i in 1:nrow(top10)) {
            cat(paste(top10[i,CHR], top10[i,BP], top10[i,SNP], 
                     format(top10[i,PVALUE], scientific=TRUE, digits=3),
                     round(top10[i,LOG10P], 3), sep="\t"), 
                file="~{output_prefix}_summary.txt", append=TRUE)
            cat("\n", file="~{output_prefix}_summary.txt", append=TRUE)
        }
        
        cat("Association testing completed successfully!\n")
        EOF
        
        Rscript process_results.R
        
        echo "✅ GWAS Association Testing completed successfully!"
        echo "Output files:"
        echo "  - Raw association results: ~{output_prefix}.*"
        echo "  - Processed results: ~{output_prefix}_processed.txt"
        echo "  - Summary report: ~{output_prefix}_summary.txt"
        echo "  - Merged covariates: merged_covariates.txt"
    >>>

    output {
        File gwas_results = "~{output_prefix}_processed.txt"
        File association_summary = "~{output_prefix}_summary.txt"
        File association_log = "~{output_prefix}.log"
        File merged_covariates = "merged_covariates.txt"
        Array[File] raw_results = glob("~{output_prefix}.*")
    }

    runtime {
        docker: docker_image
        cpu: cpu
        memory: "~{memory_gb}GB"
        disks: "local-disk 100 SSD"
        bootDiskSizeGb: 20
        preemptible: 2
    }

    meta {
        description: "Genome-wide association study (GWAS) analysis"
        author: "GA4GH Hackathon 2025"
    }
} 