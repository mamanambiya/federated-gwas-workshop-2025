# GitHub Container Registry as Default

As of this update, the Federated GWAS Workshop 2025 pipeline uses **GitHub Container Registry (ghcr.io)** as the default container registry.

## Why GHCR as Default?

1. **Seamless GitHub Integration**: No separate authentication needed
2. **Better Bandwidth**: Generous bandwidth limits for public repositories
3. **Built-in Security**: Vulnerability scanning included
4. **Unified Permissions**: Same access control as your GitHub repository
5. **Free Private Repos**: Unlimited private repositories (vs 1 on DockerHub)

## Configuration Changes

All configuration files have been updated to use GHCR by default:

| File | Default Image |
|------|---------------|
| `workflows/gwas_pipeline.wdl` | `ghcr.io/mamanambiya/gwas-tools:latest` |
| `cromwell.options.json` | `ghcr.io/mamanambiya/gwas-tools:latest` |
| `inputs/test_gensetB.json` | `ghcr.io/mamanambiya/gwas-tools:latest` |
| `inputs/test_gensetB_ghcr.json` | `ghcr.io/mamanambiya/gwas-tools:latest` |
| `inputs/test_local.json` | `ghcr.io/mamanambiya/gwas-tools:latest` |
| `scripts/run_pipeline.sh` | `ghcr.io/mamanambiya/gwas-tools:latest` |

## Using DockerHub (Alternative)

If you prefer to use DockerHub, simply update the `docker_image` parameter in your input JSON:

```json
{
  "GWASPipeline.docker_image": "mamana/gwas-tools:latest"
}
```

## Migration Notes

- No changes to WDL logic required
- Only the docker runtime specification changes
- Both registries are built and maintained by GitHub Actions
- You can mix registries in multi-workflow projects

## Pull Commands

```bash
# GitHub Container Registry (default)
docker pull ghcr.io/mamanambiya/gwas-tools:latest

# DockerHub (alternative)
docker pull mamana/gwas-tools:latest
``` 