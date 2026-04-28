# =============================================================
# FreeRADIUS Server - Autenticación WiFi Empresarial
# =============================================================
FROM freeradius/freeradius-server:latest

LABEL maintainer="Enterprise WiFi Team"
LABEL description="FreeRADIUS Server for WPA2-Enterprise WiFi with AD Integration"
LABEL version="1.0"

# =============================================================
# ACTUALIZACIONES Y DEPENDENCIAS
# =============================================================
RUN apt-get update && apt-get install -y \
    ldap-utils \
    openldap-clients \
    && rm -rf /var/lib/apt/lists/*

# =============================================================
# COPIAR CONFIGURACIÓN
# =============================================================
# Configuración de FreeRADIUS
COPY radius /etc/freeradius/3.0/

# Asegurar permisos correctos
RUN chown -R freerad:freerad /etc/freeradius/3.0 && \
    chmod 750 /etc/freeradius/3.0 && \
    chmod 640 /etc/freeradius/3.0/*

# =============================================================
# PUERTOS
# =============================================================
# 1812 - RADIUS Authentication (UDP)
# 1813 - RADIUS Accounting (UDP)
EXPOSE 1812/udp 1813/udp

# =============================================================
# HEALTHCHECK
# =============================================================
# Verificar que FreeRADIUS está escuchando en el puerto 1812
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD nc -zu 127.0.0.1 1812 || exit 1

# =============================================================
# INICIO DEL SERVICIO
# =============================================================
# Ejecutar FreeRADIUS en modo debug
# Cambiar a "freeradius" sin -X en producción
CMD ["freeradius", "-X"]