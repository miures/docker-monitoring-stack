#!/bin/bash

# Script de despliegue para el stack de monitoreo de Docker
# Servidor: 192.168.1.13

set -e

SERVER="192.168.1.13"
REMOTE_USER="root"  # Cambiar según tu usuario
REMOTE_PATH="/opt/docker-monitoring"

echo "========================================"
echo "  Despliegue de Stack de Monitoreo"
echo "  Servidor: $SERVER"
echo "========================================"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar conexión SSH
echo -e "\n${YELLOW}[1/5]${NC} Verificando conexión SSH..."
if ssh -o ConnectTimeout=5 ${REMOTE_USER}@${SERVER} "echo 'Conexión exitosa'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Conexión SSH exitosa"
else
    echo -e "${RED}✗${NC} No se puede conectar a ${SERVER}"
    echo "Por favor verifica:"
    echo "  - El servidor está encendido"
    echo "  - La IP es correcta"
    echo "  - Tienes acceso SSH configurado"
    exit 1
fi

# Crear directorio remoto
echo -e "\n${YELLOW}[2/5]${NC} Creando directorio en servidor..."
ssh ${REMOTE_USER}@${SERVER} "mkdir -p ${REMOTE_PATH}"
echo -e "${GREEN}✓${NC} Directorio creado: ${REMOTE_PATH}"

# Copiar archivos al servidor
echo -e "\n${YELLOW}[3/5]${NC} Copiando archivos al servidor..."
rsync -avz --progress \
    --exclude '.git' \
    --exclude '*.log' \
    ./ ${REMOTE_USER}@${SERVER}:${REMOTE_PATH}/
echo -e "${GREEN}✓${NC} Archivos copiados"

# Desplegar stack
echo -e "\n${YELLOW}[4/5]${NC} Desplegando stack de monitoreo..."
ssh ${REMOTE_USER}@${SERVER} "cd ${REMOTE_PATH} && docker-compose down && docker-compose up -d"
echo -e "${GREEN}✓${NC} Stack desplegado"

# Verificar estado
echo -e "\n${YELLOW}[5/5]${NC} Verificando estado de contenedores..."
ssh ${REMOTE_USER}@${SERVER} "cd ${REMOTE_PATH} && docker-compose ps"

# Información final
echo -e "\n${GREEN}========================================"
echo "  Despliegue completado exitosamente"
echo "========================================${NC}"
echo ""
echo "Acceso a los servicios:"
echo "  • Grafana:     http://${SERVER}:3000"
echo "  • Prometheus:  http://${SERVER}:9090"
echo "  • cAdvisor:    http://${SERVER}:8080"
echo "  • Node Export: http://${SERVER}:9100"
echo ""
echo "Credenciales de Grafana:"
echo "  Usuario: admin"
echo "  Password: admin123"
echo ""
echo -e "${YELLOW}¡Recuerda cambiar la contraseña de admin!${NC}"
echo ""
