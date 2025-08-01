# Docker CI/CD Setup Guide

This guide explains how to set up automated Docker image builds and publishing to DockerHub using GitHub Actions.

## Overview

The CI/CD pipeline automatically:
- Builds Docker images on every push to main/master
- Supports multi-architecture builds (AMD64, ARM64)
- Pushes images to DockerHub with proper tagging
- Updates DockerHub description automatically
- Caches layers for faster builds
- Triggers on Dockerfile changes, releases, and manual dispatch

## Prerequisites

1. **DockerHub Account**: Create account at [hub.docker.com](https://hub.docker.com)
2. **GitHub Repository**: Fork or create the repository
3. **DockerHub Repository**: Create `mamana/gwas-tools` repository on DockerHub

## Setup Instructions

### 1. Create DockerHub Access Token

1. Log in to [DockerHub](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Set description: "GitHub Actions - GWAS Pipeline"
5. Set permissions: **Read, Write, Delete**
6. Copy the generated token (save securely - you won't see it again)

### 2. Configure GitHub Secrets

Navigate to your GitHub repository settings:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

#### Required Secrets

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DOCKERHUB_USERNAME` | `mamana` | Your DockerHub username |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` | DockerHub access token from step 1 |

#### Adding Secrets

```bash
# Navigate to: https://github.com/YOUR_USERNAME/federated-gwas-workshop-2025/settings/secrets/actions
# Add each secret individually
```

### 3. Update Image Name (Optional)

If you want to use a different DockerHub repository:

1. Edit `.github/workflows/docker-build.yml`
2. Update the `DOCKER_IMAGE` environment variable:

```yaml
env:
  DOCKER_IMAGE: your-username/your-image-name
```

### 4. Verify Workflow

1. Push changes to your main/master branch
2. Go to **Actions** tab in your GitHub repository
3. Watch the "Build and Push Docker Image" workflow
4. Verify the image appears on DockerHub

## Workflow Triggers

The Docker build workflow triggers on:

### Automatic Triggers
- **Push to main/master** - When Dockerfile or workflow changes
- **Pull Requests** - Builds but doesn't push (testing only)
- **Releases** - Creates versioned tags

### Manual Trigger
- **workflow_dispatch** - Manual trigger from Actions tab

## Image Tagging Strategy

The workflow automatically creates multiple tags:

| Trigger | Tags Created | Example |
|---------|--------------|---------|
| Push to main | `latest`, `main-abc123` | `mamana/gwas-tools:latest` |
| Release v1.0.0 | `v1.0.0`, `1.0`, `latest` | `mamana/gwas-tools:v1.0.0` |
| Pull Request | `pr-123` | `mamana/gwas-tools:pr-123` |

## Multi-Architecture Support

The workflow builds for multiple architectures:
- **linux/amd64** - Intel/AMD processors
- **linux/arm64** - ARM processors (Apple Silicon, AWS Graviton)

Users can pull architecture-specific images:
```bash
# Automatic (Docker selects correct architecture)
docker pull mamana/gwas-tools:latest

# Specific architecture
docker pull --platform linux/amd64 mamana/gwas-tools:latest
docker pull --platform linux/arm64 mamana/gwas-tools:latest
```

## Build Optimization

The workflow includes several optimizations:

### Layer Caching
- Uses GitHub Actions cache for Docker layers
- Reduces build time for subsequent builds
- Automatically manages cache lifecycle

### Build Context
- Only includes necessary files in build context
- Uses `.dockerignore` to exclude large files

### Parallel Builds
- Builds multiple architectures in parallel
- Uses Docker Buildx for advanced features

## Monitoring and Troubleshooting

### Check Build Status

1. **GitHub Actions**: Monitor builds in real-time
2. **DockerHub**: Verify images are published
3. **Badges**: Add build status to README

### Common Issues

#### 1. Authentication Failed
```
Error: buildx failed with: error: failed to solve: failed to authorize
```
**Solution**: Check `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets

#### 2. Permission Denied
```
Error: denied: requested access to the resource is denied
```
**Solution**: Ensure DockerHub token has `Read, Write, Delete` permissions

#### 3. Repository Not Found
```
Error: repository does not exist or may require authentication
```
**Solution**: Create repository on DockerHub first, or check repository name

#### 4. Build Timeout
```
Error: The job running on runner has exceeded the maximum execution time
```
**Solution**: 
- Optimize Dockerfile (use smaller base image, combine RUN commands)
- Use multi-stage builds
- Check for hanging processes

### Build Logs

Access detailed build logs:
1. Go to **Actions** tab
2. Click on the failed workflow run
3. Expand the "Build and push Docker image" step
4. Review the detailed logs

## Security Considerations

### Token Management
- Use access tokens instead of passwords
- Limit token permissions to minimum required
- Regularly rotate access tokens
- Never expose tokens in logs or code

### Image Security
- Base image is regularly updated Ubuntu LTS
- Dependencies are pinned to specific versions
- No sensitive data in image layers
- Multi-architecture support reduces attack surface

### Repository Access
- Secrets are encrypted at rest
- Workflow runs in isolated environment
- No access to secrets in pull request workflows

## Advanced Configuration

### Custom Build Arguments

Add build arguments to the workflow:

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    build-args: |
      BUILD_DATE=${{ github.event.head_commit.timestamp }}
      VCS_REF=${{ github.sha }}
```

### Notification Setup

Add notifications for build status:

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Schedule Builds

Add scheduled builds for security updates:

```yaml
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly on Sunday at 2 AM
```

## Verification

### Test the Setup

1. **Local Build Test**:
```bash
# Test build locally
docker build -t test-gwas-tools -f docker/Dockerfile .
docker run -it --rm test-gwas-tools plink2 --help
```

2. **Pull and Test**:
```bash
# After CI/CD setup
docker pull mamana/gwas-tools:latest
docker run -it --rm mamana/gwas-tools:latest plink2 --version
```

3. **Multi-arch Test**:
```bash
# Test both architectures
docker run --platform linux/amd64 mamana/gwas-tools:latest uname -m
docker run --platform linux/arm64 mamana/gwas-tools:latest uname -m
```

## Support

- **GitHub Actions Documentation**: [docs.github.com/actions](https://docs.github.com/en/actions)
- **Docker Buildx**: [docs.docker.com/buildx](https://docs.docker.com/buildx/)
- **DockerHub**: [docs.docker.com/docker-hub](https://docs.docker.com/docker-hub/)

The automated Docker builds will ensure your GWAS tools container is always up-to-date and available for federated analysis workflows! 