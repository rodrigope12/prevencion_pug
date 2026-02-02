#!/bin/bash

# Check if localtunnel is installed
if ! command -v npx &> /dev/null; then
    echo "Error: Node.js (npx) is not installed. Please install Node.js."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 is not installed."
    exit 1
fi

echo "--- Iniciando Servidor de Prevención (Smoking Simulator) ---"

# Kill previous instances if any
pkill -f "python3 -m http.server 8000"

# Start Python Server in background
python3 -m http.server 8000 &
SERVER_PID=$!
echo "Servidor Local iniciado en PID $SERVER_PID"

echo "Esperando a iniciar el túnel..."
sleep 2

# Start Localtunnel and capture output
# We use a temporary file to capture the URL because npx localtunnel keeps running
echo "Generando URL Pública..."
# Try using npx with yes flag to avoid prompts
npx -y localtunnel --port 8000 > tunnel_url.txt 2>&1 &
TUNNEL_PID=$!

sleep 8

# Read URL
URL=$(grep -o "https://[a-zA-Z0-9.-]*\.loca\.lt" tunnel_url.txt | head -n 1)

if [ -z "$URL" ]; then
    echo "No se pudo generar la URL del túnel. Detalles del error:"
    cat tunnel_url.txt
    kill $SERVER_PID
    # kill $TUNNEL_PID # might be already dead
    rm tunnel_url.txt
    exit 1
fi

echo "=================================================="
echo "¡APLICACIÓN EN LÍNEA!"
echo "URL Pública: $URL"
echo "=================================================="

# Generate QR Code
echo "Generando QR..."
# Use an online API to generate QR and display it in terminal using curl/cat if possible, 
# or just print the link big.
# Since we can't easily display images in all terminals, we rely on the user clicking or copying,
# OR we use qrencode if available. We'll fallback to a simple ASCII generator via python if needed,
# or just ask the user to open the URL.

# Let's try to use python qrcode if installed, else simple text.
if python3 -c "import qrcode" &> /dev/null; then
    python3 -c "import qrcode; qr = qrcode.QRCode(); qr.add_data('$URL'); qr.print_ascii()"
else
    echo "Instala 'qrcode' (pip install qrcode) para ver el QR aquí. O visita la URL: $URL"
    echo ""
    echo "Alternativa: Copia la URL y genera un QR en: https://www.the-qrcode-generator.com/"
fi

echo "=================================================="
echo "Presiona CTRL+C para detener el servidor."

# Wait for user interrupt
trap "kill $SERVER_PID; kill $TUNNEL_PID; rm tunnel_url.txt; exit" INT
wait
