#!/bin/bash

# Script para verificar, actualizar y desplegar servicios
# Soporta ambientes: development (dev) y production (prod)
# Este script debe ejecutarse EN EL SERVIDOR (dev o prod)

set -e  # Detener si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detectar ambiente automáticamente
# Buscar docker-compose específico o genérico
if [ -f "docker-compose.dev.yml" ]; then
    DEFAULT_ENV="dev"
    DEFAULT_COMPOSE="docker-compose.dev.yml"
elif [ -f "docker-compose.prod.yml" ]; then
    DEFAULT_ENV="prod"
    DEFAULT_COMPOSE="docker-compose.prod.yml"
elif [ -f "docker-compose.yml" ]; then
    # Intentar detectar por contenido del archivo
    if grep -q "phone-services-app:dev" "docker-compose.yml" 2>/dev/null; then
        DEFAULT_ENV="dev"
    else
        DEFAULT_ENV="prod"
    fi
    DEFAULT_COMPOSE="docker-compose.yml"
else
    DEFAULT_ENV="prod"
    DEFAULT_COMPOSE="docker-compose.prod.yml"
fi

# Variables
ENVIRONMENT="${DEFAULT_ENV}"
COMPOSE_FILE="${DEFAULT_COMPOSE}"
MAX_WAIT=60

echo -e "${GREEN}=== Phone Services - Deploy Script ===${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}\n"

# Función para mostrar uso
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --env ENV            Specify environment: dev or prod (auto-detected by default)"
    echo "  --skip-pull          Skip pulling new images"
    echo "  --skip-health-check  Skip health check after deployment"
    echo "  --logs               Show logs after deployment"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Environment Detection:"
    echo "  - If docker-compose.dev.yml exists → dev environment"
    echo "  - Otherwise → prod environment"
    echo ""
    exit 1
}

# Parsear argumentos
SKIP_PULL=false
SKIP_HEALTH_CHECK=true  # Por defecto true debido a basic auth de nginx
SHOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV_ARG="$2"
            if [ "$ENV_ARG" = "dev" ]; then
                ENVIRONMENT="dev"
                # Buscar archivo de dev en orden de prioridad
                if [ -f "docker-compose.dev.yml" ]; then
                    COMPOSE_FILE="docker-compose.dev.yml"
                elif [ -f "docker-compose.yml" ]; then
                    COMPOSE_FILE="docker-compose.yml"
                else
                    echo -e "${RED}No docker-compose file found for dev environment${NC}"
                    exit 1
                fi
            elif [ "$ENV_ARG" = "prod" ]; then
                ENVIRONMENT="prod"
                # Buscar archivo de prod en orden de prioridad
                if [ -f "docker-compose.prod.yml" ]; then
                    COMPOSE_FILE="docker-compose.prod.yml"
                elif [ -f "docker-compose.yml" ]; then
                    COMPOSE_FILE="docker-compose.yml"
                else
                    echo -e "${RED}No docker-compose file found for prod environment${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}Invalid environment: $ENV_ARG (use 'dev' or 'prod')${NC}"
                usage
            fi
            shift 2
            ;;
        --skip-pull)
            SKIP_PULL=true
            shift
            ;;
        --skip-health-check)
            SKIP_HEALTH_CHECK=true
            shift
            ;;
        --logs)
            SHOW_LOGS=true
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

echo -e "${BLUE}Using compose file: ${COMPOSE_FILE}${NC}\n"

# Paso 1: Verificar Docker
echo -e "${GREEN}Step 1/5: Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker daemon is not running${NC}"
    echo -e "${YELLOW}Try: sudo systemctl start docker${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed and running${NC}\n"

# Paso 2: Verificar Docker Compose
echo -e "${GREEN}Step 2/5: Checking Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi

# Detectar si es docker-compose o docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

COMPOSE_VERSION=$($COMPOSE_CMD version --short 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ Docker Compose is installed (version: $COMPOSE_VERSION)${NC}\n"

# Paso 3: Verificar archivo docker-compose.yml
echo -e "${GREEN}Step 3/6: Checking docker-compose configuration...${NC}"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}✗ $COMPOSE_FILE not found in current directory${NC}"
    echo -e "${YELLOW}Current directory: $(pwd)${NC}"
    exit 1
fi

# Validar sintaxis del archivo
if ! $COMPOSE_CMD -f "$COMPOSE_FILE" config > /dev/null 2>&1; then
    echo -e "${RED}✗ $COMPOSE_FILE has syntax errors${NC}"
    echo -e "${YELLOW}Validating configuration:${NC}"
    $COMPOSE_CMD -f "$COMPOSE_FILE" config
    exit 1
fi
echo -e "${GREEN}✓ $COMPOSE_FILE found and valid${NC}\n"

# Paso 4: Verificar variables de entorno críticas
echo -e "${GREEN}Step 4/6: Checking environment variables...${NC}"
# Cargar .env si existe
if [ -f ".env" ]; then
    echo -e "${YELLOW}Loading .env file...${NC}"
    export $(grep -v '^#' .env | xargs)
fi

# Verificar variables críticas
MISSING_VARS=false
if [ -z "$BETTER_AUTH_SECRET" ]; then
    echo -e "${YELLOW}⚠ BETTER_AUTH_SECRET not set (will use default from docker-compose)${NC}"
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo -e "${YELLOW}⚠ POSTGRES_PASSWORD not set (will use default 'postgres')${NC}"
fi

