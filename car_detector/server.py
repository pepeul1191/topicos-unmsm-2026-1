from PIL import Image, ImageDraw, ImageFont
import cv2
import numpy as np
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, FileResponse
from pydantic import BaseModel
from ultralytics import YOLO
import yt_dlp

app = FastAPI(title = "API de prueba local de YOLO")

# Permitir todas las conexiones para evitar bloqueos
app.add_middleware(
    CORSMiddleware,
    allow_origins       = ["*"],
    allow_credentials   = True,
    allow_methods       = ["*"],
    allow_headers       = ["*"],
)

# Cargar modelos en memoria
print("Cargando modelos YOLO...")
modelos = {
    "yolov8n": YOLO("yolov8n.pt"),
    "yolov8s": YOLO("yolov8s.pt"),
    "yolo11n": YOLO("yolo11n.pt"),
    "yolo11s": YOLO("yolo11s.pt")
}

class ConfigParametros(BaseModel):
    tipo_fuente: str
    fuente: str
    modelo: str

@app.get("/")
def obtener_interfaz():
    ruta_html = os.path.join(os.path.dirname(__file__), "index.html")
    if os.path.exists(ruta_html):
        return FileResponse(ruta_html)
    raise HTTPException(status_code=404, detail="No se encontro el archivo index.html")

def inicializar_fuente(tipo, fuente):
    tipo    = tipo.lower()
    if tipo == "webcam": 
        return cv2.VideoCapture(int(fuente))
    
    if tipo in ["local", "rtsp", "m3u8"]: 
        return cv2.VideoCapture(fuente)
    
    if tipo == "youtube":
        try:
            ydl_opts = {'format': 'best[ext=mp4]/best', 'quiet': True}
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(fuente, download = False)
                return cv2.VideoCapture(info['url'])
        except Exception as e:
            print(f"Error en YouTube: {e}")
            return None
    return None

def motor_vision_artificial(cap, modelo):
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 2)
    contador_total = 0
    linea_y = 240  
    
    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret: 
                break
            
            frame = cv2.resize(frame, (640, 360))
            results = modelo(frame, conf=0.25, verbose=False)[0]
            autos_en_pantalla = 0
            
            for box in results.boxes:
                cls = int(box.cls)
                label = results.names[cls]
                
                if label in ['car', 'truck', 'bus', 'motorcycle']:
                    autos_en_pantalla += 1
                    x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 0, 0), 2)
                    cx = int((x1 + x2) / 2)
                    cy = int((y1 + y2) / 2)
                    cv2.circle(frame, (cx, cy), 4, (0, 0, 255), -1)
                    
                    if abs(cy - linea_y) < 4:
                        contador_total += 1

            estado_trafico = "Bajo" if autos_en_pantalla <= 8 else "Alto"
            color_alerta = (0, 255, 0) if autos_en_pantalla <= 8 else (0, 0, 255)

            cv2.line(frame, (0, linea_y), (640, linea_y), (0, 255, 255), 2)
            cv2.rectangle(frame, (10, 10), (240, 95), (0, 0, 0), -1)

            # 2. Convertir el frame de OpenCV (BGR) a formato PIL para poder usar fuentes del sistema
            img_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            draw = ImageDraw.Draw(img_pil)

            # 3. Cargar una fuente del sistema (Usa Arial o una por defecto si no existe)
            try:
                # En Windows, las fuentes estan en C:\Windows\Fonts. Arial soporta tildes perfectamente.
                font_path = "C:\\Windows\\Fonts\\arial.ttf"
                font = ImageFont.truetype(font_path, 16)       # Texto normal
                font_bold = ImageFont.truetype(font_path, 17)  # Texto destacado
            except:
                # Si falla por estar en otro sistema operativo, carga la fuente basica sin tildes
                font = ImageFont.load_default()
                font_bold = ImageFont.load_default()

            # 4. Dibujar los textos estilizados con soporte nativo para tildes
            # Sintaxis: draw.text((X, Y), "Texto", font=fuente, fill=(R, G, B))
            draw.text((20, 20), f"Vehículos: {autos_en_pantalla}", font=font, fill=(255, 255, 255))
            draw.text((20, 45), f"Contador Total: {contador_total}", font=font, fill=(255, 255, 255))
            
            # Definir el color RGB de la alerta según el tráfico
            color_rgb = (0, 255, 0) if autos_en_pantalla <= 8 else (255, 0, 0)
            draw.text((20, 70), f"Tráfico: {estado_trafico}", font=font_bold, fill=color_rgb)

            # 5. Volver a convertir la imagen al formato original de OpenCV (BGR)
            frame = cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)



            #cv2.putText(frame, f"Vehiculos: {autos_en_pantalla}", (20, 35), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            #cv2.putText(frame, f"Contador: {contador_total}", (20, 55), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            #cv2.putText(frame, f"Trafico: {estado_trafico}", (20, 75), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color_alerta, 2)



            _, buffer = cv2.imencode('.jpg', frame)
            yield (b'--frame\r\nContent-Type: image/jpeg\r\n\r\n' + buffer.tobytes() + b'\r\n')
            
    finally:
        cap.release()

@app.get("/stream_analitica")
def stream_analitica_get(tipo_fuente: str = "local", fuente: str = "SavedVideo.mp4", modelo: str = "yolo11n"):
    if tipo_fuente.lower() == "local" and not os.path.isabs(fuente):
        fuente = os.path.join(os.path.dirname(__file__), fuente)
        print(f"[INFO] Ruta absoluta del video: {fuente}")

    cap = inicializar_fuente(tipo_fuente, fuente)
    if cap is None or not cap.isOpened():
        print(f"[ERROR] No se pudo abrir la fuente: {fuente}")
        raise HTTPException(status_code=400, detail="Error al abrir fuente")
        
    return StreamingResponse(
        motor_vision_artificial(cap, modelos[modelo]), 
        media_type="multipart/x-mixed-replace; boundary=frame"
    )
