#!/bin/bash

## Local Docker Build and Test Script
## GA4GH Hackathon 2025 - African Genomics Team

set -euo pipefail

echo "🐳 Local Docker Build and Test"
echo "=============================="
echo ""

# Configuration
IMAGE_NAME="gwas-tools-local"
DOCKERFILE_PATH="docker/Dockerfile"
BUILD_CONTEXT="."

# Check if we're in the right directory
if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    echo "❌ Error: Dockerfile not found at $DOCKERFILE_PATH"
    echo "   Please run this script from the project root directory"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "   Please start Docker and try again"
    exit 1
fi

echo "📋 Build Configuration:"
echo "  Image name: $IMAGE_NAME"
echo "  Dockerfile: $DOCKERFILE_PATH"
echo "  Build context: $BUILD_CONTEXT"
echo "  Docker version: $(docker --version)"
echo ""

# Build the image
echo "🔨 Building Docker image..."
echo "   This may take 10-15 minutes for the first build..."
echo ""

# Add build arguments
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

if docker build \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VCS_REF="$VCS_REF" \
    -t "$IMAGE_NAME:latest" \
    -f "$DOCKERFILE_PATH" \
    "$BUILD_CONTEXT"; then
    echo "✅ Docker image built successfully!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

echo ""

# Get image information
echo "📊 Image Information:"
IMAGE_SIZE=$(docker images "$IMAGE_NAME:latest" --format "{{.Size}}")
IMAGE_ID=$(docker images "$IMAGE_NAME:latest" --format "{{.ID}}")
echo "  Image ID: $IMAGE_ID"
echo "  Size: $IMAGE_SIZE"
echo ""

# Test basic functionality
echo "🧪 Testing Image Functionality:"
echo ""

# Test 1: Basic container startup
echo "  Test 1: Container startup..."
if docker run --rm "$IMAGE_NAME:latest" echo "Container started successfully"; then
    echo "  ✅ Container startup: PASSED"
else
    echo "  ❌ Container startup: FAILED"
    exit 1
fi

# Test 2: PLINK installation
echo "  Test 2: PLINK installation..."
if docker run --rm "$IMAGE_NAME:latest" plink2 --version >/dev/null 2>&1; then
    PLINK_VERSION=$(docker run --rm "$IMAGE_NAME:latest" plink2 --version 2>&1 | head -1)
    echo "  ✅ PLINK installation: PASSED ($PLINK_VERSION)"
else
    echo "  ❌ PLINK installation: FAILED"
    exit 1
fi

# Test 3: bcftools installation
echo "  Test 3: bcftools installation..."
if docker run --rm "$IMAGE_NAME:latest" bcftools --version >/dev/null 2>&1; then
    BCFTOOLS_VERSION=$(docker run --rm "$IMAGE_NAME:latest" bcftools --version 2>&1 | head -1)
    echo "  ✅ bcftools installation: PASSED ($BCFTOOLS_VERSION)"
else
    echo "  ❌ bcftools installation: FAILED"
    exit 1
fi

# Test 4: R installation
echo "  Test 4: R installation..."
if docker run --rm "$IMAGE_NAME:latest" R --version >/dev/null 2>&1; then
    R_VERSION=$(docker run --rm "$IMAGE_NAME:latest" R --version 2>&1 | head -1)
    echo "  ✅ R installation: PASSED ($R_VERSION)"
else
    echo "  ❌ R installation: FAILED"
    exit 1
fi

# Test 5: R packages
echo "  Test 5: R packages..."
if docker run --rm "$IMAGE_NAME:latest" R -e "library(data.table); library(ggplot2)" >/dev/null 2>&1; then
    echo "  ✅ R packages: PASSED (data.table, ggplot2)"
else
    echo "  ❌ R packages: FAILED"
    exit 1
fi

# Test 6: Python installation
echo "  Test 6: Python installation..."
if docker run --rm "$IMAGE_NAME:latest" python3 --version >/dev/null 2>&1; then
    PYTHON_VERSION=$(docker run --rm "$IMAGE_NAME:latest" python3 --version 2>&1)
    echo "  ✅ Python installation: PASSED ($PYTHON_VERSION)"
else
    echo "  ❌ Python installation: FAILED"
    exit 1
fi

# Test 7: Python packages
echo "  Test 7: Python packages..."
if docker run --rm "$IMAGE_NAME:latest" python3 -c "import pandas, numpy, scipy, matplotlib" >/dev/null 2>&1; then
    echo "  ✅ Python packages: PASSED (pandas, numpy, scipy, matplotlib)"
else
    echo "  ❌ Python packages: FAILED"
    exit 1
fi

# Test 8: Non-root user
echo "  Test 8: Non-root user..."
USER_ID=$(docker run --rm "$IMAGE_NAME:latest" id -u)
if [[ "$USER_ID" != "0" ]]; then
    echo "  ✅ Non-root user: PASSED (UID: $USER_ID)"
else
    echo "  ❌ Non-root user: FAILED (running as root)"
    exit 1
fi

# Test 9: Health check
echo "  Test 9: Health check..."
if docker run --rm "$IMAGE_NAME:latest" plink2 --help >/dev/null 2>&1; then
    echo "  ✅ Health check: PASSED"
else
    echo "  ❌ Health check: FAILED"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Docker image is ready for use."
echo ""

# Show usage examples
echo "📖 Usage Examples:"
echo ""
echo "  # Run interactive shell:"
echo "  docker run -it --rm $IMAGE_NAME:latest"
echo ""
echo "  # Mount data directory:"
echo "  docker run -it --rm -v \$(pwd)/tests/data:/data $IMAGE_NAME:latest"
echo ""
echo "  # Run PLINK command:"
echo "  docker run --rm -v \$(pwd)/tests/data:/data $IMAGE_NAME:latest \\"
echo "    plink2 --bfile /data/gensetB --freq --out /data/output"
echo ""

# Cleanup option
echo "🧹 Cleanup:"
echo "  To remove the test image: docker rmi $IMAGE_NAME:latest"
echo ""

# Tag for upload (optional)
read -p "🚀 Tag image for upload to registry? [y/N]: " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter registry/image name (e.g., mamana/gwas-tools): " REGISTRY_IMAGE
    if [[ -n "$REGISTRY_IMAGE" ]]; then
        docker tag "$IMAGE_NAME:latest" "$REGISTRY_IMAGE:latest"
        echo "✅ Tagged as $REGISTRY_IMAGE:latest"
        echo "   To push: docker push $REGISTRY_IMAGE:latest"
    fi
fi

echo ""
echo "✅ Docker build and test completed successfully!" 