<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Analizador Biomecánico - Zancada (Lunge)</title>
    <script src="https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/pose.js" crossorigin="anonymous"></script>
    
    <style>
        :root {
            --bg: #f3f4f6;
            --card-bg: #ffffff;
            --primary: #3b82f6;
            --primary-hover: #2563eb;
            --success: #10b981;
            --success-hover: #059669;
            --text: #1f2937;
            --border: #e5e7eb;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg);
            color: var(--text);
            margin: 0;
            padding: 20px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
        }

        h1 {
            text-align: center;
            font-size: 2rem;
            margin-bottom: 30px;
            color: #111827;
        }

        /* Barra superior de controles */
        .top-bar {
            display: flex;
            flex-direction: column;
            gap: 15px;
            background: var(--card-bg);
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            margin-bottom: 25px;
            align-items: center;
        }

        .upload-group {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 10px;
            width: 100%;
        }

        .upload-group h3 {
            margin: 0;
            font-size: 1.1rem;
            color: var(--primary);
        }

        input[type="file"] {
            font-size: 1rem;
        }

        #btn-capture {
            background-color: var(--success);
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 1.2rem;
            font-weight: bold;
            border-radius: 8px;
            cursor: pointer;
            width: 100%;
            max-width: 350px;
            transition: background 0.2s;
            box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);
        }

        #btn-capture:hover:not(:disabled) { background-color: var(--success-hover); }
        #btn-capture:disabled { background: #9ca3af; cursor: not-allowed; box-shadow: none; }

        /* Contenedor principal dividido en 2 columnas */
        .main-workspace {
            display: flex;
            flex-direction: column;
            gap: 25px;
        }

        /* Panel Izquierdo: Video */
        .video-panel {
            flex: 1.2;
            background: #000;
            border-radius: 12px;
            overflow: hidden;
            position: relative;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }

        video {
            width: 100%;
            height: auto;
            display: block;
        }

        canvas {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
        }

        /* Panel Derecho: Resultados */
        .results-panel {
            flex: 1;
            background: var(--card-bg);
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            display: flex;
            flex-direction: column;
        }

        .results-panel h2 {
            margin-top: 0;
            border-bottom: 2px solid var(--border);
            padding-bottom: 15px;
            color: #111827;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .data-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px 0;
            border-bottom: 1px solid var(--border);
            font-size: 1.1rem;
        }

        .data-row:last-child {
            border-bottom: none;
        }

        .data-label {
            font-weight: 500;
            color: #4b5563;
        }

        .data-value {
            font-weight: 700;
            color: var(--primary);
            font-size: 1.3rem;
        }

        .status-badge {
            background: #fef3c7;
            color: #d97706;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: bold;
        }

        @media (min-width: 992px) {
            .top-bar { flex-direction: row; justify-content: space-between; padding: 20px 40px; }
            .upload-group { align-items: flex-start; width: auto; }
            #btn-capture { width: auto; }
            .main-workspace { flex-direction: row; }
        }
    </style>
