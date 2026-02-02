#!/bin/bash

# Define Log File
LOG_FILE="/Users/rodrigoperezcordero/Documents/prevencion_pug/webapp/debug_launch.log"

echo "=========================================="
echo "   INICIANDO SISTEMA & DIAGNÓSTICO"
echo "=========================================="
echo "Log detallado en: $LOG_FILE"
echo "------------------------------------------"

# Function to log actions
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Cleanup previous
log "Limpiando procesos anteriores..."
# CRITICAL: Force kill anything holding port 8000 (like the old STEM app)
lsof -ti :8000 | xargs kill -9 2>/dev/null
pkill -f "python3 -m http.server 8000" >> "$LOG_FILE" 2>&1
pkill -f "cloudflared" >> "$LOG_FILE" 2>&1

# Remove old QR to avoid confusion
rm -f qr_access.png

# 1. Start Local Server
log "Iniciando Servidor Web Local (Python)..."
# Bind to 0.0.0.0 to ensure it's reachable on all interfaces (IPv4/IPv6)
python3 -m http.server 8000 --bind 0.0.0.0 >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!
sleep 2

# Verify Local Server
if lsof -i :8000 > /dev/null; then
    log "✅ Servidor Local OK en puerto 8000"
else
    log "❌ Error: El servidor local no inició. Revisa los logs."
    exit 1
fi

# ... (Network Check kept same) ...

# 4. Start Tunnel with robust settings
log "Iniciando Túnel de Acceso Público (Cloudflare)..."
log "Esto puede tardar unos segundos en conectar..."

# Use HTTP/2 and point to 127.0.0.1 explicitly
./cloudflared tunnel --url http://127.0.0.1:8000 --protocol http2 > /tmp/cf_tunnel.log 2>&1 &
TUNNEL_PID=$!

# Wait loop
MAX_RETRIES=30
COUNT=0
PUBLIC_URL=""

while [ $COUNT -lt $MAX_RETRIES ]; do
    sleep 1
    # Check if process is still running
    if ! ps -p $TUNNEL_PID > /dev/null; then
        log "❌ Error: El proceso del túnel murió inesperadamente."
        log "--- Últimas líneas del log del túnel ---"
        tail -n 10 /tmp/cf_tunnel.log | tee -a "$LOG_FILE"
        break
    fi

# ... (Process check) ...

    # Try to grab URL
    PUBLIC_URL=$(grep -o "https://[a-zA-Z0-9-]*\.trycloudflare\.com" /tmp/cf_tunnel.log | head -n 1)
    
    if [ -n "$PUBLIC_URL" ]; then
        # VERIFY CONNECTION BEFORE SHOWING
        # Capture the HTTP status code AND the error message
        HTTP_RESPONSE=$(curl -s --max-time 3 -w "|%{http_code}" "$PUBLIC_URL" 2>&1)
        # Split response into Body+Error and Status Code using delimiter |
        HTTP_BODY=${HTTP_RESPONSE%|*}
        HTTP_STATUS=${HTTP_RESPONSE##*|}
        
        log "Verificando URL pública... Código: $HTTP_STATUS"
        
        if [ "$HTTP_STATUS" = "200" ]; then
             log "✅ Verificación Exitosa: La URL responde 200 OK."
             break
        elif [ "$HTTP_STATUS" = "000" ]; then
             log "⚠️  Error de Conexión (000): Tu Mac no puede contactar la URL."
             log "   Posible causa: Bloqueo DNS o Firewall corporativo."
             
             # Show curl error details if meaningful
             if [ -n "$HTTP_BODY" ]; then
                 log "   Detalle Curl: $HTTP_BODY"
             fi

             # CHECK CLOUDFLARE LOGS DIRECTLY
             if grep -q "Registered tunnel connection" /tmp/cf_tunnel.log; then
                 log "✅ Túnel Confirmado en Logs: Conexión Exitosa."
                 log "⚠️  Nota: Tu Mac no puede ver la web (DNS), pero el mundo exterior SÍ."
                 break
             else
                 log "   (Cloudflare aún no confirma conexión en el log...)"
             fi
             
        elif [ "$HTTP_STATUS" = "502" ]; then
             log "⚠️  Error 502: Túnel conectado, pero Python no responde (revisando...)"
        else
             log "⏳ Esperando propagación (Estado: $HTTP_STATUS)..."
        fi
    fi
    
    echo -n "."
    COUNT=$((COUNT+1))
done
echo ""

if [ -n "$PUBLIC_URL" ]; then
    log "✅ CONEXIÓN EXITOSA"
    echo ""
    echo "=================================================="
    echo "🔗 URL PÚBLICA (Acceso Global):"
    echo "   $PUBLIC_URL"
    echo "=================================================="
    echo ""
    log "URL generada: $PUBLIC_URL"
    
    # QR Code - Generate Image for reliability
    if python3 -c "import qrcode" 2>/dev/null; then
        echo "Generando imagen del código QR..."
        
        python3 << EOF
import qrcode
# Generate Image
try:
    img = qrcode.make('$PUBLIC_URL')
    img.save('qr_access.png')
    print("QR guardado como qr_access.png")
except ImportError:
    print("Nota: Instala 'pillow' para generar la imagen PNG.")
except Exception as e:
    print(f"Error generando imagen: {e}")
EOF
        # Open the image automatically on Mac
        if [ -f "qr_access.png" ]; then
            open qr_access.png
        fi
    else
        echo "Nota: Instala 'qrcode' para generar la imagen PNG."
    fi
else
    log "❌ Error: No se pudo obtener la URL pública después de 30 segundos."
    log "Revisando logs de Cloudflared:"
    cat /tmp/cf_tunnel.log | tee -a "$LOG_FILE"
fi

# 6. Display Local Network Option (Fallback)
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP="127.0.0.1"
fi

echo ""
echo "=================================================="
echo "       OPCIÓN B: ACCESO LOCAL (WIFI)"
echo "=================================================="
echo "Si el QR no carga porque la red es restrictiva,"
echo "conecta tu celular al mismo WiFi y entra a:"
echo ""
echo "👉 http://$LOCAL_IP:8000"
echo ""
echo "=================================================="

echo ""
echo "Presiona CTRL+C para salir."

# Trap for cleanup
trap "kill $SERVER_PID 2>/dev/null; kill $TUNNEL_PID 2>/dev/null; exit" INT

wait
