# server_yolo_websocket.py
import asyncio
import base64
import cv2
import numpy as np
import torch
from ultralytics import YOLO
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import json
import threading

app = FastAPI(title="YOLO WebSocket Server")

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

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self.lock = threading.Lock()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        with self.lock:
            self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        with self.lock:
            if websocket in self.active_connections:
                self.active_connections.remove(websocket)

    async def send_message(self, websocket: WebSocket, message: dict):
        try:
            await websocket.send_json(message)
        except:
            self.disconnect(websocket)

manager = ConnectionManager()

def process_image(image_bytes: bytes, model_name: str = "yolo11n"):
    """Procesa una imagen y devuelve resultados"""
    try:
        # Decodificar imagen
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return None, None, None
        
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
            confidence = float(box.conf[0])
            
            if label in ['car', 'truck', 'bus', 'motorcycle', 'bicycle']:
                vehicles_count += 1
                x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())
                
                detections.append({
                    "label": label,
                    "confidence": confidence,
                    "bbox": [x1, y1, x2, y2]
                })
                
                # Dibujar bounding box
                cv2.rectangle(img, (x1, y1), (x2, y2), (255, 0, 0), 2)
                cv2.putText(img, f"{label} {confidence:.2f}", (x1, y1-5),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
        
        # Agregar información
        cv2.putText(img, f"Vehiculos: {vehicles_count}", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # Convertir a base64
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 70])
        img_base64 = base64.b64encode(buffer).decode('utf-8')
        
        return vehicles_count, detections, img_base64
        
    except Exception as e:
        print(f"❌ Error procesando imagen: {e}")
        return None, None, None

@app.get("/health")
async def health():
    return {"status": "ok", "models": list(modelos.keys())}

@app.websocket("/ws/detect")
async def websocket_detect(websocket: WebSocket):
    await manager.connect(websocket)
    current_model = "yolo11n"
    
    print(f"✅ Nuevo cliente conectado")
    
    try:
        # Enviar mensaje de bienvenida
        await manager.send_message(websocket, {
            "type": "connected",
            "message": "Conectado al servidor YOLO WebSocket",
            "models": list(modelos.keys())
        })
        
        while True:
            # Recibir mensaje del cliente
            data = await websocket.receive_json()
            
            message_type = data.get("type", "")
            
            if message_type == "config":
                # Cambiar modelo
                current_model = data.get("model", "yolo11n")
                await manager.send_message(websocket, {
                    "type": "config_ack",
                    "model": current_model,
                    "message": f"Modelo cambiado a {current_model}"
                })
                print(f"📦 Modelo cambiado a: {current_model}")
                
            elif message_type == "frame":
                # Procesar frame
                image_base64 = data.get("image", "")
                if image_base64:
                    # Decodificar base64
                    image_bytes = base64.b64decode(image_base64)
                    
                    # Procesar imagen
                    vehicles_count, detections, processed_image = process_image(image_bytes, current_model)
                    
                    if vehicles_count is not None:
                        # Enviar resultados
                        await manager.send_message(websocket, {
                            "type": "detection",
                            "vehicles_count": vehicles_count,
                            "detections": detections,
                            "processed_image": processed_image,
                            "model_used": current_model
                        })
                    else:
                        await manager.send_message(websocket, {
                            "type": "error",
                            "message": "Error procesando la imagen"
                        })
                        
            elif message_type == "ping":
                # Responder a ping
                await manager.send_message(websocket, {"type": "pong"})
                
    except WebSocketDisconnect:
        print(f"❌ Cliente desconectado")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*50)
    print("🚀 Servidor YOLO WebSocket iniciado")
    print("📍 http://localhost:8000")
    print("🔌 WebSocket: ws://localhost:8000/ws/detect")
    print("🔍 GET /health - Verificar estado")
    print("="*50 + "\n")
    
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000,
        log_level="info"
    )