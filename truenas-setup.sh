#!/bin/bash

# Script para configurar monitoreo en TrueNAS
# Ejecutar este script en el servidor TrueNAS

set -e

TRUENAS_IP="${1:-192.168.1.X}"  # Cambiar por la IP de tu TrueNAS
INSTALL_DIR="/mnt/tank/monitoring"  # Ajustar según tu pool de TrueNAS

echo "========================================"
echo "  Configuración de Monitoreo TrueNAS"
echo "  IP: $TRUENAS_IP"
echo "========================================"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Crear directorio
echo -e "\n${YELLOW}[1/3]${NC} Creando directorio de instalación..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
echo -e "${GREEN}✓${NC} Directorio creado: $INSTALL_DIR"

# Descargar docker-compose.yml
echo -e "\n${YELLOW}[2/3]${NC} Creando configuración de Docker Compose..."
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor-truenas
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter-truenas
    restart: unless-stopped
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
EOF

echo -e "${GREEN}✓${NC} Configuración creada"

# Iniciar servicios
echo -e "\n${YELLOW}[3/3]${NC} Iniciando servicios de monitoreo..."
docker-compose up -d
echo -e "${GREEN}✓${NC} Servicios iniciados"

# Verificar estado
echo -e "\n${YELLOW}Estado de los contenedores:${NC}"
docker-compose ps

echo -e "\n${GREEN}========================================"
echo "  Configuración completada"
echo "========================================${NC}"
echo ""
echo "Servicios disponibles en TrueNAS:"
echo "  • cAdvisor:      http://${TRUENAS_IP}:8080"
echo "  • Node Exporter: http://${TRUENAS_IP}:9100/metrics"
echo ""
echo "Ahora actualiza prometheus.yml en el servidor de monitoreo"
echo "para agregar estos targets."
echo ""
