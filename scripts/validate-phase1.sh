#!/bin/bash
# Script de Validación - Fase 1
# Verifica que la implementación de seguridad básica sea correcta

set -e

echo "========================================"
echo "🔍 VALIDACIÓN FASE 1 - SEGURIDAD BÁSICA"
echo "========================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Función para imprimir checks
check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

check_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

echo "📁 VERIFICANDO ESTRUCTURA DE ARCHIVOS..."
echo ""

# Verificar archivos principales
if [ -f "Dockerfile" ]; then
    check_pass "Dockerfile existe"
else
    check_fail "Dockerfile NO EXISTE"
fi

if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml existe"
else
    check_fail "docker-compose.yml NO EXISTE"
fi

if [ -f "scripts/generate-certs.sh" ]; then
    check_pass "scripts/generate-certs.sh existe"
else
    check_fail "scripts/generate-certs.sh NO EXISTE"
fi

if [ -f "README.md" ]; then
    check_pass "README.md existe"
else
    check_fail "README.md NO EXISTE"
fi

if [ -f "radius/clients.conf" ]; then
    check_pass "radius/clients.conf existe"
else
    check_fail "radius/clients.conf NO EXISTE"
fi

if [ -f "radius/users" ]; then
    check_pass "radius/users existe"
else
    check_fail "radius/users NO EXISTE"
fi

echo ""
echo "🔐 VERIFICANDO CONFIGURACIÓN DE SEGURIDAD..."
echo ""

# Verificar clients.conf
if grep -q "0.0.0.0/0" radius/clients.conf 2>/dev/null; then
    check_fail "clients.conf: AÚN CONTIENE 0.0.0.0/0 (RIESGO CRÍTICO)"
else
    check_pass "clients.conf: No contiene 0.0.0.0/0 ✓"
fi

if grep -q "testing123" radius/clients.conf 2>/dev/null; then
    check_fail "clients.conf: AÚN CONTIENE secret débil 'testing123'"
else
    check_pass "clients.conf: No contiene 'testing123' ✓"
fi

if grep -q "require_message_authenticator" radius/clients.conf 2>/dev/null; then
    check_pass "clients.conf: Contiene 'require_message_authenticator' ✓"
else
    check_warning "clients.conf: No contiene 'require_message_authenticator'"
fi

echo ""
echo "📦 VERIFICANDO CONFIGURACIÓN DOCKER..."
echo ""

# Verificar docker-compose
if grep -q "./radius.*:ro" docker-compose.yml 2>/dev/null; then
    check_pass "docker-compose: Volumen radius montado (read-only) ✓"
else
    check_warning "docker-compose: Volumen radius podría no estar en modo read-only"
fi

if grep -q "./logs" docker-compose.yml 2>/dev/null; then
    check_pass "docker-compose: Volumen logs configurado ✓"
else
    check_warning "docker-compose: No hay volumen para logs"
fi

if grep -q "./certs" docker-compose.yml 2>/dev/null; then
    check_pass "docker-compose: Volumen certs configurado ✓"
else
    check_warning "docker-compose: No hay volumen para certs"
fi

if grep -q "restart: always" docker-compose.yml 2>/dev/null; then
    check_pass "docker-compose: restart policy = 'always' ✓"
else
    check_warning "docker-compose: restart policy podría no ser 'always'"
fi

if grep -q "freeradius-network" docker-compose.yml 2>/dev/null; then
    check_pass "docker-compose: Red personalizada definida ✓"
else
    check_warning "docker-compose: No tiene red personalizada"
fi

echo ""
echo "🔑 VERIFICANDO CERTIFICADOS..."
echo ""

if [ -d "certs" ]; then
    check_pass "Carpeta certs/ existe"
    
    if [ -f "certs/ca.crt" ] && [ -f "certs/ca.key" ]; then
        check_pass "Certificados de CA generados ✓"
    else
        check_warning "Certificados de CA NO encontrados (ejecutar generate-certs.sh)"
    fi
    
    if [ -f "certs/server.crt" ] && [ -f "certs/server.key" ]; then
        check_pass "Certificados del servidor generados ✓"
    else
        check_warning "Certificados del servidor NO encontrados (ejecutar generate-certs.sh)"
    fi
else
    check_warning "Carpeta certs/ NO EXISTE (ejecutar generate-certs.sh)"
fi

echo ""
echo "========================================"
echo "📊 RESUMEN DE VALIDACIÓN"
echo "========================================"
echo -e "${GREEN}✅ PASSED:  $PASSED${NC}"
echo -e "${RED}❌ FAILED:  $FAILED${NC}"
echo -e "${YELLOW}⚠️  WARN:   $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✨ ¡VALIDACIÓN EXITOSA!${NC}"
    echo ""
    echo "Siguientes pasos:"
    echo "  1. Ejecutar: ./scripts/generate-certs.sh"
    echo "  2. Cambiar IP en radius/clients.conf a tu Omada Controller"
    echo "  3. Ejecutar: docker-compose up -d"
    echo "  4. Ver logs: docker logs -f freeradius"
    exit 0
else
    echo -e "${RED}❌ VALIDACIÓN FALLIDA${NC}"
    echo ""
    echo "Por favor, corregir los errores indicados arriba."
    exit 1
fi
