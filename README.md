# FreeRADIUS Docker - Autenticación WiFi Empresarial 802.1X

## 📋 Descripción

Implementación de FreeRADIUS en Docker para autenticación WPA2-Enterprise contra Microsoft Active Directory.

**Arquitectura:**
```
Dispositivos WiFi → Omada Controller → FreeRADIUS → Active Directory
```

## ⚙️ Configuración Actual

### Servidor RADIUS
- **Versión:** FreeRADIUS (latest)
- **Puerto Autenticación:** 1812 UDP
- **Puerto Accounting:** 1813 UDP
- **Protocolo:** UDP (RADIUS)
- **Cliente:** Controlador Omada (IP: 192.168.1.100)
- **Secret:** RadSecure@2026.prod.enterprise.freeradius

## 🚀 Inicio Rápido

### 1. Generar Certificados (PRIMERO)

```bash
# Hacer ejecutable el script
chmod +x generate-certs.sh

# Generar certificados TLS
./generate-certs.sh

# Verificar que se creó la carpeta ./certs
ls -la certs/
```

**Certificados generados:**
- `ca.crt` - Certificado de Autoridad Certificadora
- `ca.key` - Clave privada de CA (MANTENER SEGURO)
- `server.crt` - Certificado del servidor
- `server.key` - Clave privada del servidor

### 2. Levantar el Servicio

```bash
# Crear directorio de logs si no existe
mkdir -p logs

# Levantar contenedor en segundo plano
docker-compose up -d

# Verificar que está corriendo
docker ps | grep freeradius
```

### 3. Ver Logs en Tiempo Real

```bash
docker logs -f freeradius
```

### 4. Detener el Servicio

```bash
docker-compose down
```

## 🔧 Configuración

### clients.conf - Clientes RADIUS Autorizados

**Ubicación:** `./radius/clients.conf`

```
client omada_controller_primary {
    ipaddr = 192.168.1.100              # IP del Omada Controller
    secret = RadSecure@2026.prod...     # Secret compartido
    require_message_authenticator = yes # Requerido para seguridad
}
```

**⚠️ IMPORTANTE:**
- Cambiar `ipaddr` a la IP real de tu Omada Controller
- Usar un `secret` fuerte (32+ caracteres, sin espacios)
- **NUNCA** usar `0.0.0.0/0` en producción
- El secret debe coincidir en Omada y FreeRADIUS

### users - Base de Datos de Usuarios

**Ubicación:** `./radius/users`

Actualmente usa autenticación local (solo para pruebas). En producción, se debe integrar con LDAP/AD.

```
# Ejemplo actual (PRUEBAS SOLAMENTE)
testuser Cleartext-Password := "1234"
```

## 📊 Puertos y Protocolos

| Puerto | Protocolo | Uso | Estado |
|--------|-----------|-----|--------|
| 1812 | UDP | RADIUS Authentication | ✅ Activo |
| 1813 | UDP | RADIUS Accounting | ✅ Activo |

## 🔐 Seguridad (Fase 1 - COMPLETADA)

✅ **Implementado:**
- [x] Secret fuerte en clients.conf
- [x] IP específica del Omada Controller (no 0.0.0.0/0)
- [x] Certificados TLS autofirmados generados
- [x] Volúmenes persistentes para logs
- [x] Política de reinicio: `always`
- [x] Logging con rotación automática
- [x] Red personalizada con subnet definida

⏳ **Por implementar (Fases 2-4):**
- [ ] Integración LDAP con Active Directory
- [ ] Certificados firmados por CA confiable
- [ ] EAP-PEAP configuration
- [ ] Monitoreo y alertas
- [ ] Backup automático
- [ ] Alta disponibilidad (múltiples nodos)

## 🧪 Pruebas

### Test Básico con radtest

```bash
# Ingresar al contenedor
docker exec -it freeradius bash

# Probar autenticación (usuario de prueba)
radtest testuser 1234 127.0.0.1 0 testing123

# Respuesta esperada: "Access-Accept"
```

### Logs de Autenticación

```bash
# Ver últimos 100 líneas de logs
docker logs freeradius | tail -100

# Ver logs persistentes
tail -f logs/radius.log
```

## 📁 Estructura del Proyecto

```
.
├── Dockerfile                 # Imagen Docker de FreeRADIUS
├── docker-compose.yml         # Orquestación de contenedores
├── generate-certs.sh          # Script para generar certificados
├── README.md                  # Esta documentación
├── certs/                     # Certificados TLS (generado por script)
│   ├── ca.crt
│   ├── ca.key
│   ├── server.crt
│   └── server.key
├── logs/                      # Logs persistentes
│   └── radius.log
└── radius/                    # Configuración de FreeRADIUS
    ├── clients.conf           # Clientes RADIUS autorizados
    ├── users                  # Base de datos local de usuarios
    └── mods-config/           # Configuración de módulos (ej: LDAP)
```

## 🐛 Troubleshooting

### El contenedor no inicia

```bash
# Ver logs detallados
docker logs freeradius

# Verificar que archivos de config existen
ls -la radius/
```

### "Address already in use" en puerto 1812

```bash
# Ver qué proceso usa el puerto
lsof -i :1812

# Cambiar puerto en docker-compose
ports:
  - "1814:1812/udp"  # Mapear a 1814 en el host
```

### Autenticación rechazada

```bash
# Verificar que el cliente está en clients.conf
grep "omada" radius/clients.conf

# Verificar que el secret coincide
# (debe ser el mismo en Omada y FreeRADIUS)

# Ver logs:
docker logs freeradius | grep -i "reject\|accept"
```

## 📚 Próximos Pasos

1. **Fase 2:** Integración LDAP con Active Directory
   - Configurar módulo LDAP
   - Sincronización de usuarios/grupos
   - Testing con credenciales AD

2. **Fase 3:** EAP y WiFi Enterprise
   - Configurar EAP-PEAP
   - Generar certificados para WiFi
   - Configurar Omada para usar RADIUS

3. **Fase 4:** Producción
   - Monitoreo y alertas
   - Backup automático
   - Alta disponibilidad

## 🔗 Referencias

- [FreeRADIUS Official](https://freeradius.org/)
- [Docker Hub - FreeRADIUS](https://hub.docker.com/r/freeradius/freeradius-server)
- [RFC 2865 - RADIUS Protocol](https://tools.ietf.org/html/rfc2865)
- [802.1X - Network Access Control](https://en.wikipedia.org/wiki/IEEE_802.1X)