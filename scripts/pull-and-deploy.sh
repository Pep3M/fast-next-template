#!/bin/bash

# Script para descargar y desplegar la última versión en producción
# Este script debe ejecutarse EN EL SERVIDOR DE PRODUCCIÓN

set -e  # Detener si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Phone Services - Pull & Deploy Script ===${NC}\n"

# Cargar variables de entorno
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo -e "${YELLOW}Please create .env file with required variables${NC}"
    echo -e "${YELLOW}Example: cp config.env.prod.example .env${NC}"
    exit 1
fi

echo -e "${YELLOW}Loading environment variables from .env${NC}"
export $(cat .env | grep -v '^#' | xargs)

# Variables
COMPOSE_FILE="docker-compose.prod.yml"
SERVICE_NAME="app"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Registry: ${DOCKER_REGISTRY:-ghcr.io}"
echo "  Username: ${DOCKER_USERNAME:-username}"
echo "  Image Tag: ${IMAGE_TAG:-latest}"
echo ""

# Función para mostrar uso
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --tag TAG       Image tag to deploy (overrides .env)"
    echo "  --rollback TAG      Rollback to specific version"
    echo "  --logs              Show logs after deployment"
    echo "  --no-pull           Skip pulling new image"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Deploy latest version"
    echo "  $0 -t v1.0.0                 # Deploy specific version"
    echo "  $0 --rollback v0.9.0         # Rollback to v0.9.0"
    echo "  $0 --logs                    # Deploy and show logs"
    echo ""
    exit 1
}

# Variables de control
SKIP_PULL=false
SHOW_LOGS=false
CUSTOM_TAG=""

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            CUSTOM_TAG="$2"
            shift 2
            ;;
        --rollback)
            CUSTOM_TAG="$2"
            echo -e "${YELLOW}⚠️  Rollback mode: deploying version $2${NC}"
            shift 2
            ;;
        --logs)
            SHOW_LOGS=true
            shift
            ;;
        --no-pull)
            SKIP_PULL=true
            shift
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

# Usar tag personalizado si se especificó
if [ -n "$CUSTOM_TAG" ]; then
    export IMAGE_TAG="$CUSTOM_TAG"
    echo -e "${BLUE}Using custom tag: ${IMAGE_TAG}${NC}\n"
fi

# Verificar que Docker está corriendo
echo -e "${YELLOW}Checking Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Verificar que docker-compose.prod.yml existe
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}Error: $COMPOSE_FILE not found${NC}"
    exit 1
fi

# Paso 1: Backup de la versión actual (opcional)
echo -e "${GREEN}Step 1/4: Saving current version info...${NC}"
CURRENT_IMAGE=$(docker-compose -f $COMPOSE_FILE images -q app 2>/dev/null || echo "none")
if [ "$CURRENT_IMAGE" != "none" ]; then
    echo "Current image ID: $CURRENT_IMAGE" > .last-deployment
    echo -e "${GREEN}✓ Current version saved for potential rollback${NC}\n"
else
    echo -e "${YELLOW}⚠ No previous deployment found${NC}\n"
fi

# Paso 2: Pull de la nueva imagen
if [ "$SKIP_PULL" = false ]; then
    echo -e "${GREEN}Step 2/4: Pulling new image...${NC}"
    if docker-compose -f $COMPOSE_FILE pull $SERVICE_NAME; then
        echo -e "${GREEN}✓ Image pulled successfully${NC}\n"
    else
        echo -e "${RED}✗ Failed to pull image${NC}"
        echo -e "${YELLOW}Possible causes:${NC}"
        echo "  - Authentication required: run 'docker login'"
        echo "  - Image tag doesn't exist: check registry"
        echo "  - Network issues: check connectivity"
        exit 1
    fi
else
    echo -e "${YELLOW}Step 2/4: Skipping pull (--no-pull flag)${NC}\n"
fi

# Paso 3: Desplegar
echo -e "${GREEN}Step 3/4: Deploying application...${NC}"
if docker-compose -f $COMPOSE_FILE up -d $SERVICE_NAME; then
    echo -e "${GREEN}✓ Application deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

# Paso 4: Verificar salud del servicio
echo -e "${GREEN}Step 4/4: Verifying deployment...${NC}"
echo -e "${YELLOW}Waiting for service to be healthy...${NC}"

# Esperar hasta 60 segundos para que el servicio esté saludable
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' phone-services-app-prod 2>/dev/null || echo "unknown")
    
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}✓ Service is healthy${NC}\n"
        break
    elif [ "$HEALTH" = "unhealthy" ]; then
        echo -e "${RED}✗ Service is unhealthy${NC}"
        echo -e "${YELLOW}Showing recent logs:${NC}"
        docker-compose -f $COMPOSE_FILE logs --tail=50 $SERVICE_NAME
        exit 1
    else
        echo -n "."
        sleep 2
        WAITED=$((WAITED + 2))
    fi
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "${YELLOW}⚠ Health check timeout (service may still be starting)${NC}"
    echo -e "${YELLOW}Check logs with: docker-compose -f $COMPOSE_FILE logs -f app${NC}\n"
fi

# Mostrar estado de servicios
echo -e "${GREEN}=== Deployment Summary ===${NC}\n"
docker-compose -f $COMPOSE_FILE ps

echo ""
echo -e "${GREEN}=== Deployed Image Info ===${NC}"
docker-compose -f $COMPOSE_FILE images $SERVICE_NAME

# Mostrar logs si se solicitó
if [ "$SHOW_LOGS" = true ]; then
    echo ""
    echo -e "${GREEN}=== Application Logs ===${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}\n"
    docker-compose -f $COMPOSE_FILE logs -f $SERVICE_NAME
fi

# Instrucciones finales
echo ""
echo -e "${GREEN}=== Deployment Completed Successfully ===${NC}\n"
echo -e "${YELLOW}Useful commands:${NC}"
echo "  View logs:      docker-compose -f $COMPOSE_FILE logs -f app"
echo "  View status:    docker-compose -f $COMPOSE_FILE ps"
echo "  Restart app:    docker-compose -f $COMPOSE_FILE restart app"
echo "  Stop all:       docker-compose -f $COMPOSE_FILE down"
echo ""

if [ -f .last-deployment ]; then
    echo -e "${YELLOW}Rollback available:${NC}"
    echo "  If something went wrong, you can rollback with:"
    echo "  IMAGE_TAG=<previous-tag> docker-compose -f $COMPOSE_FILE up -d"
fi

echo ""
