# server_yolo.py - Servidor que recibe frames y devuelve resultados
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import cv2
import numpy as np
from io import BytesIO
from PIL import Image
import base64
import torch

app = FastAPI(title="YOLO API para detección de vehículos")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Forzar CPU
torch.cuda.is_available = lambda: False

# Cargar modelos
print("Cargando modelos YOLO...")
modelos = {
    "yolo11n": YOLO("yolo11n.pt"),
    "yolo11s": YOLO("yolo11s.pt"),
    "yolov8n": YOLO("yolov8n.pt"),
    "yolov8s": YOLO("yolov8s.pt"),
}
print("✅ Modelos cargados")

@app.get("/")
def root():
    return {"status": "ok", "message": "YOLO API Server"}

@app.post("/detect")
async def detect_vehicles(
    image: UploadFile = File(...),
    model_name: str = "yolo11n"
):
    """Recibe una imagen y devuelve detecciones"""
    try:
        # Leer imagen
        contents = await image.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="No se pudo decodificar la imagen")
        
        # Redimensionar
        img = cv2.resize(img, (640, 360))
        
        # Procesar con YOLO
        modelo = modelos.get(model_name, modelos["yolo11n"])
        results = modelo(img, conf=0.25, verbose=False)[0]
        
        # Contar vehículos
        vehicles_count = 0
        detections = []
        
        for box in results.boxes:
            cls = int(box.cls)
            label = results.names[cls]
            
            if label in ['car', 'truck', 'bus', 'motorcycle', 'bicycle']:
                vehicles_count += 1
                x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
                confidence = float(box.conf[0])
                
                detections.append({
                    "label": label,
                    "confidence": confidence,
                    "bbox": [x1, y1, x2, y2]
                })
                
                # Dibujar en la imagen
                cv2.rectangle(img, (x1, y1), (x2, y2), (255, 0, 0), 2)
                cv2.putText(img, f"{label} {confidence:.2f}", (x1, y1-5),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
        
        # Añadir información
        cv2.putText(img, f"Vehiculos: {vehicles_count}", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # Codificar imagen resultante
        _, buffer = cv2.imencode('.jpg', img)
        img_base64 = base64.b64encode(buffer).decode('utf-8')
        
        return JSONResponse({
            "success": True,
            "vehicles_count": vehicles_count,
            "detections": detections,
            "processed_image": img_base64
        })
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return JSONResponse({
            "success": False,
            "error": str(e)
        }, status_code=500)

if __name__ == "__main__":
    import uvicorn
    print("\n🚀 Servidor YOLO iniciado")
    print("📍 http://localhost:8000")
    print("📤 POST /detect - Enviar imagen para detección")
    uvicorn.run(app, host="0.0.0.0", port=8000)