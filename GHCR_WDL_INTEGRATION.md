# GitHub Container Registry (GHCR) with WDL

## Yes, WDL Can Use GitHub Container Registry!

This repository demonstrates complete integration of GitHub Container Registry with WDL workflows for federated GWAS analysis.

## What Was Implemented

### Multi-Registry CI/CD
- **Automated builds** to both DockerHub and GitHub Container Registry
- **Synchronized tagging** across registries
- **Matrix-based security scanning** for both registries
- **Unified authentication** using GitHub tokens

### WDL Configuration
- **DockerHub**: `docker: "mamana/gwas-tools:latest"`
- **GitHub Container Registry**: `docker: "ghcr.io/mamana/gwas-tools:latest"`
- **Flexible runtime configuration** via input JSON
- **Default GHCR configuration** in Cromwell options

### Complete Testing Suite
- **DockerHub test**: `inputs/test_gensetB.json`
- **GHCR test**: `inputs/test_gensetB_ghcr.json`
- **Registry-specific test scripts**
- **Fallback mechanisms** for development

## Registry Comparison

| Feature | DockerHub | GitHub Container Registry |
|---------|-----------|---------------------------|
| **WDL Support** | Full | Full |
| **Authentication** | Separate tokens | GitHub tokens |
| **Free Private Images** | 1 repository | Unlimited |
| **GitHub Integration** | External | Native |
| **Vulnerability Scanning** | Paid feature | Built-in |
| **Build Integration** | Manual setup | GitHub Actions |
| **Bandwidth Limits** | Limited | Generous |

## **Files Created**

- `.github/workflows/docker-build.yml` - Multi-registry build pipeline
- `.github/workflows/security-scan.yml` - Security scanning workflow
- `inputs/test_gensetB_ghcr.json` - GHCR test configuration
- `scripts/test_ghcr.sh` - GHCR-specific test script
- `docs/GITHUB_CONTAINER_REGISTRY.md` - Complete documentation
- `docs/DOCKER_CI_SETUP.md` - CI/CD setup guide
- `docker/README.md` - Container documentation
- `.dockerignore` - Optimized build context
- `cromwell.options.json` - Default GHCR configuration
- `GHCR_WDL_INTEGRATION.md` - This file

## **Usage Examples**

### Run with DockerHub
```bash
./scripts/run_pipeline.sh inputs/test_gensetB.json
```

### Run with GitHub Container Registry
```bash
./scripts/run_pipeline.sh inputs/test_gensetB_ghcr.json
```

### Override Registry in Any Input
```json
{
  "GWASPipeline.docker_image": "ghcr.io/mamana/gwas-tools:latest"
}
```

### Test Both Registries
```bash
# Test DockerHub
./scripts/test_gensetB.sh

# Test GHCR
./scripts/test_ghcr.sh
```

## **Platform Support**

Both registries work seamlessly with:
- **Terra/AnVIL**: Full support
- **DNAstack Workbench**: Full support
- **Nextflow Tower**: Full support
- **AWS Batch**: Full support
- **Google Cloud Life Sciences**: Full support
- **Azure Container Instances**: Full support

### Platform-Specific Configuration

#### Terra/AnVIL
```json
{
  "GWASPipeline.docker_image": "ghcr.io/mamana/gwas-tools:latest"
}
```

#### DNAstack
No special configuration needed - works with standard WDL runtime blocks.

## **Quick Start**

### 1. Clone Repository
```bash
git clone https://github.com/mamanambiya/federated-gwas-workshop-2025.git
cd federated-gwas-workshop-2025
```

### 2. Test GitHub Container Registry
```bash
# Pull the image
docker pull ghcr.io/mamana/gwas-tools:latest

# Run the test
./scripts/test_ghcr.sh
```

### 3. Run Full Pipeline
```bash
# With test data
./scripts/run_pipeline.sh inputs/test_gensetB_ghcr.json

# With your data
# Edit inputs/test_gensetB_ghcr.json with your file paths
./scripts/run_pipeline.sh inputs/your_data_ghcr.json
```

### 4. Verify Results
```bash
# Check outputs
ls -la outputs/
```

## **Automatic Publishing**

GitHub Actions automatically:
1. **Builds** multi-architecture images on push
2. **Tags** with version, latest, and commit SHA
3. **Pushes** to both registries simultaneously
4. **Scans** for vulnerabilities
5. **Updates** registry descriptions

## **Benefits of GitHub Container Registry for GWAS**

### Research Collaboration
- **Open Science**: Better support for public research containers
- **Global Access**: CDN for faster pulls worldwide
- **Version Control**: Tied to Git commits and releases
- **Compliance**: Audit trails and access controls

### Technical Advantages
- **Integration**: Native GitHub Actions support
- **Unified Management**: Packages tab in GitHub repository
- **CI/CD Integration**: Native GitHub Actions support
- **Security**: Built-in vulnerability scanning
- **Cost**: Free for public repositories

### Performance
- **Performance**: Better bandwidth limits
- **Versioning**: Integrated with Git tags and releases
- **Security**: Repository-level permissions

## **Migration Guide**

### From DockerHub to GHCR
1. Update `docker_image` in input JSON files
2. No changes to WDL files needed
3. Authentication handled automatically in GitHub Actions

### Using Both Registries
```json
// DockerHub
"docker_image": "mamana/gwas-tools:latest"

// GitHub Container Registry
"docker_image": "ghcr.io/mamana/gwas-tools:latest"
```

## **Best Practices**

### Registry Selection
- **Use GHCR** for GitHub-hosted research projects
- **Use DockerHub** for maximum ecosystem compatibility
- **Use both** for redundancy and broader access

### Version Management
- **Tag versions** for reproducibility (`v1.0.0`)
- Keep `latest` for development
- Use commit SHAs for debugging

## **Security Considerations**

- Public images require no authentication
- Private images use GitHub tokens
- Vulnerability scanning included
- SBOM generation available

## **Ready to Use!**

The pipeline now supports both registries with:
- Automated builds and publishing
- Complete test coverage
- Platform compatibility
- Security scanning
- Documentation

Start using GitHub Container Registry with your WDL workflows today for better integration, performance, and collaboration in federated genomics research! 