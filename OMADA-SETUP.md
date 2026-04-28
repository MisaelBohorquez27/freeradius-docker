# Configuración Omada Controller
## Fase 3: Configuración del Controlador Omada para RADIUS

⚠️ IMPORTANTE: Esta es una GUÍA
Aplicar estos parámetros en la UI de Omada

=============================================================
PASO 1: CONFIGURAR SERVIDOR RADIUS
=============================================================

Ubicación en Omada: Settings → Authentication → RADIUS

Parámetro                  | Valor              | Nota
-------------------------------|-------|-------|-------
RADIUS Server              | [IP_FREERADIUS]    | ⚠️ CAMBIAR
RADIUS Port (Auth)         | 1812               | UDP
RADIUS Port (Accounting)   | 1813               | UDP
Shared Secret              | W4nP7kL2xM9qR5tV3b | ⚠️ DEBE COINCIDIR
Timeout                    | 3                  | segundos
Retries                    | 3                  | intentos

Parámetro aleatorio generado: 2026-04-28
TODO: Cambiar al secret real configurado en clients.conf

```yaml
radius_server:
  ip_address: "[REEMPLAZAR_CON_IP_FREERADIUS]"
  auth_port: 1812
  acct_port: 1813
  shared_secret: "W4nP7kL2xM9qR5tV3b8jF0nZ2hC6mR1p"
  timeout: 3
  retries: 3
```

=============================================================
PASO 2: CREAR POLÍTICA DE AUTENTICACIÓN
=============================================================

Ubicación: Settings → Authentication → Authentication Policy

1. Crear nueva política WiFi Enterprise
2. Nombre: "Enterprise_AD_Auth"
3. Tipo: RADIUS
4. Servidor: Seleccionar servidor RADIUS configurado arriba
5. Método: EAP (PEAP-MSCHAPv2)
6. Validar nombre del servidor: Sí
7. Permitir cambio de contraseña: Sí

```yaml
authentication_policy:
  name: "Enterprise_AD_Auth"
  type: "RADIUS"
  radius_server: "[NOMBRE_DEL_SERVIDOR]"
  eap_method: "PEAP"
  inner_eap: "MSCHAPv2"
  server_name_validation: true
  allow_pwd_change: true
```

=============================================================
PASO 3: CREAR RED WiFi CON WPA2-ENTERPRISE
=============================================================

Ubicación: Wireless → SSIDs

Crear SSID:
- SSID Name: "Enterprise_Network" (o tu nombre)
- Seguridad: WPA2-Enterprise
- Autenticación: Seleccionar política "Enterprise_AD_Auth"
- Cifrado: CCMP (AES)
- VLAN: [opcional, según tu red]

```yaml
wifi_network:
  ssid: "Enterprise_Network"
  security: "WPA2-Enterprise"
  authentication_policy: "Enterprise_AD_Auth"
  cipher: "CCMP"
  # vlan_id: 10  # Opcional
  broadcast_ssid: true
  max_clients: 0  # Sin límite
```

=============================================================
PASO 4: CONFIGURACIÓN DEL CLIENTE WiFi (Usuario Final)
=============================================================

Los clientes deben tener:

**Windows 10/11:**
  - Seguridad WiFi: WPA2-Personal/Enterprise
  - Tipo de autenticación: Microsoft: EAP (PEAP)
  - EAP-PEAP: Validar certificado del servidor: DESACTIVADO
             (para certificados autofirmados)
  - Inner EAP: MSCHAPv2
  - Usuario: usuario@domain.com
  - Contraseña: contraseña de AD

**macOS:**
  - WiFi → Avanzado
  - Seguridad: WPA2 Enterprise
  - User: usuario@domain
  - Password: contraseña de AD
  - Certificado: Confiar en CA autofirmada (si aplica)

**Linux:**
  - wpa_supplicant.conf:
    ```
    network={
        ssid="Enterprise_Network"
        key_mgmt=WPA-EAP
        eap=PEAP
        identity="usuario@domain"
        password="contraseña"
        phase1="peaplabel=0"
        phase2="auth=MSCHAPV2"
    }
    ```

**Android/iOS:**
  - Seguir configuración del usuario (empresa proporcionará instrucciones)
  - Confiar en certificado de CA si es autofirmado

=============================================================
PASO 5: VALIDACIÓN Y TESTING
=============================================================

1. Conectar dispositivo de prueba a SSID "Enterprise_Network"
2. Ingresar usuario AD: usuario@domain.com
3. Ingresar contraseña: contraseña de AD
4. Verificar en FreeRADIUS logs: docker logs -f freeradius
5. Buscar: "Access-Accept" para autenticación exitosa
6. Buscar: "Access-Reject" para fallos (verificar credenciales)

=============================================================
TROUBLESHOOTING OMADA
=============================================================

**Problema: "RADIUS Authentication Failed"**

Soluciones:
  1. Verificar IP del servidor FreeRADIUS es accesible
  2. Verificar puerto 1812 UDP está abierto (firewall)
  3. Verificar shared_secret coincide exactamente
  4. Verificar usuario existe en AD y está habilitado
  5. Ver logs: docker logs freeradius | grep -i radius

**Problema: "Certificate Validation Failed"**

Soluciones:
  1. Desactivar validación de certificado (testing)
  2. O confiar en CA autofirmada en cliente
  3. O usar certificado de CA confiable en producción

**Problema: "Timeout"**

Soluciones:
  1. Aumentar timeout en Omada a 5-10 segundos
  2. Verificar latencia red → FreeRADIUS
  3. Verificar carga de FreeRADIUS: docker stats freeradius
