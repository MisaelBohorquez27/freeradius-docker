#!/bin/bash
# =============================================================
# SCRIPT DE MONITOREO DE FREERADIUS
# Fase 4: Producción
# =============================================================
# Monitorea salud de FreeRADIUS y genera alertas
# =============================================================

set -e

# =============================================================
# CONFIGURACIÓN
# =============================================================

CONTAINER_NAME="${1:-freeradius-primary}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.local}"
LOG_FILE="./logs/monitoring.log"

# Umbrales de alerta
CPU_THRESHOLD=80        # %
MEMORY_THRESHOLD=85     # %
DISK_THRESHOLD=90       # %
AUTH_FAILURE_RATE=50    # % de rechazos permitidos

# Colores
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# =============================================================
# FUNCIONES
# =============================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

alert() {
    local severity=$1
    local message=$2
    
    log "${severity}: ${message}"
    
    # Enviar alerta (descomentar cuando se configure notificación)
    # send_alert "${severity}" "${message}"
}

# =============================================================
# VERIFICACIONES DE SALUD
# =============================================================

check_container_running() {
    log "Verificando si contenedor está activo..."
    
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log "✓ Contenedor ${CONTAINER_NAME} está activo"
        return 0
    else
        alert "CRITICAL" "Contenedor ${CONTAINER_NAME} NO está activo"
        return 1
    fi
}

check_port_listening() {
    local port=$1
    
    log "Verificando puerto ${port}..."
    
    if docker exec "${CONTAINER_NAME}" netstat -uln | grep -q ":${port}"; then
        log "✓ Puerto ${port} escuchando"
        return 0
    else
        alert "CRITICAL" "Puerto ${port} NO escuchando"
        return 1
    fi
}

check_resources() {
    log "Verificando recursos..."
    
    local stats=$(docker stats --no-stream "${CONTAINER_NAME}")
    local cpu=$(echo "${stats}" | tail -1 | awk '{print $3}' | tr -d '%')
    local memory=$(echo "${stats}" | tail -1 | awk '{print $6}' | tr -d '%')
    
    if (( $(echo "${cpu} > ${CPU_THRESHOLD}" | bc -l) )); then
        alert "WARNING" "CPU alta: ${cpu}% (umbral: ${CPU_THRESHOLD}%)"
    fi
    
    if (( $(echo "${memory} > ${MEMORY_THRESHOLD}" | bc -l) )); then
        alert "WARNING" "Memoria alta: ${memory}% (umbral: ${MEMORY_THRESHOLD}%)"
    fi
    
    log "CPU: ${cpu}% | Memoria: ${memory}%"
}

check_logs() {
    log "Verificando logs de errores..."
    
    local errors=$(docker logs "${CONTAINER_NAME}" --tail 100 2>/dev/null | grep -i "error\|reject" | wc -l)
    
    if [ "${errors}" -gt 10 ]; then
        alert "WARNING" "${errors} errores detectados en últimos 100 logs"
    else
        log "✓ ${errors} errores en últimos 100 logs"
    fi
}

check_disk_space() {
    log "Verificando espacio en disco..."
    
    local disk_usage=$(df ./logs | tail -1 | awk '{print $5}' | tr -d '%')
    
    if (( disk_usage > DISK_THRESHOLD )); then
        alert "WARNING" "Espacio en disco bajo: ${disk_usage}% (umbral: ${DISK_THRESHOLD}%)"
    else
        log "✓ Espacio en disco: ${disk_usage}%"
    fi
}

check_authentication() {
    log "Verificando tasa de autenticación..."
    
    local auth_accept=$(docker logs "${CONTAINER_NAME}" --tail 1000 2>/dev/null | grep -i "Access-Accept" | wc -l)
    local auth_reject=$(docker logs "${CONTAINER_NAME}" --tail 1000 2>/dev/null | grep -i "Access-Reject" | wc -l)
    local total=$((auth_accept + auth_reject))
    
    if [ "${total}" -gt 0 ]; then
        local reject_rate=$((auth_reject * 100 / total))
        log "Autenticaciones - Aceptadas: ${auth_accept} | Rechazadas: ${auth_reject} (${reject_rate}%)"
        
        if (( reject_rate > AUTH_FAILURE_RATE )); then
            alert "WARNING" "Tasa de rechazo alta: ${reject_rate}% (umbral: ${AUTH_FAILURE_RATE}%)"
        fi
    else
        log "Sin autenticaciones registradas en últimos logs"
    fi
}

# =============================================================
# RESUMEN DE SALUD
# =============================================================

health_summary() {
    echo ""
    echo "═════════════════════════════════════════════════════"
    echo "📊 RESUMEN DE SALUD - $(date +'%Y-%m-%d %H:%M:%S')"
    echo "═════════════════════════════════════════════════════"
    
    check_container_running || echo -e "${RED}✗ Contenedor offline${NC}"
    check_port_listening 1812 || echo -e "${RED}✗ Puerto 1812 no escucha${NC}"
    check_resources
    check_logs
    check_disk_space
    check_authentication
    
    echo "═════════════════════════════════════════════════════"
    echo ""
}

# =============================================================
# MAIN
# =============================================================

log "Iniciando monitoreo de FreeRADIUS..."
log "Contenedor: ${CONTAINER_NAME}"

if [ -z "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    alert "CRITICAL" "Contenedor ${CONTAINER_NAME} no existe"
    exit 1
fi

health_summary

exit 0
