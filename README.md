# Simulador de Tabaquismo - Web App

Aplicación web educativa gamificada para demostrar los efectos del tabaquismo.

## 🚀 Inicio Rápido

### Opción 1: Doble-Click (Más Fácil)
1. Abre la carpeta `prevencion_pug`
2. Haz **doble-click** en `Iniciar Simulador.app`
3. Se abrirá Terminal mostrando el código QR y las URLs

### Opción 2: Terminal
```bash
cd /Users/rodrigoperezcordero/Documents/prevencion_pug/webapp
./launch.sh
```

## 📱 Acceso

El lanzador te dará **dos URLs**:

1. **URL Local** - Para dispositivos en la misma red WiFi
   - Ejemplo: `http://192.168.1.100:8000`
   
2. **URL Pública** - Para acceso desde cualquier red (internet)
   - Ejemplo: `https://random-name.loca.lt`

Escanea el código QR que aparece en la terminal con tu celular.

## 🎮 Cómo Jugar

- **Botón Fumar 🚬**: Daña la salud del personaje (+adicción)
- **Botón Vida Sana 🍎**: Recupera salud (-adicción)
- **Objetivo**: Ver cómo la adicción hace difícil recuperarse

## 📁 Estructura del Proyecto

```
webapp/
├── index.html          # Interfaz principal
├── css/
│   └── styles.css     # Estilos y animaciones
├── js/
│   └── app.js         # Lógica del juego
└── launch.sh          # Script de inicio
```

## 🛠️ Requisitos

- Python 3 (ya instalado en Mac)
- Node.js (para el túnel público)
- Conexión a internet (para túnel)

## 📝 Notas

- El estado del juego se guarda en el navegador (localStorage)
- La primera vez que uses el túnel público, puede pedir hacer click en "Continue"
- Para detener el servidor: presiona CTRL+C en Terminal

## 📄 Documentación

Ver [GDD completo](gdd.tex) para detalles técnicos y pedagógicos.
