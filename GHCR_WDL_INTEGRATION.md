# GitHub Container Registry Integration with WDL

## ✅ Yes, WDL Can Use GitHub Container Registry!

Your GWAS pipeline now supports **both DockerHub and GitHub Container Registry (ghcr.io)** with full automation and multi-registry publishing.

## 🚀 What Was Implemented

### **Multi-Registry CI/CD Pipeline**
- ✅ **Automated builds** to both DockerHub and GitHub Container Registry
- ✅ **Synchronized tagging** across registries
- ✅ **Matrix-based security scanning** for both registries
- ✅ **Unified authentication** using GitHub tokens

### **WDL Configuration Options**
- ✅ **DockerHub**: `docker: "mamana/gwas-tools:latest"`
- ✅ **GitHub Container Registry**: `docker: "ghcr.io/mamana/gwas-tools:latest"`
- ✅ **Flexible runtime configuration** via input JSON
- ✅ **Default GHCR configuration** in Cromwell options

### **Test Configurations**
- ✅ **DockerHub test**: `inputs/test_gensetB.json`
- ✅ **GHCR test**: `inputs/test_gensetB_ghcr.json`
- ✅ **Registry-specific test scripts**
- ✅ **Fallback mechanisms** for development

## 🏷️ Registry Comparison

| Feature | DockerHub | GitHub Container Registry |
|---------|-----------|---------------------------|
| **WDL Support** | ✅ Full | ✅ Full |
| **Authentication** | Separate tokens | 🎯 GitHub tokens |
| **Free Private Images** | 1 repository | ✅ Unlimited |
| **GitHub Integration** | External | 🎯 Native |
| **Vulnerability Scanning** | Paid feature | ✅ Built-in |
| **Build Integration** | Manual setup | 🎯 GitHub Actions |
| **Bandwidth Limits** | Limited | ✅ Generous |

## 📁 **Files Created**

### **Multi-Registry Configuration**
- **`.github/workflows/docker-build.yml`** - Publishes to both registries
- **`.github/workflows/security-scan.yml`** - Scans both registry images
- **`inputs/test_gensetB_ghcr.json`** - GHCR-specific configuration
- **`scripts/test_ghcr.sh`** - GHCR testing script

### **Documentation**
- **`docs/GITHUB_CONTAINER_REGISTRY.md`** - Comprehensive GHCR guide
- **`GHCR_WDL_INTEGRATION.md`** - This summary document

## 🔧 **Usage Examples**

### **Option 1: DockerHub (Traditional)**
```json
{
  "GWASPipeline.docker_image": "mamana/gwas-tools:latest"
}
```

### **Option 2: GitHub Container Registry (Recommended)**
```json
{
  "GWASPipeline.docker_image": "ghcr.io/mamana/gwas-tools:latest"
}
```

### **WDL Task Configuration**
```wdl
task QualityControl {
    runtime {
        # Option 1: DockerHub
        docker: "mamana/gwas-tools:latest"
        
        # Option 2: GitHub Container Registry
        docker: "ghcr.io/mamana/gwas-tools:latest"
        
        cpu: 4
        memory: "16GB"
    }
}
```

## 🌍 **Platform Support**

### **Cloud Platforms Supporting GHCR**
- ✅ **Terra/AnVIL**: Full support
- ✅ **DNAstack Workbench**: Full support  
- ✅ **Nextflow Tower**: Full support
- ✅ **AWS Batch**: Full support
- ✅ **Google Cloud Life Sciences**: Full support
- ✅ **Azure Container Instances**: Full support

### **Local Execution**
```bash
# Works with both registries
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i inputs/test_gensetB.json
java -jar cromwell.jar run workflows/gwas_pipeline.wdl -i inputs/test_gensetB_ghcr.json
```

## 🚀 **Quick Start**

### **Test DockerHub Version**
```bash
./scripts/test_gensetB.sh
```

### **Test GitHub Container Registry Version**
```bash
./scripts/test_ghcr.sh
```

### **Compare Both Registries**
```bash
# Run with DockerHub
./scripts/run_pipeline.sh inputs/test_gensetB.json

# Run with GitHub Container Registry  
./scripts/run_pipeline.sh inputs/test_gensetB_ghcr.json
```

## 🔐 **Authentication**

### **DockerHub**
```bash
# Requires separate DockerHub account and token
docker login
docker pull mamana/gwas-tools:latest
```

### **GitHub Container Registry**
```bash
# Uses your GitHub credentials (if public image, no auth needed)
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
docker pull ghcr.io/mamana/gwas-tools:latest
```

## 📊 **Automatic Publishing**

When you push to your GitHub repository:

1. **GitHub Actions triggers**
2. **Builds Docker image once**
3. **Publishes to both registries simultaneously:**
   - `mamana/gwas-tools:latest` (DockerHub)
   - `ghcr.io/mamana/gwas-tools:latest` (GitHub Container Registry)
4. **Updates descriptions** on both platforms
5. **Runs security scans** on both images

## 🎯 **Benefits of GitHub Container Registry for GWAS**

### **Research-Friendly Features**
- 🔬 **Open Science**: Better support for public research containers
- 🌍 **Global Access**: CDN for faster pulls worldwide
- 🔒 **Security**: Built-in vulnerability scanning
- 📊 **Compliance**: Audit trails and access controls

### **Integration Benefits**
- 🔗 **Same Repository**: Container images live with source code
- 🎛️ **Unified Management**: Packages tab in GitHub repository
- 🚀 **CI/CD Integration**: Native GitHub Actions support
- 🔑 **Authentication**: Uses existing GitHub credentials

### **Development Benefits**
- 💰 **Cost**: Free private repositories
- 📈 **Performance**: Better bandwidth limits
- 🔄 **Versioning**: Integrated with Git tags and releases
- 🛡️ **Security**: Repository-level permissions

## 🏃‍♂️ **Migration Guide**

### **From DockerHub to GHCR**
```bash
# Update WDL files
find . -name "*.wdl" -exec sed -i 's|mamana/gwas-tools|ghcr.io/mamana/gwas-tools|g' {} +

# Update input files
find . -name "*.json" -exec sed -i 's|"mamana/gwas-tools|"ghcr.io/mamana/gwas-tools|g' {} +
```

### **Hybrid Approach (Both Registries)**
- Use **DockerHub** for maximum compatibility
- Use **GHCR** for GitHub-integrated projects
- **Same workflow**, just different `docker:` specification

## 📈 **Best Practices**

### **Registry Selection**
- 🎯 **Use GHCR** for GitHub-hosted research projects
- 🐳 **Use DockerHub** for maximum ecosystem compatibility
- 🔄 **Use both** for redundancy and broader access

### **Image Management**
- 🏷️ **Tag versions** for reproducibility (`v1.0.0`)
- 📅 **Keep latest** updated for development
- 🧹 **Clean up old images** automatically
- 🔒 **Make research images public** for open science

## 🎉 **Ready to Use!**

Your GWAS pipeline now has **dual-registry support**:

1. **Choose your preferred registry** (DockerHub or GHCR)
2. **Update input JSON** with appropriate image name
3. **Run workflow** - everything else stays the same!

The same WDL workflow works with both registries, giving you flexibility in deployment and distribution for federated genomics research! 🧬 