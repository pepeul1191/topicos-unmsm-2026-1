import cv2
import numpy as np
import asyncio
import websockets
import base64
import json
from ultralytics import YOLO
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PlacaDetectorServer:
    def __init__(self, modelo_path='models/best_upeu_yolo12_100ep.pt', conf_threshold=0.25):
        logger.info(f"Cargando modelo: {modelo_path}")
        self.model = YOLO(modelo_path)
        self.conf_threshold = conf_threshold
        self.connected_clients = set()
        
        # Imprimir clases para debug
        logger.info(f"Clases del modelo: {self.model.names}")
        
    def preprocess_for_printed_plate(self, img):
        """
        Preprocesamiento para mejorar detección de placas impresas
        """
        # 1. Aumentar contraste drásticamente
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
        l_enhanced = clahe.apply(l)
        enhanced_lab = cv2.merge([l_enhanced, a, b])
        contrast_img = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2BGR)
        
        # 2. Nitidez (simula textura metálica)
        kernel = np.array([[-1,-1,-1],
                           [-1, 9,-1],
                           [-1,-1,-1]])
        sharpened = cv2.filter2D(contrast_img, -1, kernel)
        
        # 3. Reducir brillo (las fotos reales suelen ser más oscuras)
        darker = cv2.addWeighted(sharpened, 0.7, np.zeros(sharpened.shape, sharpened.dtype), 0, 0)
        
        # 4. Agregar un marco negro simulado (como si fuera el auto)
        h, w = darker.shape[:2]
        border_size = int(min(h, w) * 0.15)
        with_frame = cv2.copyMakeBorder(darker, border_size, border_size,
                                        border_size, border_size,
                                        cv2.BORDER_CONSTANT, value=[30,30,30])
        
        return with_frame
    
    def decode_frame(self, frame_data):
        frame_bytes = base64.b64decode(frame_data)
        nparr = np.frombuffer(frame_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return img
    
    def encode_frame(self, img):
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 80])
        return base64.b64encode(buffer).decode('utf-8')
    
    def detect_plates(self, img):
        # Aplicar preprocesamiento para placa impresa
        processed_img = self.preprocess_for_printed_plate(img)
        
        # Realizar detección
        results = self.model(processed_img, conf=self.conf_threshold, iou=0.45)
        
        detections = []
        annotated_img = processed_img.copy()
        
        for result in results:
            boxes = result.boxes
            if boxes is not None and len(boxes) > 0:
                logger.info(f"Se encontraron {len(boxes)} detecciones potenciales")
                
                for box in boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    confidence = float(box.conf[0])
                    class_id = int(box.cls[0])
                    class_name = self.model.names.get(class_id, "plate")
                    
                    # FILTRO: Solo considerar detecciones con tamaño razonable
                    area = (x2 - x1) * (y2 - y1)
                    img_area = processed_img.shape[0] * processed_img.shape[1]
                    area_ratio = area / img_area
                    
                    # Una placa debería ocupar entre 5% y 30% de la imagen
                    if 0.05 < area_ratio < 0.30:
                        detection = {
                            'bbox': [x1, y1, x2, y2],
                            'confidence': confidence,
                            'class': class_name,
                            'class_id': class_id,
                            'area_ratio': area_ratio
                        }
                        detections.append(detection)
                        
                        # Dibujar detección
                        cv2.rectangle(annotated_img, (x1, y1), (x2, y2), (0, 255, 0), 3)
                        label = f"PLACA: {confidence:.2f}"
                        cv2.putText(annotated_img, label, (x1, y1-10), 
                                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                        
                        logger.info(f"Detección aceptada: conf={confidence:.2f}, area={area_ratio:.2%}")
                    else:
                        logger.debug(f"Detección rechazada por tamaño: area={area_ratio:.2%}")
        
        # Si no hay detecciones, mostrar mensaje
        if len(detections) == 0:
            cv2.putText(annotated_img, "No se detecto placa - ajustando parametros", 
                       (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
            
            # Dibujar guías para el usuario
            h, w = annotated_img.shape[:2]
            cv2.rectangle(annotated_img, (int(w*0.2), int(h*0.3)), 
                         (int(w*0.8), int(h*0.7)), (255, 0, 0), 2)
            cv2.putText(annotated_img, "Coloca la placa dentro del rectangulo azul", 
                       (10, h-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1)
        
        return detections, annotated_img
    
    # ⭐ IMPORTANTE: Aquí está la corrección - eliminamos el parámetro 'path'
    async def handle_client(self, websocket):  # ← Solo websocket, sin path
        client_id = id(websocket)
        self.connected_clients.add(websocket)
        logger.info(f"Cliente conectado. Total: {len(self.connected_clients)}")
        
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    
                    if data['type'] == 'frame':
                        frame = self.decode_frame(data['image'])
                        detections, annotated_frame = self.detect_plates(frame)
                        result_frame = self.encode_frame(annotated_frame)
                        
                        response = {
                            'type': 'detection',
                            'image': result_frame,
                            'detections': detections,
                            'timestamp': datetime.now().isoformat()
                        }
                        
                        await websocket.send(json.dumps(response))
                        
                        if detections:
                            logger.info(f"✅ Placas detectadas: {len(detections)}")
                        else:
                            logger.debug("❌ No se detectaron placas")
                    
                    elif data['type'] == 'ping':
                        await websocket.send(json.dumps({'type': 'pong'}))
                        
                except Exception as e:
                    logger.error(f"Error procesando: {e}")
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info("Cliente desconectado")
        finally:
            self.connected_clients.remove(websocket)

async def main():
    # Configuración específica para placa impresa
    server = PlacaDetectorServer(
        modelo_path='models/best_upeu_yolo12_100ep.pt',
        conf_threshold=0.25  # Threshold más bajo para impresiones
    )
    
    # ⭐ Nota: El serve() automáticamente pasa solo el websocket, no el path
    async with websockets.serve(server.handle_client, "localhost", 8765):
        logger.info("=== SERVIDOR PARA PLACA IMPRESA ===")
        logger.info("Consejos para mejorar deteccion:")
        logger.info("1. Coloca la hoja sobre una superficie oscura")
        logger.info("2. Ilumina bien la placa (luz natural o lampara)")
        logger.info("3. Manten la camara a 20-30cm de distancia")
        logger.info("4. Evita sombras sobre la placa")
        logger.info("====================================")
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())