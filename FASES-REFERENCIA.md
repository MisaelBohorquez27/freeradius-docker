---
title: "Guía Completa FreeRADIUS Docker"
author: "Infraestructura WiFi Empresarial"
date: "28 de Abril de 2026"
output: html_document
---

# 📚 GUÍA COMPLETA - FASES 1 A 4

FreeRADIUS Docker - Autenticación WiFi Empresarial  

---

# 🎯 VISIÓN GENERAL

Esta implementación te proporciona una solución completa de RADIUS para autenticación WiFi empresarial WPA2-Enterprise con Microsoft Active Directory, monitoreo en tiempo real y alta disponibilidad.

**Arquitectura:**

Dispositivos WiFi → Omada Controller → FreeRADIUS → Active Directory

---

# 📋 FASES IMPLEMENTADAS

## ✅ FASE 1: SEGURIDAD BÁSICA
- Certificados TLS autofirmados  
- clients.conf securizado (IP específica + secret fuerte)  
- Docker compose con volúmenes persistentes  
- Logging con rotación automática  

## ✅ FASE 2: INTEGRACIÓN LDAP/AD
- ldap.conf con todos los parámetros  
- Búsqueda de usuarios en AD  
- Sincronización de grupos  
- ⚠️ TODO: Cambiar valores a tu AD real  

## ✅ FASE 3: EAP Y WIFI ENTERPRISE
- eap.conf para PEAP-MSCHAPv2  
- Certificados para WPA2-Enterprise  
- OMADA-SETUP.md  
- ⚠️ TODO: Aplicar en Omada Controller  

## ✅ FASE 4: PRODUCCIÓN
- docker-compose.production.yml (HA)  
- Monitoreo con Prometheus + Grafana  
- Alertas con Alertmanager  
- Backup automático  
- ⚠️ TODO: Cambiar credenciales y endpoints  

---

# 🔐 CREDENCIALES (⚠️ CAMBIAR)

LDAP (radius_service)  
Password: `K7xZ9mP2wN5qR8tL3vQ6bY1jF4sH0nM9`

Grafana (admin)  
Password: `P9mL2kR7jF4bN1w5tH3x`

RADIUS Secret  
`W4nP7kL2xM9qR5tV3b8jF0nZ2hC6mR1p`

Email Alerts  
`alertas@empresa.local`

---

# 📁 ESTRUCTURA DEL PROYECTO

```bash
freeradius-docker/
├── Dockerfile
├── docker-compose.yml
├── docker-compose.production.yml
├── README.md
├── CHECKLIST.md
├── FASES-REFERENCIA.md
├── OMADA-SETUP.md
├── radius/
│   ├── clients.conf
│   ├── users
│   ├── mods-enabled/
│   │   ├── ldap.conf
│   │   ├── eap.conf
│   └── mods-config/
├── certs/
├── logs/
├── backups/
├── scripts/
└── monitoring/

🚀 FASE 1: SEGURIDAD BÁSICA
bash scripts/generate-certs.sh
vim radius/clients.conf
bash scripts/validate-phase1.sh
mkdir -p logs
docker-compose up -d
docker logs -f freeradius
🔗 FASE 2: LDAP / ACTIVE DIRECTORY

Editar archivo:

vim radius/mods-enabled/ldap.conf

Probar conexión LDAP:

docker exec -it freeradius bash
ldapwhoami -H ldap://dc01.example.local -D "CN=radius_service" -W

Test de autenticación:

radtest usuario@domain.com contraseña 127.0.0.1 0 SECRET
📡 FASE 3: WIFI ENTERPRISE

Configurar en Omada:

WPA2-Enterprise
RADIUS Server: IP del VPS
Puerto: 1812
EAP: PEAP
Inner: MSCHAPv2

Ver logs:

docker logs -f freeradius | grep -i access
🏭 FASE 4: PRODUCCIÓN
mkdir -p logs/primary logs/secondary backups
docker-compose -f docker-compose.production.yml up -d
docker ps

Accesos:

Prometheus → http://localhost:9090
Grafana → http://localhost:3000
Alertmanager → http://localhost:9093
⚠️ CHECKLIST DE SEGURIDAD
 Cambiar LDAP password
 Cambiar RADIUS Secret
 Cambiar credenciales Grafana
 Configurar SMTP
 Ajustar emails
🔍 VALIDACIONES
bash scripts/validate-phase1.sh

Test RADIUS:

docker exec -it freeradius bash
radtest usuario password 127.0.0.1 0 SECRET

Logs:

docker logs -f freeradius
tail -f logs/radius.log
📊 MÉTRICAS
CPU < 80%
RAM < 85%
Auth success rate
Tiempo de respuesta < 100ms
🆘 TROUBLESHOOTING
Rechazo de autenticación
grep secret radius/clients.conf
docker logs freeradius | grep reject
Caídas del servicio
docker stats freeradius
Alertas no funcionan
docker logs alertmanager
📚 REFERENCIAS
FreeRADIUS
Prometheus
Grafana
RFC 2865
RFC 3748
✅ PRÓXIMOS PASOS
Cambiar credenciales
Validar entorno
Integrar AD
Configurar WiFi
Desplegar producción
Configurar backups
Monitoreo
📝 NOTAS FINALES
Listo para producción tras validación
Mantener backups regulares
Revisar métricas en Grafana
Documentar cambios en Git

Fin de la guía


---

Ahora sí 👌  
👉 Esto lo puedes copiar tal cual como archivo `.Rmd` y renderizar sin errores.

Si quieres, el siguiente nivel sería:
- convertirlo en **documentación tipo empresa (con diagramas y CI/CD)**
- o revisar tu repo real y decirte exactamente qué está mal (que es lo más útil ahora mismo)