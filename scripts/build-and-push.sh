#!/bin/bash

# Builds and pushes the Docker image to a container registry.
# Run this script locally to manually build and publish the image.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== fast-next-template - Build & Push ===${NC}\n"

# Load environment variables from .env.build if it exists
if [ -f .env.build ]; then
    echo -e "${YELLOW}Loading environment variables from .env.build${NC}"
    export $(cat .env.build | grep -v '^#' | xargs)
fi

# Configurable variables (can be overridden by .env.build or CLI arguments)
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io"}
DOCKER_USERNAME=${DOCKER_USERNAME:-"username"}
IMAGE_NAME=${IMAGE_NAME:-"fast-next-template"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Docker requires lowercase repository names
DOCKER_USERNAME=$(echo "$DOCKER_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')

FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Registry:   ${DOCKER_REGISTRY}"
echo "  Username:   ${DOCKER_USERNAME}"
echo "  Image name: ${IMAGE_NAME}"
echo "  Tag:        ${IMAGE_TAG}"
echo "  Full image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo ""

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --registry REGISTRY    Docker registry (default: ghcr.io)"
    echo "  -u, --username USERNAME    Docker username or organization"
    echo "  -n, --name NAME            Image name (default: fast-next-template)"
    echo "  -t, --tag TAG              Image tag (default: latest)"
    echo "  -h, --help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -u myuser -t v1.0.0"
    echo "  $0 --registry docker.io --username mycompany --tag production"
    echo ""
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Check Docker is running
echo -e "${YELLOW}Checking Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Warn if NEXT_PUBLIC_BETTER_AUTH_URL is not set
if [ -z "$NEXT_PUBLIC_BETTER_AUTH_URL" ]; then
    echo -e "${YELLOW}⚠ NEXT_PUBLIC_BETTER_AUTH_URL is not set — defaulting to http://localhost:5023${NC}"
    echo -e "${YELLOW}  Set it in .env.build or export it before running this script${NC}\n"
    NEXT_PUBLIC_BETTER_AUTH_URL="http://localhost:5023"
else
    echo -e "${GREEN}✓ NEXT_PUBLIC_BETTER_AUTH_URL: ${NEXT_PUBLIC_BETTER_AUTH_URL}${NC}\n"
fi

# Step 1: Build image
echo -e "${GREEN}Step 1/3: Building Docker image...${NC}"
docker build \
    --platform linux/amd64 \
    --build-arg DATABASE_URL="postgresql://buildtime:buildtime@localhost:5432/buildtime" \
    --build-arg NEXT_PUBLIC_BETTER_AUTH_URL="${NEXT_PUBLIC_BETTER_AUTH_URL}" \
    -t ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
    -t ${FULL_IMAGE_NAME}:latest \
    -f Dockerfile \
    .
echo -e "${GREEN}✓ Image built successfully${NC}\n"

# Step 2: Tag with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo -e "${GREEN}Step 2/3: Tagging with timestamp ${TIMESTAMP}...${NC}"
docker tag ${FULL_IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${TIMESTAMP}
echo -e "${GREEN}✓ Tagged as ${FULL_IMAGE_NAME}:${TIMESTAMP}${NC}\n"

# Step 3: Push images
echo -e "${GREEN}Step 3/3: Pushing images to registry...${NC}"
docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
docker push ${FULL_IMAGE_NAME}:latest
docker push ${FULL_IMAGE_NAME}:${TIMESTAMP}
echo -e "${GREEN}✓ Images pushed successfully${NC}\n"

# Summary
echo -e "${GREEN}=== Build & Push Completed ===${NC}\n"
echo -e "${YELLOW}Images published:${NC}"
echo "  ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "  ${FULL_IMAGE_NAME}:latest"
echo "  ${FULL_IMAGE_NAME}:${TIMESTAMP}"
echo ""
echo -e "${YELLOW}Pull the image on your server:${NC}"
echo "  docker pull ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo ""
