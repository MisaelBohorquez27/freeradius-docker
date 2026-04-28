#!/bin/bash
# Script para generar certificados TLS para FreeRADIUS
# Uso: bash generate-certs.sh

set -e

CERT_DIR="./certs"
DAYS_VALID=3650

echo "📋 Creando directorio de certificados..."
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "🔐 Generando clave privada de CA..."
openssl genrsa -out ca.key 2048

echo "📜 Generando certificado de CA..."
openssl req -new -x509 \
  -days $DAYS_VALID \
  -key ca.key \
  -out ca.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=Enterprise/OU=IT/CN=FreeRADIUS-CA"

echo "🔐 Generando clave privada del servidor..."
openssl genrsa -out server.key 2048

echo "📝 Generando solicitud de firma de certificado (CSR)..."
openssl req -new \
  -key server.key \
  -out server.csr \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=Enterprise/OU=IT/CN=freeradius.local"

echo "✅ Firmando certificado del servidor..."
openssl x509 -req \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -days $DAYS_VALID \
  -sha256

echo "🧹 Limpiando archivos temporales..."
rm -f server.csr ca.srl

echo "🔒 Ajustando permisos..."
chmod 600 ca.key server.key
chmod 644 ca.crt server.crt

echo ""
echo "✨ ¡Certificados generados exitosamente!"
echo ""
echo "📂 Certificados creados en: $CERT_DIR/"
ls -la

echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Estos certificados son autofirmados (válidos 10 años)"
echo "   - Para producción, considera obtener certificados de una CA confiable"
echo "   - Mantén ca.key en lugar seguro y nunca lo compartas"
echo ""
