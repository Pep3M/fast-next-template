#!/bin/bash

# Script para construir y subir la imagen Docker de phone-services-app
# Este script debe ejecutarse en LOCAL antes del despliegue en producción

set -e  # Detener si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Phone Services - Build & Push Script ===${NC}\n"

# Cargar variables de entorno si existe .env.build
if [ -f .env.build ]; then
    echo -e "${YELLOW}Loading environment variables from .env.build${NC}"
    export $(cat .env.build | grep -v '^#' | xargs)
fi

# Variables configurables (pueden ser sobrescritas por .env.build o argumentos)
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"ghcr.io"}
DOCKER_USERNAME=${DOCKER_USERNAME:-"username"}
IMAGE_NAME=${IMAGE_NAME:-"phone-services-app"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Convertir a minúsculas (Docker requiere nombres de repositorio en minúsculas)
DOCKER_USERNAME=$(echo "$DOCKER_USERNAME" | tr '[:upper:]' '[:lower:]')
IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')

# Construir el nombre completo de la imagen
FULL_IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Registry: ${DOCKER_REGISTRY}"
echo "  Username: ${DOCKER_USERNAME}"
echo "  Image Name: ${IMAGE_NAME}"
echo "  Tag: ${IMAGE_TAG}"
echo "  Full Image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# Función para mostrar uso
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --registry REGISTRY    Docker registry (default: ghcr.io)"
    echo "  -u, --username USERNAME    Docker username/organization"
    echo "  -n, --name NAME           Image name (default: phone-services-app)"
    echo "  -t, --tag TAG             Image tag (default: latest)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -u myuser -t v1.0.0"
    echo "  $0 --registry docker.io --username mycompany --tag production"
    echo ""
    exit 1
}

# Parsear argumentos
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

# Validar que el usuario esté autenticado en el registry
echo -e "${YELLOW}Checking Docker authentication...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

# Verificar si ya hay una sesión activa (esto depende del registry)
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Validar que NEXT_PUBLIC_BETTER_AUTH_URL esté configurada
if [ -z "$NEXT_PUBLIC_BETTER_AUTH_URL" ]; then
    echo -e "${YELLOW}⚠ WARNING: NEXT_PUBLIC_BETTER_AUTH_URL is not set${NC}"
    echo -e "${YELLOW}   Using default: http://localhost:5023${NC}"
    echo -e "${YELLOW}   Set NEXT_PUBLIC_BETTER_AUTH_URL in .env.build or export it before running this script${NC}\n"
    NEXT_PUBLIC_BETTER_AUTH_URL="http://localhost:5023"
else
    echo -e "${GREEN}✓ NEXT_PUBLIC_BETTER_AUTH_URL: ${NEXT_PUBLIC_BETTER_AUTH_URL}${NC}\n"
fi

# Paso 1: Construir la imagen
echo -e "${GREEN}Step 1/3: Building Docker image...${NC}"
docker build \
    --platform linux/amd64 \
    --build-arg DATABASE_URL="postgresql://buildtime:buildtime@localhost:5432/buildtime" \
    --build-arg NEXT_PUBLIC_BETTER_AUTH_URL="${NEXT_PUBLIC_BETTER_AUTH_URL}" \
    -t ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
    -t ${FULL_IMAGE_NAME}:latest \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Image built successfully${NC}\n"
else
    echo -e "${RED}✗ Error building image${NC}"
    exit 1
fi

# Paso 2: Hacer tag adicional con timestamp para versionado
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo -e "${GREEN}Step 2/3: Creating additional tag with timestamp...${NC}"
docker tag ${FULL_IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}:${TIMESTAMP}
echo -e "${GREEN}✓ Tagged as ${FULL_IMAGE_NAME}:${TIMESTAMP}${NC}\n"

# Paso 3: Subir la imagen al registry
echo -e "${GREEN}Step 3/3: Pushing image to registry...${NC}"
echo -e "${YELLOW}Pushing ${FULL_IMAGE_NAME}:${IMAGE_TAG}${NC}"
docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}

echo -e "${YELLOW}Pushing ${FULL_IMAGE_NAME}:latest${NC}"
docker push ${FULL_IMAGE_NAME}:latest

echo -e "${YELLOW}Pushing ${FULL_IMAGE_NAME}:${TIMESTAMP}${NC}"
docker push ${FULL_IMAGE_NAME}:${TIMESTAMP}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Images pushed successfully${NC}\n"
else
    echo -e "${RED}✗ Error pushing images${NC}"
    exit 1
fi

# Resumen
echo -e "${GREEN}=== Build & Push Completed Successfully ===${NC}\n"
echo -e "${YELLOW}Images pushed:${NC}"
echo "  - ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
echo "  - ${FULL_IMAGE_NAME}:latest"
echo "  - ${FULL_IMAGE_NAME}:${TIMESTAMP}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update your .env file on production server with:"
echo "     DOCKER_REGISTRY=${DOCKER_REGISTRY}"
echo "     DOCKER_USERNAME=${DOCKER_USERNAME}"
echo "     IMAGE_TAG=${IMAGE_TAG}"
echo ""
echo "  2. On production server, run:"
echo "     docker-compose -f docker-compose.prod.yml pull"
echo "     docker-compose -f docker-compose.prod.yml up -d"
echo ""
