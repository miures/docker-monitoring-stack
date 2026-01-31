# Configuración de Monitoreo para TrueNAS

Esta guía te ayudará a agregar monitoreo de Docker en TrueNAS a tu stack de Grafana.

## 📋 Requisitos

- TrueNAS con Docker instalado
- Acceso SSH a TrueNAS
- Puertos 8080 y 9100 disponibles en TrueNAS

## 🚀 Instalación en TrueNAS

### Opción 1: Script Automático

1. **Copiar el script a TrueNAS:**
   ```bash
   scp truenas-setup.sh root@TU_TRUENAS_IP:/tmp/
   ```

2. **Conectar a TrueNAS y ejecutar:**
   ```bash
   ssh root@TU_TRUENAS_IP
   chmod +x /tmp/truenas-setup.sh
   /tmp/truenas-setup.sh 192.168.1.XX  # Reemplazar con la IP de TrueNAS
   ```

### Opción 2: Manual

1. **Conectar a TrueNAS:**
   ```bash
   ssh root@TU_TRUENAS_IP
   ```

2. **Crear directorio:**
   ```bash
   mkdir -p /mnt/tank/monitoring  # Ajustar según tu pool
   cd /mnt/tank/monitoring
   ```

3. **Copiar docker-compose.yml:**
   ```bash
   # Copiar el contenido de truenas-docker-compose.yml
   nano docker-compose.yml
   ```

4. **Iniciar servicios:**
   ```bash
   docker-compose up -d
   ```

5. **Verificar:**
   ```bash
   docker-compose ps
   curl http://localhost:8080/metrics
   curl http://localhost:9100/metrics
   ```

## ⚙️ Configurar Prometheus

Una vez que los exporters estén corriendo en TrueNAS:

1. **Editar `prometheus/prometheus.yml`** en el servidor de monitoreo:

   ```yaml
   # TrueNAS - Métricas de contenedores Docker
   - job_name: 'truenas-cadvisor'
     scrape_interval: 10s
     static_configs:
       - targets: ['192.168.1.XX:8080']  # IP de TrueNAS
         labels:
           instance: 'truenas'
           group: 'docker'

   # TrueNAS - Métricas del sistema
   - job_name: 'truenas-node-exporter'
     scrape_interval: 10s
     static_configs:
       - targets: ['192.168.1.XX:9100']  # IP de TrueNAS
         labels:
           instance: 'truenas'
           group: 'system'
   ```

2. **Aplicar cambios:**
   ```bash
   cd ~/docker-monitoring-stack
   ./deploy.sh
   ```

   O manualmente en el servidor de monitoreo:
   ```bash
   ssh asanchez@192.168.1.13
   cd /home/asanchez/docker-monitoring
   sudo docker compose restart prometheus
   ```

## ✅ Verificación

1. **Verificar targets en Prometheus:**
   - Accede a: http://192.168.1.13:9090/targets
   - Deberías ver los nuevos targets de TrueNAS con estado "UP"

2. **Verificar métricas en Grafana:**
   - Accede a: http://192.168.1.13:3000
   - Los dashboards existentes deberían mostrar ahora datos de TrueNAS
   - Usa el filtro por `instance="truenas"` en las queries

## 📊 Dashboards Recomendados

Los siguientes dashboards funcionarán automáticamente con TrueNAS:

- **Docker Container Monitoring** (ID: 893) - Métricas de contenedores
- **Node Exporter Full** (ID: 1860) - Métricas del sistema TrueNAS
- **cAdvisor exporter** (ID: 14282) - Métricas detalladas de Docker

## 🔍 Queries de Ejemplo

### Ver contenedores en TrueNAS:
```promql
container_last_seen{instance="truenas"}
```

### CPU de contenedores en TrueNAS:
```promql
rate(container_cpu_usage_seconds_total{instance="truenas"}[5m])
```

### Memoria de contenedores en TrueNAS:
```promql
container_memory_usage_bytes{instance="truenas"}
```

### Uso de disco en TrueNAS:
```promql
node_filesystem_avail_bytes{instance="truenas"}
```

## 🛠️ Múltiples Servidores TrueNAS

Si tienes varios TrueNAS, repite el proceso y agrega más targets en `prometheus.yml`:

```yaml
- job_name: 'truenas-cadvisor'
  scrape_interval: 10s
  static_configs:
    - targets: 
        - '192.168.1.10:8080'
        - '192.168.1.11:8080'
        - '192.168.1.12:8080'
      labels:
        group: 'docker'
    # O con labels individuales
    - targets: ['192.168.1.10:8080']
      labels:
        instance: 'truenas-01'
        location: 'datacenter'
    - targets: ['192.168.1.11:8080']
      labels:
        instance: 'truenas-02'
        location: 'oficina'
```

## 🔒 Seguridad

### Restricción por Firewall en TrueNAS

```bash
# Solo permitir acceso desde el servidor de monitoreo
iptables -A INPUT -p tcp -s 192.168.1.13 --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp -s 192.168.1.13 --dport 9100 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j DROP
iptables -A INPUT -p tcp --dport 9100 -j DROP
```

### Autenticación Básica (Opcional)

Si quieres agregar autenticación, puedes usar Nginx como reverse proxy en TrueNAS.

## 🐛 Troubleshooting

### Los targets aparecen como "DOWN"

1. **Verificar que los contenedores estén corriendo en TrueNAS:**
   ```bash
   ssh root@TU_TRUENAS_IP
   docker ps | grep -E "cadvisor|node-exporter"
   ```

2. **Verificar conectividad desde el servidor de monitoreo:**
   ```bash
   ssh asanchez@192.168.1.13
   curl http://TU_TRUENAS_IP:8080/metrics
   curl http://TU_TRUENAS_IP:9100/metrics
   ```

3. **Verificar firewall:**
   ```bash
   # En TrueNAS
   netstat -tlnp | grep -E "8080|9100"
   ```

### cAdvisor no muestra todos los contenedores

Asegúrate de que cAdvisor tenga acceso al socket de Docker:
```bash
ls -la /var/run/docker.sock
# Debe ser accesible para el usuario que corre Docker
```

## 📝 Notas para TrueNAS SCALE

TrueNAS SCALE usa Kubernetes (k3s) en lugar de Docker. Para monitorear aplicaciones en SCALE:

1. Usa los exporters de Kubernetes nativos
2. O ejecuta los exporters como aplicaciones de TrueNAS SCALE
3. Considera usar el operador de Prometheus para Kubernetes

## 🔄 Actualización

Para actualizar los exporters en TrueNAS:

```bash
ssh root@TU_TRUENAS_IP
cd /mnt/tank/monitoring
docker-compose pull
docker-compose up -d
```

## 📚 Recursos Adicionales

- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Node Exporter Documentation](https://github.com/prometheus/node_exporter)
- [TrueNAS Documentation](https://www.truenas.com/docs/)
