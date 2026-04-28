#!/bin/bash
# =============================================================
# SCRIPT DE BACKUP AUTOMÁTICO
# Fase 4: Producción
# =============================================================
# Este script realiza backup de la configuración de FreeRADIUS
# Cron: 0 2 * * * (diariamente a las 2 AM)
# =============================================================

set -e

# =============================================================
# CONFIGURACIÓN
# =============================================================

# Directorio de backups
BACKUP_DIR="${1:-.}/backups"

# Directorio de configuración
CONFIG_DIR="${2:-.}/radius"

# Directorio de certificados
CERT_DIR="${3:-.}/certs"

# Días para retener backups
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Tipo de compresión
COMPRESSION="${BACKUP_COMPRESSION:-gzip}"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Archivo de backup
BACKUP_FILE="${BACKUP_DIR}/freeradius_backup_${TIMESTAMP}.tar.${COMPRESSION##*=}"

# Archivo de log
LOG_FILE="${BACKUP_DIR}/backup.log"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =============================================================
# FUNCIONES
# =============================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"
}

# =============================================================
# PRE-VALIDACIÓN
# =============================================================

log "Iniciando backup de FreeRADIUS..."

if [ ! -d "${CONFIG_DIR}" ]; then
    log_error "Directorio de configuración no encontrado: ${CONFIG_DIR}"
    exit 1
fi

if [ ! -d "${BACKUP_DIR}" ]; then
    log "Creando directorio de backup: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
fi

# =============================================================
# CREAR BACKUP
# =============================================================

log "Comprimiendo configuración..."

case "${COMPRESSION}" in
    gzip|gz)
        tar czf "${BACKUP_FILE}" \
            -C "${CONFIG_DIR}" . \
            -C "${CERT_DIR}" . \
            2>>"${LOG_FILE}" || {
            log_error "Error al comprimir backup"
            exit 1
        }
        ;;
    bzip2|bz2)
        tar cjf "${BACKUP_FILE}" \
            -C "${CONFIG_DIR}" . \
            -C "${CERT_DIR}" . \
            2>>"${LOG_FILE}" || {
            log_error "Error al comprimir backup"
            exit 1
        }
        ;;
    xz)
        tar cJf "${BACKUP_FILE}" \
            -C "${CONFIG_DIR}" . \
            -C "${CERT_DIR}" . \
            2>>"${LOG_FILE}" || {
            log_error "Error al comprimir backup"
            exit 1
        }
        ;;
    *)
        log_error "Tipo de compresión no soportado: ${COMPRESSION}"
        exit 1
        ;;
esac

log_success "Backup creado: ${BACKUP_FILE}"

# Información del backup
BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
log "Tamaño del backup: ${BACKUP_SIZE}"

# =============================================================
# VERIFICAR INTEGRIDAD
# =============================================================

log "Verificando integridad del archivo..."

if tar -tzf "${BACKUP_FILE}" > /dev/null 2>&1; then
    log_success "Integridad del archivo verificada ✓"
else
    log_error "¡Error de integridad! El backup puede estar corrupto"
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# =============================================================
# LIMPIAR BACKUPS ANTIGUOS
# =============================================================

log "Limpiando backups más antiguos de ${RETENTION_DAYS} días..."

OLD_BACKUPS=$(find "${BACKUP_DIR}" -name "freeradius_backup_*.tar.*" -type f -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)

if [ "${OLD_BACKUPS}" -gt 0 ]; then
    find "${BACKUP_DIR}" -name "freeradius_backup_*.tar.*" -type f -mtime +${RETENTION_DAYS} -delete
    log_warning "Se eliminaron ${OLD_BACKUPS} backup(s) antiguo(s)"
else
    log "No hay backups antiguos para eliminar"
fi

# =============================================================
# LISTA DE BACKUPS ACTUALES
# =============================================================

log "Backups disponibles:"
ls -lh "${BACKUP_DIR}"/freeradius_backup_*.tar.* 2>/dev/null | awk '{print $9, "(" $5 ")"}' | tee -a "${LOG_FILE}" || true

# =============================================================
# RESUMEN
# =============================================================

echo "" | tee -a "${LOG_FILE}"
log_success "Backup completado exitosamente"
echo "" | tee -a "${LOG_FILE}"

log "Resumen:"
log "  - Archivo: ${BACKUP_FILE}"
log "  - Tamaño: ${BACKUP_SIZE}"
log "  - Retención: ${RETENTION_DAYS} días"
log "  - Próximo backup: $(date -d '+1 day' +'%Y-%m-%d 02:00:00')"

exit 0