</head>
<body>

    <div class="container">
        <h1>Análisis Kinésico de Zancada (Perfil Sagital)</h1>

        <div class="top-bar">
            <div class="upload-group">
                <h3>Subir Video (Vista Lateral)</h3>
                <input type="file" id="input-video" accept="video/*">
            </div>
            <button id="btn-capture" disabled>📸 Capturar Análisis</button>
        </div>

        <div class="main-workspace">
            <div class="video-panel">
                <!-- Se reproduce en bucle automáticamente -->
                <video id="video" playsinline muted loop></video>
                <canvas id="canvas"></canvas>
            </div>

            <div class="results-panel">
                <h2>Resultados del Gesto <span id="side-badge" class="status-badge">Esperando...</span></h2>
                
                <div class="data-row">
                    <span class="data-label">Inclinación de Tronco (vs Línea Vertical)</span>
                    <span class="data-value" id="res-tronco">--°</span>
                </div>
                <div class="data-row">
                    <span class="data-label">Flexión Cadera (Pierna Adelantada)</span>
                    <span class="data-value" id="res-cadera">--°</span>
                </div>
                <div class="data-row">
                    <span class="data-label">Flexión Rodilla Derecha</span>
                    <span class="data-value" id="res-rodilla-der">--°</span>
                </div>
                <div class="data-row">
                    <span class="data-label">Flexión Rodilla Izquierda</span>
                    <span class="data-value" id="res-rodilla-izq">--°</span>
                </div>
                <div class="data-row">
                    <span class="data-label">Dorsiflexión Tobillo (Adelantado)</span>
                    <span class="data-value" id="res-tobillo">--°</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        const videoElem = document.getElementById('video');
        const canvasElem = document.getElementById('canvas');
        const ctx = canvasElem.getContext('2d');
        const inputVideo = document.getElementById('input-video');
        const btnCapture = document.getElementById('btn-capture');

        let isProcessing = false;
        let animationFrameId = null;
        
        // Almacenamos los datos calculados frame a frame
        const currentData = {
            side: '', tronco: '--', cadera: '--', 
            rodillaDer: '--', rodillaIzq: '--', tobillo: '--'
        };

        const L = {
            l_sh: 11, r_sh: 12, // Hombros
            l_hi: 23, r_hi: 24, // Caderas
            l_kn: 25, r_kn: 26, // Rodillas
            l_an: 27, r_an: 28, // Tobillos
            l_ft: 31, r_ft: 32  // Pies
        };

        function calculateAngle(p1, p2, p3) {
            if (!p1 || !p2 || !p3 || p1.visibility < 0.4 || p2.visibility < 0.4 || p3.visibility < 0.4) return null;
            let radians = Math.atan2(p3.y - p2.y, p3.x - p2.x) - Math.atan2(p1.y - p2.y, p1.x - p2.x);
            let angle = Math.abs(radians * 180.0 / Math.PI);
            if (angle > 180.0) angle = 360.0 - angle;
            return Math.round(angle);
        }

        // Calcula ángulo respecto a una vertical pura
        function calculateVerticalAngle(topPoint, bottomPoint) {
            if (!topPoint || !bottomPoint) return null;
            // Punto imaginario exactamente arriba del bottomPoint
            const verticalRef = { x: bottomPoint.x, y: bottomPoint.y - 1, visibility: 1 };
            return calculateAngle(topPoint, bottomPoint, verticalRef);
        }

        function drawLine(ctx, p1, p2, width, height, color = '#00ff00', lineWidth = 3) {
            if (!p1 || !p2 || p1.visibility < 0.4 || p2.visibility < 0.4) return;
            ctx.beginPath();
            ctx.moveTo(p1.x * width, p1.y * height);
            ctx.lineTo(p2.x * width, p2.y * height);
            ctx.lineWidth = lineWidth;
            ctx.strokeStyle = color; 
            ctx.stroke();
        }

        function onResults(results) {
            ctx.clearRect(0, 0, canvasElem.width, canvasElem.height);
            if (!results.poseLandmarks) return;

            const lm = results.poseLandmarks;
            const w = canvasElem.width;
            const h = canvasElem.height;

            // Detección de perfil (qué lado mira a la cámara)
            const leftVis = lm[L.l_hi].visibility + lm[L.l_kn].visibility;
            const rightVis = lm[L.r_hi].visibility + lm[L.r_kn].visibility;
            const isLeftProfile = leftVis > rightVis;
            
            currentData.side = isLeftProfile ? 'Perfil Izquierdo' : 'Perfil Derecho';

            // Puntos principales basados en el perfil
            const p_sh = isLeftProfile ? L.l_sh : L.r_sh;
            const p_hi = isLeftProfile ? L.l_hi : L.r_hi;
            const p_kn = isLeftProfile ? L.l_kn : L.r_kn;
            const p_an = isLeftProfile ? L.l_an : L.r_an;
            const p_ft = isLeftProfile ? L.l_ft : L.r_ft;

            // 1. Línea de Referencia Vertical (Azul celeste) cruzando la cadera
            if (lm[p_hi] && lm[p_hi].visibility > 0.4) {
                ctx.beginPath();
                ctx.moveTo(lm[p_hi].x * w, 0);
                ctx.lineTo(lm[p_hi].x * w, h);
                ctx.lineWidth = 2;
                ctx.strokeStyle = '#0ea5e9'; // Azul vertical
                ctx.setLineDash([10, 10]); // Línea punteada
                ctx.stroke();
                ctx.setLineDash([]); // Resetear
            }

            // Cálculos Kinésicos
            const ang_tronco = calculateVerticalAngle(lm[p_sh], lm[p_hi]);
            const ang_cadera = calculateAngle(lm[p_sh], lm[p_hi], lm[p_kn]);
            const ang_rodilla_der = calculateAngle(lm[L.r_hi], lm[L.r_kn], lm[L.r_an]);
            const ang_rodilla_izq = calculateAngle(lm[L.l_hi], lm[L.l_kn], lm[L.l_an]);
            const ang_tobillo = calculateAngle(lm[p_kn], lm[p_an], lm[p_ft]);

            currentData.tronco = ang_tronco !== null ? ang_tronco : '--';
            currentData.cadera = ang_cadera !== null ? ang_cadera : '--';
            currentData.rodillaDer = ang_rodilla_der !== null ? ang_rodilla_der : '--';
            currentData.rodillaIzq = ang_rodilla_izq !== null ? ang_rodilla_izq : '--';
            currentData.tobillo = ang_tobillo !== null ? ang_tobillo : '--';

            // Dibujar esqueleto básico visible
            drawLine(ctx, lm[p_sh], lm[p_hi], w, h, '#00ff00');
            drawLine(ctx, lm[L.r_hi], lm[L.r_kn], w, h, '#f59e0b'); // Pierna Der Naranja
            drawLine(ctx, lm[L.r_kn], lm[L.r_an], w, h, '#f59e0b');
            drawLine(ctx, lm[L.l_hi], lm[L.l_kn], w, h, '#8b5cf6'); // Pierna Izq Morada
            drawLine(ctx, lm[L.l_kn], lm[L.l_an], w, h, '#8b5cf6');
            drawLine(ctx, lm[p_an], lm[p_ft], w, h, '#00ff00');

            // Dibujar nodos
            const joints = [p_sh, p_hi, L.r_kn, L.l_kn, p_an];
            joints.forEach(j => {
                if (lm[j] && lm[j].visibility > 0.4) {
                    ctx.beginPath();
                    ctx.arc(lm[j].x * w, lm[j].y * h, 6, 0, 2 * Math.PI);
                    ctx.fillStyle = '#ef4444';
                    ctx.fill();
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = '#fff';
                    ctx.stroke();
                }
            });
        }

        const pose = new Pose({locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/${file}`});
        pose.setOptions({
            modelComplexity: 1,
            smoothLandmarks: true,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5
        });
        pose.onResults(onResults);

        pose.initialize().then(() => {
            btnCapture.disabled = false;
        });

        async function processFrames() {
            if (!videoElem.paused && !videoElem.ended) {
                if (!isProcessing) {
                    isProcessing = true;
                    try {
                        await pose.send({image: videoElem});
                    } catch (e) {}
                    isProcessing = false;
                }
                animationFrameId = requestAnimationFrame(processFrames);
            }
        }

        // Carga de video y autoplay
        inputVideo.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                videoElem.src = URL.createObjectURL(file);
            }
        });

        videoElem.addEventListener('loadeddata', () => {
            canvasElem.width = videoElem.videoWidth;
            canvasElem.height = videoElem.videoHeight;
            videoElem.play(); // Auto-reproducir
            processFrames();
        });

        videoElem.addEventListener('play', () => {
            processFrames();
        });

        // Botón Capturar actualiza el panel derecho inmediatamente
        btnCapture.addEventListener('click', () => {
            document.getElementById('side-badge').innerText = currentData.side;
            document.getElementById('res-tronco').innerText = currentData.tronco + '°';
            document.getElementById('res-cadera').innerText = currentData.cadera + '°';
            document.getElementById('res-rodilla-der').innerText = currentData.rodillaDer + '°';
            document.getElementById('res-rodilla-izq').innerText = currentData.rodillaIzq + '°';
            document.getElementById('res-tobillo').innerText = currentData.tobillo + '°';
            
            // Efecto visual de flash
            canvasElem.style.backgroundColor = 'rgba(255, 255, 255, 0.5)';
            setTimeout(() => canvasElem.style.backgroundColor = 'transparent', 100);
        });
    </script>
</body>
</html>
