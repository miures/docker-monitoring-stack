# Stack de Monitoreo Docker con Grafana

Stack completo de monitoreo para contenedores Docker utilizando Grafana, Prometheus, cAdvisor y Node Exporter.

## 🎯 Componentes

- **Grafana** (Puerto 3000): Dashboard y visualización de métricas
- **Prometheus** (Puerto 9090): Recolección y almacenamiento de métricas
- **cAdvisor** (Puerto 8080): Métricas de contenedores Docker
- **Node Exporter** (Puerto 9100): Métricas del sistema host

## 📋 Requisitos

- Docker y Docker Compose instalados en el servidor 192.168.1.13
- Acceso SSH al servidor
- Puertos 3000, 9090, 8080, 9100 disponibles

## 🚀 Instalación

### Opción 1: Despliegue Remoto (desde tu máquina local)

1. **Configurar acceso SSH** (si es necesario):
   ```bash
   ssh-copy-id root@192.168.1.13
   ```

2. **Editar el script de despliegue** si es necesario:
   ```bash
   nano deploy.sh
   # Ajustar SERVER, REMOTE_USER y REMOTE_PATH según tu configuración
   ```

3. **Ejecutar el despliegue**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

### Opción 2: Instalación Manual en el Servidor

1. **Copiar archivos al servidor**:
   ```bash
   scp -r docker-monitoring-stack root@192.168.1.13:/opt/
   ```

2. **Conectar al servidor**:
   ```bash
   ssh root@192.168.1.13
   cd /opt/docker-monitoring-stack
   ```

3. **Iniciar el stack**:
   ```bash
   docker-compose up -d
   ```

4. **Verificar estado**:
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

## 🔐 Acceso

Una vez desplegado, puedes acceder a:

- **Grafana**: http://192.168.1.13:3000
  - Usuario: `admin`
  - Password: `admin123` (¡Cámbialo después del primer acceso!)

- **Prometheus**: http://192.168.1.13:9090
- **cAdvisor**: http://192.168.1.13:8080
- **Node Exporter**: http://192.168.1.13:9100/metrics

## 📊 Configurar Dashboards en Grafana

### Dashboards Recomendados

1. **Docker Container & Host Metrics** (ID: 893)
2. **Docker Monitoring** (ID: 179)
3. **Node Exporter Full** (ID: 1860)
4. **cAdvisor exporter** (ID: 14282)

### Importar Dashboard

1. Accede a Grafana: http://192.168.1.13:3000
2. Ve a **Dashboards** → **Import**
3. Ingresa el ID del dashboard (ej: 893)
4. Selecciona **Prometheus** como datasource
5. Haz clic en **Import**

## 🛠️ Comandos Útiles

### Gestión del Stack

```bash
# Ver logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f grafana

# Reiniciar servicios
docker-compose restart

# Detener stack
docker-compose down

# Detener y eliminar volúmenes
docker-compose down -v

# Ver métricas en tiempo real
docker stats
```

### Verificar Métricas

```bash
# Probar endpoint de Prometheus
curl http://192.168.1.13:9090/api/v1/targets

# Probar métricas de cAdvisor
curl http://192.168.1.13:8080/metrics

# Probar métricas de Node Exporter
curl http://192.168.1.13:9100/metrics
```

## 🔧 Configuración Adicional

### Habilitar Métricas del Docker Daemon

Para obtener métricas directamente del daemon de Docker:

1. Editar `/etc/docker/daemon.json`:
   ```json
   {
     "metrics-addr": "0.0.0.0:9323",
     "experimental": true
   }
   ```

2. Reiniciar Docker:
   ```bash
   systemctl restart docker
   ```

3. Descomentar la sección en `prometheus/prometheus.yml`

### Personalizar Retención de Datos

Editar `docker-compose.yml`, sección de prometheus:
```yaml
command:
  - '--storage.tsdb.retention.time=30d'  # Cambiar de 15d a 30d
```

### Configurar Alertas

1. Crear archivo de reglas en `prometheus/alerts/rules.yml`
2. Descomentar la sección `rule_files` en `prometheus/prometheus.yml`
3. Reiniciar Prometheus: `docker-compose restart prometheus`

## 🔒 Seguridad

### Recomendaciones:

1. **Cambiar la contraseña de Grafana** inmediatamente después del primer acceso
2. **Configurar firewall** para restringir acceso a los puertos:
   ```bash
   ufw allow from 192.168.1.0/24 to any port 3000
   ufw allow from 192.168.1.0/24 to any port 9090
   ```
3. **Usar HTTPS** con un reverse proxy (Nginx/Traefik)
4. **Configurar autenticación** adicional si es necesario

## 📈 Métricas Disponibles

### Docker/cAdvisor
- Uso de CPU por contenedor
- Uso de memoria por contenedor
- I/O de red por contenedor
- I/O de disco por contenedor
- Número de contenedores en ejecución

### Sistema (Node Exporter)
- CPU (uso, load average)
- Memoria (RAM, swap)
- Disco (espacio, I/O)
- Red (tráfico, errores)
- Procesos del sistema

## 🐛 Troubleshooting

### cAdvisor no muestra métricas
```bash
# Verificar que Docker esté corriendo
systemctl status docker

# Verificar permisos de cAdvisor
docker-compose logs cadvisor
```

### Prometheus no puede conectar a targets
```bash
# Verificar conectividad de red
docker-compose exec prometheus ping cadvisor
docker-compose exec prometheus ping node-exporter
```

### Grafana no muestra datos
1. Verificar que Prometheus esté configurado como datasource
2. Ir a Configuration → Data Sources
3. Hacer clic en "Test" para verificar conexión

## 📝 Notas

- Los datos de Prometheus se retienen por 15 días por defecto
- Los volúmenes persisten los datos incluso si se detienen los contenedores
- El stack consume aproximadamente 500MB-1GB de RAM en total

## 🤝 Soporte

Para más información sobre los componentes:
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [cAdvisor GitHub](https://github.com/google/cadvisor)
- [Node Exporter GitHub](https://github.com/prometheus/node_exporter)
