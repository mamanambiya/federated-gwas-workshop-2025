version 1.0

## Apply quality control filters to genotype data for GWAS
task QualityControl {
    input {
        File genotype_file
        File phenotype_file
        Float maf_threshold = 0.01
        Float call_rate_threshold = 0.95
        Float hwe_pvalue = 1e-6
        Float relatedness_threshold = 0.125
        String output_prefix = "quality_controlled"
        Int cpu = 4
        Int memory_gb = 16
        String docker_image = "mamana/gwas-tools:latest"
    }

    command <<<
        set -euo pipefail
        
        echo "🧬 Starting GWAS Quality Control Pipeline"
        echo "Input genotype file: ~{genotype_file}"
        echo "MAF threshold: ~{maf_threshold}"
        echo "Call rate threshold: ~{call_rate_threshold}"
        echo "HWE p-value threshold: ~{hwe_pvalue}"
        echo "Relatedness threshold: ~{relatedness_threshold}"
        echo ""
        
        # Create output directory
        mkdir -p qc_outputs
        
        # Determine input format (VCF or PLINK)
        if [[ "~{genotype_file}" == *.vcf.gz ]] || [[ "~{genotype_file}" == *.vcf ]]; then
            echo "Detected VCF format input"
            INPUT_FORMAT="vcf"
            INPUT_PREFIX="input_vcf"
            
            # Convert VCF to PLINK format for processing
            if [[ "~{genotype_file}" == *.vcf.gz ]]; then
                cp "~{genotype_file}" input.vcf.gz
                plink2 --vcf input.vcf.gz \
                    --make-bed \
                    --out "$INPUT_PREFIX" \
                    --memory ~{memory_gb * 1000}
            else
                plink2 --vcf "~{genotype_file}" \
                    --make-bed \
                    --out "$INPUT_PREFIX" \
                    --memory ~{memory_gb * 1000}
            fi
        else
            echo "Detected PLINK format input"
            INPUT_FORMAT="plink"
            INPUT_PREFIX="input_plink"
            
            # Assume PLINK binary format (.bed/.bim/.fam)
            BASENAME=$(basename "~{genotype_file}" .bed)
            DIRNAME=$(dirname "~{genotype_file}")
            cp "$DIRNAME/$BASENAME.bed" "$INPUT_PREFIX.bed"
            cp "$DIRNAME/$BASENAME.bim" "$INPUT_PREFIX.bim"  
            cp "$DIRNAME/$BASENAME.fam" "$INPUT_PREFIX.fam"
        fi
        
        # Step 1: Basic sample and variant counts
        echo "📊 Generating initial statistics..."
        plink2 --bfile "$INPUT_PREFIX" \
            --freq \
            --missing \
            --hardy \
            --out qc_outputs/initial_stats \
            --memory ~{memory_gb * 1000}
        
        # Step 2: Remove variants with low call rate
        echo "🧹 Filtering variants by call rate (>= ~{call_rate_threshold})..."
        plink2 --bfile "$INPUT_PREFIX" \
            --geno $(echo "1 - ~{call_rate_threshold}" | bc -l) \
            --make-bed \
            --out temp_callrate \
            --memory ~{memory_gb * 1000}
        
        # Step 3: Remove variants with low MAF
        echo "🧹 Filtering variants by MAF (>= ~{maf_threshold})..."
        plink2 --bfile temp_callrate \
            --maf ~{maf_threshold} \
            --make-bed \
            --out temp_maf \
            --memory ~{memory_gb * 1000}
        
        # Step 4: Remove variants out of HWE
        echo "🧹 Filtering variants by HWE (p >= ~{hwe_pvalue})..."
        plink2 --bfile temp_maf \
            --hwe ~{hwe_pvalue} \
            --make-bed \
            --out temp_hwe \
            --memory ~{memory_gb * 1000}
        
        # Step 5: Remove individuals with high missing genotype rate
        echo "🧹 Filtering individuals by missing genotype rate..."
        plink2 --bfile temp_hwe \
            --mind 0.05 \
            --make-bed \
            --out temp_mind \
            --memory ~{memory_gb * 1000}
        
        # Step 6: Calculate relatedness and remove related individuals
        echo "🧬 Calculating relatedness..."
        plink2 --bfile temp_mind \
            --king-cutoff ~{relatedness_threshold} \
            --make-bed \
            --out temp_unrelated \
            --memory ~{memory_gb * 1000}
        
        # Step 7: Filter to individuals present in phenotype file
        echo "📋 Filtering to individuals with phenotype data..."
        
        # Extract sample IDs from phenotype file (assuming FID IID format)
        awk 'NR>1 {print $1, $2}' "~{phenotype_file}" > keep_samples.txt
        
        plink2 --bfile temp_unrelated \
            --keep keep_samples.txt \
            --make-bed \
            --out "~{output_prefix}" \
            --memory ~{memory_gb * 1000}
        
        # Step 8: Generate final statistics and QC report
        echo "📊 Generating final QC statistics..."
        plink2 --bfile "~{output_prefix}" \
            --freq \
            --missing \
            --hardy \
            --het \
            --out qc_outputs/final_stats \
            --memory ~{memory_gb * 1000}
        
        # Step 9: Create sample list for downstream analysis
        awk '{print $1, $2}' "~{output_prefix}.fam" > "~{output_prefix}_samples.txt"
        
        # Step 10: Generate QC plots using R
        cat > qc_plots.R << 'EOF'
        library(ggplot2)
        library(data.table)
        library(gridExtra)
        
        # Read data
        freq_before <- fread("qc_outputs/initial_stats.afreq")
        freq_after <- fread("qc_outputs/final_stats.afreq")
        missing_before <- fread("qc_outputs/initial_stats.vmiss")
        missing_after <- fread("qc_outputs/final_stats.vmiss")
        hwe_before <- fread("qc_outputs/initial_stats.hardy")
        hwe_after <- fread("qc_outputs/final_stats.hardy")
        
        # MAF distribution plot
        freq_before$status <- "Before QC"
        freq_after$status <- "After QC" 
        freq_combined <- rbind(freq_before, freq_after)
        
        p1 <- ggplot(freq_combined, aes(x=ALT_FREQS, fill=status)) +
            geom_histogram(alpha=0.7, bins=50) +
            facet_wrap(~status, ncol=1) +
            labs(title="Minor Allele Frequency Distribution", 
                 x="MAF", y="Count") +
            theme_minimal()
        
        # Missing rate distribution
        missing_before$status <- "Before QC"
        missing_after$status <- "After QC"
        missing_combined <- rbind(missing_before, missing_after)
        
        p2 <- ggplot(missing_combined, aes(x=F_MISS, fill=status)) +
            geom_histogram(alpha=0.7, bins=50) +
            facet_wrap(~status, ncol=1) +
            labs(title="Variant Missing Rate Distribution",
                 x="Missing Rate", y="Count") +
            theme_minimal()
        
        # HWE p-value distribution  
        hwe_before$status <- "Before QC"
        hwe_after$status <- "After QC"
        hwe_combined <- rbind(hwe_before, hwe_after)
        
        p3 <- ggplot(hwe_combined, aes(x=-log10(P), fill=status)) +
            geom_histogram(alpha=0.7, bins=50) +
            facet_wrap(~status, ncol=1) +
            labs(title="Hardy-Weinberg Equilibrium",
                 x="-log10(P)", y="Count") +
            theme_minimal()
        
        # Combine plots
        pdf("~{output_prefix}_qc_plots.pdf", width=12, height=10)
        grid.arrange(p1, p2, p3, ncol=2)
        dev.off()
        
        # Summary statistics
        cat("QC Summary Report\n", file="~{output_prefix}_qc_report.txt")
        cat("================\n", file="~{output_prefix}_qc_report.txt", append=TRUE)
        cat(paste("Variants before QC:", nrow(freq_before), "\n"), 
            file="~{output_prefix}_qc_report.txt", append=TRUE)
        cat(paste("Variants after QC:", nrow(freq_after), "\n"), 
            file="~{output_prefix}_qc_report.txt", append=TRUE)
        cat(paste("Variant retention rate:", 
                  round(nrow(freq_after)/nrow(freq_before)*100, 2), "%\n"), 
            file="~{output_prefix}_qc_report.txt", append=TRUE)
        EOF
        
        Rscript qc_plots.R
        
        echo "✅ Quality Control completed successfully!"
        echo "Output files:"
        echo "  - Filtered genotypes: ~{output_prefix}.bed/bim/fam"
        echo "  - Sample list: ~{output_prefix}_samples.txt"
        echo "  - QC report: ~{output_prefix}_qc_report.txt"
        echo "  - QC plots: ~{output_prefix}_qc_plots.pdf"
    >>>

    output {
        File filtered_genotype_file = "~{output_prefix}.bed"
        File filtered_bim_file = "~{output_prefix}.bim"
        File filtered_fam_file = "~{output_prefix}.fam"
        File filtered_sample_file = "~{output_prefix}_samples.txt"
        File qc_report = "~{output_prefix}_qc_report.txt"
        File qc_plots = "~{output_prefix}_qc_plots.pdf"
        File final_freq = "qc_outputs/final_stats.afreq"
        File final_missing = "qc_outputs/final_stats.vmiss"
        File final_hardy = "qc_outputs/final_stats.hardy"
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
        description: "Quality control for GWAS genotype data"
        author: "GA4GH Hackathon 2025"
    }
} 