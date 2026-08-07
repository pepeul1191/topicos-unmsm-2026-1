import cv2
import numpy as np
import asyncio
import websockets
import base64
import json
import easyocr
import re
import logging
from datetime import datetime
from ultralytics import YOLO
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PlateOnlyServer:
    def __init__(self, yolo_model_path='models/best.pt'):
        logger.info("🎯 Inicializando detector enfocado en placas...")
        
        self.yolo_model = YOLO(yolo_model_path)
        self.ocr_reader = easyocr.Reader(['es', 'en'], gpu=False)
        
        self.frame_counter = 0
        self.process_every_n_frames = 10
        self.last_plate = None
        self.last_bbox = None
        self.last_confidence = 0  # ⭐ Agregar variable para guardar confianza
        
        logger.info("✅ Modo: Solo texto grande de placa")
    
    def decode_frame(self, frame_data):
        frame_bytes = base64.b64decode(frame_data)
        nparr = np.frombuffer(frame_bytes, np.uint8)
        return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    def is_valid_car_plate(self, plate_text):
        """
        Valida placa de auto peruana
        
        Formatos aceptados (Post-2016):
        - ABC-123 (tradicional)
        - A1B-234 (mixto)
        - 123-456 (numérico)
        """
        if not plate_text:
            return False
        
        # Limpiar y convertir a mayúsculas
        clean = re.sub(r'[^A-Z0-9]', '', plate_text.upper())
        
        # Debe tener 6 caracteres exactamente
        if len(clean) != 6:
            return False
        
        # Últimos 3 deben ser números
        if not clean[3:].isdigit():
            return False
        
        # Primeros 3 pueden ser cualquier caracter alfanumérico
        # (no hay restricción adicional)
        return True
    
    def encode_frame(self, img, quality=60):
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, quality])
        return base64.b64encode(buffer).decode('utf-8')
    
    def resize_for_speed(self, img, max_size=480):
        h, w = img.shape[:2]
        if max(h, w) > max_size:
            scale = max_size / max(h, w)
            new_w = int(w * scale)
            new_h = int(h * scale)
            return cv2.resize(img, (new_w, new_h))
        return img
    
    def convert_ocr_bbox_to_rectangle(self, ocr_bbox):
        """
        Convierte bbox de OCR (4 puntos) a rectángulo (x1,y1,x2,y2)
        """
        if not ocr_bbox:
            return None
        
        x_coords = [p[0] for p in ocr_bbox]
        y_coords = [p[1] for p in ocr_bbox]
        
        x1 = min(x_coords)
        y1 = min(y_coords)
        x2 = max(x_coords)
        y2 = max(y_coords)
        
        return [int(x1), int(y1), int(x2), int(y2)]
    
    def filter_large_text(self, ocr_results, min_height=25):
        """
        Filtra solo texto grande (el de la placa)
        """
        filtered = []
        for (bbox, text, confidence) in ocr_results:
            y_coords = [p[1] for p in bbox]
            height = max(y_coords) - min(y_coords)
            
            if height >= min_height:
                clean = re.sub(r'[^A-Z0-9]', '', text.upper())
                if len(clean) >= 3:
                    rect = self.convert_ocr_bbox_to_rectangle(bbox)
                    filtered.append((rect, clean, confidence, height))
        
        return filtered
    
    def extract_plate_text(self, img):
        """
        Extrae SOLO el texto grande de la placa
        """
        h, w = img.shape[:2]
        small_img = self.resize_for_speed(img, 640)
        scale_x = w / small_img.shape[1]
        scale_y = h / small_img.shape[0]
        
        gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(4,4))
        enhanced = clahe.apply(gray)
        _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        results = self.ocr_reader.readtext(
            binary,
            allowlist='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-',
            paragraph=False,
            detail=1
        )
        
        large_texts = self.filter_large_text(results, min_height=25)
        
        if large_texts:
            best = max(large_texts, key=lambda x: x[3])
            bbox_rect, text, confidence, height = best
            
            x1, y1, x2, y2 = bbox_rect
            x1 = int(x1 * scale_x)
            y1 = int(y1 * scale_y)
            x2 = int(x2 * scale_x)
            y2 = int(y2 * scale_y)
            
            if len(text) == 6 and '-' not in text:
                text = f"{text[:3]}-{text[3:]}"
            
            return text, [x1, y1, x2, y2], confidence
        
        return None, None, None
    
    def detect_with_yolo(self, img):
        """
        Usa YOLO para encontrar la ubicación de la placa
        """
        small_img = self.resize_for_speed(img, 320)
        scale_x = img.shape[1] / small_img.shape[1]
        scale_y = img.shape[0] / small_img.shape[0]
        
        results = self.yolo_model(small_img, conf=0.25, verbose=False)
        
        best_box = None
        best_conf = 0
        
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    confidence = float(box.conf[0])
                    
                    x1 = int(x1 * scale_x)
                    y1 = int(y1 * scale_y)
                    x2 = int(x2 * scale_x)
                    y2 = int(y2 * scale_y)
                    
                    if confidence > best_conf:
                        best_conf = confidence
                        best_box = [x1, y1, x2, y2]
        
        return best_box, best_conf
    
    def process_frame(self, img):
        """
        Procesa un frame
        """
        self.frame_counter += 1
        annotated = img.copy()
        
        should_process = (self.frame_counter % self.process_every_n_frames == 0)
        
        if should_process:
            # Intentar OCR primero
            plate_text, ocr_bbox, ocr_conf = self.extract_plate_text(img)
            
            if plate_text and ocr_bbox:
                self.last_plate = plate_text
                self.last_bbox = ocr_bbox
                self.last_confidence = ocr_conf  # ⭐ Guardar la confianza
                logger.info(f"🇵🇪 Placa: {plate_text} (conf: {ocr_conf:.2%})")
            else:
                # Fallback con YOLO
                yolo_box, yolo_conf = self.detect_with_yolo(img)
                if yolo_box:
                    self.last_bbox = yolo_box
                    self.last_confidence = yolo_conf  # ⭐ Guardar confianza de YOLO
                    logger.info(f"📍 Ubicación detectada (YOLO), esperando texto...")
        
        # Dibujar resultado (opcional, puedes comentar si no quieres imagen)
        if self.last_bbox:
            x1, y1, x2, y2 = self.last_bbox
            if all(isinstance(v, int) for v in [x1, y1, x2, y2]):
                cv2.rectangle(annotated, (x1, y1), (x2, y2), (0, 255, 0), 3)
                
                if self.last_plate:
                    cv2.putText(annotated, f"{self.last_plate} ({self.last_confidence:.2%})", 
                               (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                else:
                    cv2.putText(annotated, "Leyendo placa...", (x1, y1-10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        else:
            cv2.putText(annotated, "🔍 Coloca la placa frente a la camara", 
                       (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        
        return annotated
    
    async def handle_client(self, websocket):
        logger.info("Cliente conectado")
        
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    
                    if data['type'] == 'frame':
                        start = time.time()
                        
                        frame = self.decode_frame(data['image'])
                        annotated = self.process_frame(frame)
                        result = self.encode_frame(annotated, quality=50)
                        
                        # Inicializar respuesta por defecto
                        response = {
                            'type': 'detection',
                            'plate': None,
                            'ocr_conf': 0,
                            'process_time': round((time.time() - start) * 1000, 1)
                        }
                        
                        # Si hay placa y es válida, actualizar respuesta
                        print('1 +++++++++++++++++++++++++++++++')
                        print(self.last_plate)
                        print('2 +++++++++++++++++++++++++++++++')
                        if self.last_plate:
                            if self.is_valid_car_plate(self.last_plate):
                                print('3 +++++++++++++++++++++++++++++++')
                                response['plate'] = self.last_plate
                                response['ocr_conf'] = round(self.last_confidence, 3) if self.last_confidence else 0
                                logger.info(f"✅ Enviando: {self.last_plate} (conf: {self.last_confidence:.2%})")
                                # enviar respuesta (solo cuando hay placa)
                                await websocket.send(json.dumps(response))
                            else:
                                logger.debug(f"❌ Placa inválida (formato): {self.last_plate}")
                        else:
                            logger.debug("🔍 Sin placa detectada")
                        
                    elif data['type'] == 'ping':
                        await websocket.send(json.dumps({'type': 'pong'}))
                        
                except Exception as e:
                    logger.error(f"Error: {e}")
                    import traceback
                    traceback.print_exc()
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info("Cliente desconectado")
async def main():
    server = PlateOnlyServer(yolo_model_path='models/best.pt')
    
    async with websockets.serve(server.handle_client, "192.168.1.23", 8765):
        logger.info("=" * 50)
        logger.info("🎯 SERVIDOR CORREGIDO - CON CONFIANZA")
        logger.info("=" * 50)
        logger.info("✅ Incluye 'ocr_conf' en la respuesta")
        logger.info("✅ Confianza formateada como porcentaje")
        logger.info("=" * 50)
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())