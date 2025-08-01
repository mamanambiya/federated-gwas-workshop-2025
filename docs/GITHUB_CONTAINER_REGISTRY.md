# Using GitHub Container Registry with WDL

## Overview

**Yes, WDL can absolutely use GitHub Container Registry (ghcr.io)!** In fact, GitHub Container Registry offers several advantages over traditional registries and is increasingly popular for research workflows.

## Benefits of GitHub Container Registry

### Integration Benefits
- **Seamless GitHub Integration**: Tightly coupled with your source code repository
- **Unified Authentication**: Uses GitHub tokens (no separate registry credentials)
- **Package Visibility**: Same permissions as your GitHub repository
- **Automatic Cleanup**: Can auto-delete old images based on policies

### Performance Benefits  
- **Global CDN**: Fast pulls from anywhere in the world
- **Better Caching**: Improved layer caching and distribution
- **Bandwidth**: Generous bandwidth limits for public repositories

### Security Benefits
- **Fine-grained Permissions**: Repository-level access control
- **Vulnerability Scanning**: Built-in security scanning
- **OIDC Integration**: Support for GitHub's OIDC tokens
- **Audit Logging**: Complete audit trail in GitHub

## Registry Comparison

| Feature | DockerHub | GitHub Container Registry |
|---------|-----------|---------------------------|
| **Free Public Repos** | Unlimited | Unlimited |
| **Free Private Repos** | 1 repository | Unlimited |
| **Bandwidth** | Limited | Generous |
| **Build Integration** | Separate setup | Native GitHub Actions |
| **Authentication** | Separate tokens | GitHub tokens |
| **Vulnerability Scanning** | Paid feature | Built-in |
| **Package Permissions** | Registry-level | Repository-level |

## Configuration

### 1. WDL Workflow Configuration

Update your WDL tasks to use GitHub Container Registry:

```wdl
# Before (DockerHub)
runtime {
    docker: "mamana/gwas-tools:latest"
    cpu: 4
    memory: "16GB"
}

# After (GitHub Container Registry)
runtime {
    docker: "ghcr.io/mamana/gwas-tools:latest"
    cpu: 4
    memory: "16GB"
}
```

### 2. Input JSON Configuration

```json
{
  "GWASPipeline.docker_image": "ghcr.io/mamana/gwas-tools:latest"
}
```

### 3. Cromwell Configuration

```hocon
# cromwell.conf
backend {
  default = Local
  providers {
    Local {
      config {
        runtime-attributes = """
        String docker = "ghcr.io/mamana/gwas-tools:latest"
        Int cpu = 4
        Int memory_gb = 16
        """
      }
    }
  }
}
```

## Image Naming Conventions

### GitHub Container Registry Format
```
ghcr.io/OWNER/REPOSITORY:TAG
```

### Examples
```bash
# Organization repository
ghcr.io/ga4gh-hackathon/gwas-tools:latest

# Personal repository  
ghcr.io/mamana/gwas-tools:latest

# With version tags
ghcr.io/mamana/gwas-tools:v1.0.0
ghcr.io/mamana/gwas-tools:main-abc123
```

## Authentication

### For GitHub Actions (Automatic)
```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### For Local Development
```bash
# Create GitHub Personal Access Token with packages:read scope
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Pull image
docker pull ghcr.io/mamana/gwas-tools:latest
```

### For Cromwell/WDL Execution

#### Option 1: Pre-authenticate Docker
```bash
# Authenticate once
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Run workflow (Docker already authenticated)
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i inputs/test_gensetB_ghcr.json
```

#### Option 2: Public Images (No Authentication)
Make your container image public in GitHub Package settings - no authentication required.

#### Option 3: Environment Variables
```bash
# Set environment variables
export GITHUB_TOKEN="ghp_..."
export GITHUB_USERNAME="mamana"