echo -e "${GREEN}✓ Environment variables checked${NC}\n"

# Paso 5: Verificar estado actual
echo -e "${GREEN}Step 5/6: Checking current services status...${NC}"
CURRENT_SERVICES=$($COMPOSE_CMD -f "$COMPOSE_FILE" ps --services 2>/dev/null || echo "")
if [ -n "$CURRENT_SERVICES" ]; then
    echo -e "${YELLOW}Current services:${NC}"
    $COMPOSE_CMD -f "$COMPOSE_FILE" ps
    echo ""
else
    echo -e "${YELLOW}No services currently running${NC}\n"
fi

# Paso 6: Pull de imágenes
if [ "$SKIP_PULL" = false ]; then
    echo -e "${GREEN}Step 6/7: Pulling latest images...${NC}"
    
    # Verificar autenticación si es necesario (para registries privados)
    if grep -q "ghcr.io\|docker.io" "$COMPOSE_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Checking Docker registry authentication...${NC}"
        if ! docker info | grep -q "Username"; then
            echo -e "${YELLOW}⚠ Not logged into registry. If images are private, you may need to run:${NC}"
            echo -e "${YELLOW}   docker login ghcr.io${NC}"
        fi
    fi
    
    if $COMPOSE_CMD -f "$COMPOSE_FILE" pull; then
        echo -e "${GREEN}✓ Images pulled successfully${NC}\n"
    else
        echo -e "${RED}✗ Failed to pull images${NC}"
        echo -e "${YELLOW}Possible causes:${NC}"
        echo "  - Authentication required: run 'docker login'"
        echo "  - Network issues: check connectivity"
        echo "  - Image doesn't exist: verify image name and tag"
        exit 1
    fi
else
    echo -e "${YELLOW}Step 6/7: Skipping pull (--skip-pull flag)${NC}\n"
fi

# Paso 7: Desplegar servicios
echo -e "${GREEN}Step 7/7: Deploying services...${NC}"
if $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
    echo -e "${GREEN}✓ Services deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    echo -e "${YELLOW}Showing recent logs:${NC}"
    $COMPOSE_CMD -f "$COMPOSE_FILE" logs --tail=50
    exit 1
fi

# Verificar salud de los servicios
if [ "$SKIP_HEALTH_CHECK" = false ]; then
    echo -e "${GREEN}Verifying services health...${NC}"
    echo -e "${YELLOW}Waiting for services to be healthy (max ${MAX_WAIT}s)...${NC}"
    
    WAITED=0
    ALL_HEALTHY=false
    
    while [ $WAITED -lt $MAX_WAIT ]; do
        # Obtener servicios con healthcheck
        SERVICES=$($COMPOSE_CMD -f "$COMPOSE_FILE" ps --services)
        HEALTHY_COUNT=0
        TOTAL_COUNT=0
        
        for SERVICE in $SERVICES; do
            CONTAINER_NAME=$($COMPOSE_CMD -f "$COMPOSE_FILE" ps -q $SERVICE 2>/dev/null | head -1)
            if [ -n "$CONTAINER_NAME" ]; then
                TOTAL_COUNT=$((TOTAL_COUNT + 1))
                HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "none")
                
                if [ "$HEALTH" = "healthy" ]; then
                    HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
                elif [ "$HEALTH" = "unhealthy" ]; then
                    echo -e "\n${RED}✗ Service $SERVICE is unhealthy${NC}"
                    echo -e "${YELLOW}Showing logs for $SERVICE:${NC}"
                    $COMPOSE_CMD -f "$COMPOSE_FILE" logs --tail=30 $SERVICE
                    exit 1
                fi
            fi
        done
        
        if [ $TOTAL_COUNT -gt 0 ] && [ $HEALTHY_COUNT -eq $TOTAL_COUNT ]; then
            ALL_HEALTHY=true
            break
        fi
        
        echo -n "."
        sleep 2
        WAITED=$((WAITED + 2))
    done
    
    echo ""
    
    if [ "$ALL_HEALTHY" = true ]; then
        echo -e "${GREEN}✓ All services are healthy${NC}\n"
    else
        echo -e "${YELLOW}⚠ Health check timeout or services without healthcheck${NC}"
        echo -e "${YELLOW}Services may still be starting. Check logs if needed.${NC}\n"
    fi
fi

# Mostrar estado final
echo -e "${GREEN}=== Deployment Summary ===${NC}\n"
$COMPOSE_CMD -f "$COMPOSE_FILE" ps

echo ""
echo -e "${GREEN}=== Service Information ===${NC}"
echo -e "${YELLOW}Running containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|phone-services"

echo ""
echo -e "${GREEN}=== Image Information ===${NC}"
$COMPOSE_CMD -f "$COMPOSE_FILE" images

# Mostrar logs si se solicitó
if [ "$SHOW_LOGS" = true ]; then
    echo ""
    echo -e "${GREEN}=== Application Logs ===${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}\n"
    $COMPOSE_CMD -f "$COMPOSE_FILE" logs -f
else
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "  View logs:      $COMPOSE_CMD -f $COMPOSE_FILE logs -f"
    echo "  View status:    $COMPOSE_CMD -f $COMPOSE_FILE ps"
    echo "  Restart app:    $COMPOSE_CMD -f $COMPOSE_FILE restart app"
    echo "  Stop all:       $COMPOSE_CMD -f $COMPOSE_FILE down"
    echo ""
fi

echo -e "${GREEN}=== Deployment Completed ===${NC}\n"