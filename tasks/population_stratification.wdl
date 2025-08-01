version 1.0

## Calculate principal components for population stratification in GWAS
task PopulationStratification {
    input {
        File genotype_file  # PLINK .bed file
        File sample_file    # Sample list file
        Int num_pcs = 10
        String output_prefix = "population_pca"
        Int cpu = 4
        Int memory_gb = 16
        String docker_image = "mamana/gwas-tools:latest"
    }

    command <<<
        set -euo pipefail
        
        echo "🧬 Starting Population Stratification Analysis"
        echo "Input genotype file: ~{genotype_file}"
        echo "Number of PCs to calculate: ~{num_pcs}"
        echo "Output prefix: ~{output_prefix}"
        echo ""
        
        # Set up file paths
        BASENAME=$(basename "~{genotype_file}" .bed)
        DIRNAME=$(dirname "~{genotype_file}")
        
        # Copy PLINK files to working directory
        cp "$DIRNAME/$BASENAME.bed" input.bed
        cp "$DIRNAME/$BASENAME.bim" input.bim
        cp "$DIRNAME/$BASENAME.fam" input.fam
        
        # Step 1: LD-prune variants for PCA
        echo "🧹 LD-pruning variants for PCA..."
        plink2 --bfile input \
            --indep-pairwise 50 5 0.2 \
            --out ld_pruned \
            --memory ~{memory_gb * 1000}
        
        # Step 2: Calculate principal components
        echo "📊 Calculating principal components..."
        plink2 --bfile input \
            --extract ld_pruned.prune.in \
            --pca ~{num_pcs} \
            --out "~{output_prefix}" \
            --memory ~{memory_gb * 1000}
        
        # Step 3: Create population structure plots using R
        cat > pca_plots.R << 'EOF'
        library(ggplot2)
        library(data.table)
        library(RColorBrewer)
        library(gridExtra)
        
        # Read PCA results
        pcs <- fread("~{output_prefix}.eigenvec")
        eigenvals <- fread("~{output_prefix}.eigenval")
        
        # Add column names
        pc_cols <- paste0("PC", 1:~{num_pcs})
        setnames(pcs, c("FID", "IID", pc_cols))
        setnames(eigenvals, "eigenvalue")
        
        # Calculate variance explained
        var_explained <- eigenvals$eigenvalue / sum(eigenvals$eigenvalue) * 100
        
        # PC1 vs PC2 plot
        p1 <- ggplot(pcs, aes(x=PC1, y=PC2)) +
            geom_point(alpha=0.7, size=1.5) +
            labs(title="Principal Component Analysis",
                 subtitle="Population Structure",
                 x=paste0("PC1 (", round(var_explained[1], 2), "%)"),
                 y=paste0("PC2 (", round(var_explained[2], 2), "%)")) +
            theme_minimal() +
            theme(plot.title = element_text(hjust=0.5),
                  plot.subtitle = element_text(hjust=0.5))
        
        # PC3 vs PC4 plot (if available)
        if(~{num_pcs} >= 4) {
            p2 <- ggplot(pcs, aes(x=PC3, y=PC4)) +
                geom_point(alpha=0.7, size=1.5) +
                labs(title="PC3 vs PC4",
                     x=paste0("PC3 (", round(var_explained[3], 2), "%)"),
                     y=paste0("PC4 (", round(var_explained[4], 2), "%)")) +
                theme_minimal() +
                theme(plot.title = element_text(hjust=0.5))
        }
        
        # Scree plot
        scree_data <- data.frame(
            PC = 1:length(var_explained),
            Variance = var_explained
        )
        
        p3 <- ggplot(scree_data, aes(x=PC, y=Variance)) +
            geom_bar(stat="identity", fill="steelblue", alpha=0.7) +
            geom_line(color="red", size=1) +
            geom_point(color="red", size=2) +
            labs(title="Scree Plot",
                 x="Principal Component",
                 y="Variance Explained (%)") +
            theme_minimal() +
            theme(plot.title = element_text(hjust=0.5))
        
        # Outlier detection based on PC1 and PC2
        # Define outliers as samples > 6 standard deviations from mean
        pc1_outliers <- abs(pcs$PC1 - mean(pcs$PC1)) > 6 * sd(pcs$PC1)
        pc2_outliers <- abs(pcs$PC2 - mean(pcs$PC2)) > 6 * sd(pcs$PC2)
        outliers <- pc1_outliers | pc2_outliers
        
        # Mark outliers
        pcs$outlier <- outliers
        
        p4 <- ggplot(pcs, aes(x=PC1, y=PC2, color=outlier)) +
            geom_point(alpha=0.7, size=1.5) +
            scale_color_manual(values=c("FALSE"="blue", "TRUE"="red"),
                              labels=c("Normal", "Outlier")) +
            labs(title="Population Outlier Detection",
                 x=paste0("PC1 (", round(var_explained[1], 2), "%)"),
                 y=paste0("PC2 (", round(var_explained[2], 2), "%)"),
                 color="Status") +
            theme_minimal() +
            theme(plot.title = element_text(hjust=0.5))
        
        # Save plots
        if(~{num_pcs} >= 4) {
            pdf("~{output_prefix}_plots.pdf", width=12, height=10)
            grid.arrange(p1, p2, p3, p4, ncol=2)
            dev.off()
        } else {
            pdf("~{output_prefix}_plots.pdf", width=12, height=8)
            grid.arrange(p1, p3, p4, ncol=2)
            dev.off()
        }
        
        # Save outlier list
        outlier_samples <- pcs[outliers == TRUE, .(FID, IID)]
        fwrite(outlier_samples, "~{output_prefix}_outliers.txt", sep="\t")
        
        # Create summary report
        cat("Population Stratification Analysis Report\n", file="~{output_prefix}_report.txt")
        cat("=======================================\n", file="~{output_prefix}_report.txt", append=TRUE)
        cat(paste("Total samples analyzed:", nrow(pcs), "\n"), 
            file="~{output_prefix}_report.txt", append=TRUE)
        cat(paste("Number of PCs calculated:", ~{num_pcs}, "\n"), 
            file="~{output_prefix}_report.txt", append=TRUE)
        cat(paste("Population outliers detected:", sum(outliers), "\n"), 
            file="~{output_prefix}_report.txt", append=TRUE)
        cat("\nVariance explained by each PC:\n", 
            file="~{output_prefix}_report.txt", append=TRUE)
        
        for(i in 1:length(var_explained)) {
            cat(paste("PC", i, ":", round(var_explained[i], 3), "%\n", sep=""), 
                file="~{output_prefix}_report.txt", append=TRUE)
        }
        
        cat(paste("\nCumulative variance (first 5 PCs):", 
                  round(sum(var_explained[1:min(5, length(var_explained))]), 2), "%\n"), 
            file="~{output_prefix}_report.txt", append=TRUE)
        
        # Save PCs in format suitable for GWAS (FID IID PC1 PC2 ...)
        pcs_for_gwas <- pcs[, c("FID", "IID", pc_cols), with=FALSE]
        fwrite(pcs_for_gwas, "~{output_prefix}_for_gwas.txt", sep="\t")
        
        print("Population stratification analysis completed!")
        EOF
        
        Rscript pca_plots.R
        
        # Step 4: Generate additional population statistics
        echo "📊 Calculating additional population metrics..."
        
        # Calculate F_ST between potential population clusters
        # This is a simplified approach - in practice, you'd want more sophisticated clustering
        plink2 --bfile input \
            --extract ld_pruned.prune.in \
            --cluster \
            --out "~{output_prefix}_clusters" \
            --memory ~{memory_gb * 1000}
        
        echo "✅ Population Stratification Analysis completed successfully!"
        echo "Output files:"
        echo "  - Principal components: ~{output_prefix}.eigenvec"
        echo "  - Eigenvalues: ~{output_prefix}.eigenval"
        echo "  - PCA plots: ~{output_prefix}_plots.pdf"
        echo "  - Population outliers: ~{output_prefix}_outliers.txt"
        echo "  - PCs for GWAS: ~{output_prefix}_for_gwas.txt"
        echo "  - Analysis report: ~{output_prefix}_report.txt"
    >>>

    output {
        File pcs_file = "~{output_prefix}_for_gwas.txt"
        File eigenvalues_file = "~{output_prefix}.eigenval"
        File eigenvectors_file = "~{output_prefix}.eigenvec"
        File pca_plots = "~{output_prefix}_plots.pdf"
        File outliers_file = "~{output_prefix}_outliers.txt"
        File population_report = "~{output_prefix}_report.txt"
        File pruned_variants = "ld_pruned.prune.in"
        File cluster_file = "~{output_prefix}_clusters.cluster3"
    }

    runtime {
        docker: docker_image
        cpu: cpu
        memory: "~{memory_gb}GB"
        disks: "local-disk 50 SSD"
        bootDiskSizeGb: 20
        preemptible: 2
    }

    meta {
        description: "Population stratification analysis using principal component analysis"
        author: "GA4GH Hackathon 2025"
    }
} 