# Cromwell can use these for authentication
```

## Usage Examples

### Basic WDL Task
```wdl
task QualityControl {
    input {
        File genotype_file
        String output_prefix = "qc_results"
    }
    
    command {
        plink2 --bfile ${genotype_file} \
               --maf 0.01 \
               --geno 0.05 \
               --make-bed \
               --out ${output_prefix}
    }
    
    runtime {
        docker: "ghcr.io/mamana/gwas-tools:latest"
        cpu: 4
        memory: "16GB"
    }
    
    output {
        File filtered_bed = "${output_prefix}.bed"
        File filtered_bim = "${output_prefix}.bim"
        File filtered_fam = "${output_prefix}.fam"
    }
}
```

### Terra/AnVIL Configuration
```json
{
  "GWASPipeline.QualityControl.runtime_attributes": {
    "docker": "ghcr.io/mamana/gwas-tools:latest",
    "memory": "16 GB",
    "cpu": 4,
    "disks": "local-disk 100 HDD"
  }
}
```

### DNAstack Workbench
```yaml
# workflow.yaml
runtime:
  docker: ghcr.io/mamana/gwas-tools:latest
  cpu: 4
  memory: 16Gi
```

## Migration from DockerHub

### 1. Update WDL Files
```bash
# Find and replace in all WDL files
find . -name "*.wdl" -exec sed -i 's|mamana/gwas-tools|ghcr.io/mamana/gwas-tools|g' {} +
```

### 2. Update Input Files
```bash
# Update JSON input files
find . -name "*.json" -exec sed -i 's|"mamana/gwas-tools|"ghcr.io/mamana/gwas-tools|g' {} +
```

### 3. Update Documentation
```bash
# Update README and docs
find . -name "*.md" -exec sed -i 's|mamana/gwas-tools|ghcr.io/mamana/gwas-tools|g' {} +
```

## Registry Availability

### Public Access
- **No authentication required** for public images
- **Unlimited bandwidth** for open source projects
- **Global CDN** for fast downloads

### Private Access
- **GitHub token required** for private images
- **Repository permissions** control access
- **Fine-grained access control** available

## Platform Support

### Cloud Platforms
| Platform | GHCR Support |
|----------|--------------|
| **Cromwell** | Full support |
| **Terra/AnVIL** | Full support |
| **DNAstack** | Full support |
| **Nextflow Tower** | Full support |
| **AWS Batch** | Full support |
| **Google Cloud Life Sciences** | Full support |
| **Azure Container Instances** | Full support |

### Local Execution
```bash
# Cromwell local backend
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i inputs/test_gensetB_ghcr.json

# Direct Docker execution
docker run --rm -v $(pwd)/data:/data ghcr.io/mamana/gwas-tools:latest plink2 --help
```

## Advanced Configuration

### Version Pinning
```wdl
runtime {
    # Pin to specific version for reproducibility
    docker: "ghcr.io/mamana/gwas-tools:v1.0.0"
}
```

### Multi-architecture Support
```wdl
runtime {
    # Automatic architecture selection
    docker: "ghcr.io/mamana/gwas-tools:latest"
    # Works on both AMD64 and ARM64
}
```

### Custom Registry Configuration
```hocon
# For private registries or custom configurations
docker {
  registry = "ghcr.io"
  username = ${?GITHUB_USERNAME}
  token = ${?GITHUB_TOKEN}
}
```

## Troubleshooting

### Common Issues

#### 1. Authentication Errors
```bash
# Error: unauthorized
# Solution: Check GitHub token permissions
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

#### 2. Image Not Found
```bash
# Error: image not found
# Solution: Check image name and visibility
docker pull ghcr.io/mamana/gwas-tools:latest
```

#### 3. Permission Denied
```bash
# Error: permission denied
# Solution: Check repository access or make image public
```

### Debugging Commands
```bash
# Test authentication
docker pull ghcr.io/mamana/gwas-tools:latest

# Check image details
docker inspect ghcr.io/mamana/gwas-tools:latest

# List available tags
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
     https://ghcr.io/v2/mamana/gwas-tools/tags/list
```

## Best Practices

### Versioning
- **Use specific version tags** for production workflows
- **Keep latest tag updated** for development
- **Set up automated cleanup** for old images
- **Use multi-architecture builds** for compatibility

### Security
- **Use minimal base images** to reduce attack surface
- **Scan for vulnerabilities** regularly
- **Pin dependency versions** for reproducibility
- **Use non-root users** in containers

### Performance
- **Layer caching** for faster builds
- **Multi-stage builds** for smaller images
- **Regional mirrors** for global distribution
- **Parallel pulls** when possible

## Additional Resources

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [WDL Specification](https://github.com/openwdl/wdl)
- [Cromwell Documentation](https://cromwell.readthedocs.io/)
- [Terra Platform Documentation](https://support.terra.bio/)

GitHub Container Registry provides an excellent, integrated solution for hosting Docker images used in WDL workflows, especially for research projects already hosted on GitHub! 