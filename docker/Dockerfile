FROM ubuntu:20.04

# Metadata labels
LABEL org.opencontainers.image.title="GWAS Tools Container"
LABEL org.opencontainers.image.description="Federated genome-wide association studies (GWAS) analysis tools"
LABEL org.opencontainers.image.authors="GA4GH Hackathon 2025 - African Genomics Team"
LABEL org.opencontainers.image.vendor="elwazi.org"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/your-org/federated-gwas-workshop-2025"
LABEL org.opencontainers.image.source="https://github.com/your-org/federated-gwas-workshop-2025"
LABEL org.opencontainers.image.documentation="https://github.com/your-org/federated-gwas-workshop-2025/blob/main/README.md"
LABEL org.opencontainers.image.version="1.0.0"

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${VCS_REF}

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies in a single layer
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    build-essential \
    cmake \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    python3 \
    python3-pip \
    r-base \
    r-base-dev \
    bc \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install PLINK 2.0
RUN wget -q https://s3.amazonaws.com/plink2-assets/alpha3/plink2_linux_x86_64_20221024.zip \
    && unzip -q plink2_linux_x86_64_20221024.zip \
    && mv plink2 /usr/local/bin/ \
    && chmod +x /usr/local/bin/plink2 \
    && rm plink2_linux_x86_64_20221024.zip

# Install bcftools and htslib
RUN wget -q https://github.com/samtools/bcftools/releases/download/1.17/bcftools-1.17.tar.bz2 \
    && tar -xjf bcftools-1.17.tar.bz2 \
    && cd bcftools-1.17 \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf bcftools-1.17*

# Install R packages
RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
    install.packages(c('data.table', 'ggplot2', 'dplyr', 'RColorBrewer', 'gridExtra'), \
    dependencies = TRUE, Ncpus = parallel::detectCores())"

# Install Python packages
RUN pip3 install --no-cache-dir \
    pandas==2.0.3 \
    numpy==1.24.3 \
    scipy==1.11.1 \
    matplotlib==3.7.2 \
    seaborn==0.12.2

# Create working directory
WORKDIR /workspace

# Set PATH
ENV PATH="/usr/local/bin:${PATH}"

# Create non-root user for security
RUN groupadd -g 1001 gwasuser && \
    useradd -r -u 1001 -g gwasuser gwasuser && \
    chown -R gwasuser:gwasuser /workspace

# Switch to non-root user
USER gwasuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD plink2 --help > /dev/null 2>&1 || exit 1

# Default command
CMD ["/bin/bash"] 