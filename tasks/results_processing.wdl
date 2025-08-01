version 1.0

## Process GWAS results and generate plots and meta-analysis ready outputs
task ResultsProcessing {
    input {
        File gwas_results
        String trait_name
        String trait_type
        Float pvalue_threshold = 5e-8
        Boolean include_plots = true
        String output_prefix = "final_results"
        Int cpu = 2
        Int memory_gb = 8
        String docker_image = "mamana/gwas-tools:latest"
    }

    command <<<
        set -euo pipefail
        
        echo "📊 Starting GWAS Results Processing"
        echo "Input GWAS results: ~{gwas_results}"
        echo "Trait: ~{trait_name} (~{trait_type})"
        echo "P-value threshold: ~{pvalue_threshold}"
        echo "Include plots: ~{include_plots}"
        echo "Output prefix: ~{output_prefix}"
        echo ""
        
        # Copy input file
        cp "~{gwas_results}" gwas_results.txt
        
        # Process results and generate outputs using R
        cat > process_gwas_results.R << 'EOF'
        library(data.table)
        library(ggplot2)
        library(dplyr)
        
        # Read GWAS results
        cat("Reading GWAS results...\n")
        results <- fread("gwas_results.txt")
        
        # Check required columns
        required_cols <- c("CHR", "BP", "SNP", "PVALUE")
        missing_cols <- required_cols[!required_cols %in% names(results)]
        
        if(length(missing_cols) > 0) {
            cat("Error: Missing required columns:", paste(missing_cols, collapse=", "), "\n")
            cat("Available columns:", paste(names(results), collapse=", "), "\n")
            
            # Try to infer column names
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
        }
        
        # Filter and clean data
        results <- results[!is.na(PVALUE) & PVALUE > 0 & PVALUE <= 1]
        results[, LOG10P := -log10(PVALUE)]
        
        # Ensure CHR is numeric
        results[, CHR := as.numeric(CHR)]
        results <- results[!is.na(CHR)]
        
        cat("Processed", nrow(results), "variants\n")
        
        # Generate Manhattan plot
        if(~{include_plots}) {
            cat("Generating Manhattan plot...\n")
            
            # Create chromosome positions for plotting
            results <- results[order(CHR, BP)]
            chr_lengths <- results[, .(max_bp = max(BP)), by = CHR]
            chr_lengths[, cum_pos := cumsum(as.numeric(max_bp))]
            chr_lengths[, start_pos := c(0, cum_pos[-.N])]
            
            # Merge with results
            results <- merge(results, chr_lengths[, .(CHR, start_pos)], by = "CHR")
            results[, PLOT_POS := BP + start_pos]
            
            # Define colors for chromosomes
            chr_colors <- rep(c("#2E86AB", "#A23B72"), length.out = 22)
            
            # Manhattan plot
            manhattan <- ggplot(results, aes(x = PLOT_POS, y = LOG10P)) +
                geom_point(aes(color = factor(CHR)), alpha = 0.7, size = 0.8) +
                scale_color_manual(values = chr_colors) +
                geom_hline(yintercept = -log10(~{pvalue_threshold}), 
                          color = "red", linetype = "dashed", size = 1) +
                geom_hline(yintercept = -log10(1e-6), 
                          color = "blue", linetype = "dotted", size = 0.8) +
                labs(title = paste("Manhattan Plot -", "~{trait_name}"),
                     x = "Chromosome",
                     y = expression(-log[10](italic(p)))) +
                theme_minimal() +
                theme(
                    legend.position = "none",
                    plot.title = element_text(hjust = 0.5, size = 16),
                    axis.text.x = element_text(angle = 0),
                    panel.grid.major = element_blank(),
                    panel.grid.minor = element_blank()
                ) +
                scale_x_continuous(
                    breaks = chr_lengths[, start_pos + max_bp/2],
                    labels = 1:22
                )
            
            ggsave("~{output_prefix}_manhattan.pdf", manhattan, 
                   width = 16, height = 8, dpi = 300)
            ggsave("~{output_prefix}_manhattan.png", manhattan, 
                   width = 16, height = 8, dpi = 300)
            
            # QQ plot
            cat("Generating QQ plot...\n")
            
            # Calculate expected p-values
            results_sorted <- results[order(PVALUE)]
            n_variants <- nrow(results_sorted)
            expected_p <- (1:n_variants) / (n_variants + 1)
            results_sorted[, EXPECTED_LOG10P := -log10(expected_p)]
            
            # Calculate genomic inflation factor
            chisq_obs <- qchisq(1 - results_sorted$PVALUE, 1)
            lambda <- median(chisq_obs, na.rm = TRUE) / qchisq(0.5, 1)
            
            # QQ plot
            qq_plot <- ggplot(results_sorted, aes(x = EXPECTED_LOG10P, y = LOG10P)) +
                geom_point(alpha = 0.7, size = 0.8, color = "#2E86AB") +
                geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
                labs(title = paste("QQ Plot -", "~{trait_name}"),
                     subtitle = paste("λ =", round(lambda, 3)),
                     x = expression(Expected~-log[10](italic(p))),
                     y = expression(Observed~-log[10](italic(p)))) +
                theme_minimal() +
                theme(
                    plot.title = element_text(hjust = 0.5, size = 16),
                    plot.subtitle = element_text(hjust = 0.5, size = 14)
                )
            
            ggsave("~{output_prefix}_qq.pdf", qq_plot, 
                   width = 8, height = 8, dpi = 300)
            ggsave("~{output_prefix}_qq.png", qq_plot, 
                   width = 8, height = 8, dpi = 300)
        }
        
        # Identify top hits
        cat("Identifying top hits...\n")
        top_hits <- results[PVALUE < ~{pvalue_threshold}]
        
        if(nrow(top_hits) == 0) {
            cat("No genome-wide significant hits found. Using suggestive threshold (1e-6)\n")
            top_hits <- results[PVALUE < 1e-6]
        }
        
        if(nrow(top_hits) == 0) {
            cat("No suggestive hits found. Using top 100 variants\n")
            top_hits <- head(results[order(PVALUE)], 100)
        }
        
        # Sort top hits by p-value
        top_hits <- top_hits[order(PVALUE)]
        
        # Save top hits
        fwrite(top_hits, "~{output_prefix}_top_hits.txt", sep = "\t")
        
        # Create meta-analysis ready format
        cat("Creating meta-analysis ready format...\n")
        
        # Standard format for meta-analysis
        meta_cols <- c("SNP", "CHR", "BP", "A1", "A2", "FREQ", "BETA", "SE", "PVALUE", "N")
        
        # Check which columns are available
        available_meta_cols <- meta_cols[meta_cols %in% names(results)]
        missing_meta_cols <- meta_cols[!meta_cols %in% names(results)]
        
        cat("Available meta-analysis columns:", paste(available_meta_cols, collapse = ", "), "\n")
        cat("Missing meta-analysis columns:", paste(missing_meta_cols, collapse = ", "), "\n")
        
        # Create meta-analysis ready file with available columns
        meta_ready <- results[, ..available_meta_cols]
        fwrite(meta_ready, "~{output_prefix}_meta_ready.txt", sep = "\t")
        
        # Generate summary report
        cat("Generating summary report...\n")
        
        # Calculate summary statistics
        n_variants <- nrow(results)
        n_sig_5e8 <- sum(results$PVALUE < 5e-8, na.rm = TRUE)
        n_sig_1e6 <- sum(results$PVALUE < 1e-6, na.rm = TRUE)
        n_sig_1e5 <- sum(results$PVALUE < 1e-5, na.rm = TRUE)
        
        # Genomic inflation
        if(exists("lambda")) {
            genomic_lambda <- lambda
        } else {
            chisq_obs <- qchisq(1 - results$PVALUE, 1)
            genomic_lambda <- median(chisq_obs, na.rm = TRUE) / qchisq(0.5, 1)
        }
        
        # Write summary report
        cat("GWAS Results Processing Summary\n", file = "~{output_prefix}_summary.txt")
        cat("==============================\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("Trait:", "~{trait_name}"), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("Trait type:", "~{trait_type}"), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("Analysis date:", Sys.Date()), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("Total variants:", format(n_variants, big.mark = ",")), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("Genomic inflation factor (λ):", round(genomic_lambda, 4)), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat("\nSignificance thresholds:\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("  Genome-wide significant (p < 5e-8):", n_sig_5e8), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("  Suggestive (p < 1e-6):", n_sig_1e6), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat(paste("  Nominally significant (p < 1e-5):", n_sig_1e5), "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        
        # Top 5 hits
        cat("\nTop 5 association signals:\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        top5 <- head(results[order(PVALUE), .(SNP, CHR, BP, PVALUE, LOG10P)], 5)
        
        for(i in 1:nrow(top5)) {
            cat(paste("  ", i, ". ", top5[i, SNP], " (chr", top5[i, CHR], ":", 
                     format(top5[i, BP], big.mark = ","), ") p =", 
                     format(top5[i, PVALUE], scientific = TRUE, digits = 3)), 
                "\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        }
        
        cat("\nOutput files generated:\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat("  - Top hits: ~{output_prefix}_top_hits.txt\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        cat("  - Meta-analysis ready: ~{output_prefix}_meta_ready.txt\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        if(~{include_plots}) {
            cat("  - Manhattan plot: ~{output_prefix}_manhattan.pdf\n", file = "~{output_prefix}_summary.txt", append = TRUE)
            cat("  - QQ plot: ~{output_prefix}_qq.pdf\n", file = "~{output_prefix}_summary.txt", append = TRUE)
        }
        
        cat("GWAS results processing completed successfully!\n")
        EOF
        
        Rscript process_gwas_results.R
        
        echo "✅ GWAS Results Processing completed successfully!"
        echo "Output files:"
        echo "  - Summary report: ~{output_prefix}_summary.txt"
        echo "  - Top hits: ~{output_prefix}_top_hits.txt"
        echo "  - Meta-analysis ready: ~{output_prefix}_meta_ready.txt"
        if [[ "~{include_plots}" == "true" ]]; then
            echo "  - Manhattan plot: ~{output_prefix}_manhattan.pdf"
            echo "  - QQ plot: ~{output_prefix}_qq.pdf"
        fi
    >>>

    output {
        File summary_report = "~{output_prefix}_summary.txt"
        File top_hits = "~{output_prefix}_top_hits.txt"
        File meta_analysis_ready = "~{output_prefix}_meta_ready.txt"
        File? manhattan_plot = if include_plots then "~{output_prefix}_manhattan.pdf" else null
        File? manhattan_png = if include_plots then "~{output_prefix}_manhattan.png" else null
        File? qq_plot = if include_plots then "~{output_prefix}_qq.pdf" else null
        File? qq_png = if include_plots then "~{output_prefix}_qq.png" else null
    }

    runtime {
        docker: docker_image
        cpu: cpu
        memory: "~{memory_gb}GB"
        disks: "local-disk 20 SSD"
        bootDiskSizeGb: 10
        preemptible: 2
    }

    meta {
        description: "Process GWAS results and generate plots and harmonized outputs"
        author: "GA4GH Hackathon 2025"
    }
} 