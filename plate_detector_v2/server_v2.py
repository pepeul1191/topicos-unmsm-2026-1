import asyncio
import base64
import json
import logging
from pathlib import Path
import re
import time
import cv2
import numpy as np
import torch
import websockets
from ultralytics import YOLO

logging.basicConfig(
    level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)


class PlateServer:

  def __init__(self, relative_model_path='runs/exp_nano-5/weights/best.pt'):
    logger.info('🎯 Inicializando servidor YOLO...')

    self.root_dir = Path(__file__).resolve().parent
    model_path = self.root_dir / relative_model_path

    if not model_path.exists():
      raise FileNotFoundError(f'❌ No se encontró el modelo en: {model_path}')

    self.device = '0' if torch.cuda.is_available() else 'cpu'
    self.yolo_model = YOLO(str(model_path))

    # Imprimir las clases registradas
    print('🔍 Clases del modelo:', self.yolo_model.names)

    logger.info(
        f'✅ Modelo YOLO cargado correctamente en dispositivo: {self.device}'
    )

  def decode_frame(self, frame_data):
    try:
      if ',' in frame_data:
        frame_data = frame_data.split(',')[1]

      frame_bytes = base64.b64decode(frame_data)
      nparr = np.frombuffer(frame_bytes, np.uint8)
      return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    except Exception as e:
      logger.error(f'❌ Error decodificando Base64: {e}')
      return None

  def is_valid_car_plate(self, plate_text):
    if not plate_text:
      return False
    clean = re.sub(r'[^A-Z0-9]', '', plate_text.upper())
    return len(clean) == 6 and clean[3:].isdigit()

  def detect_plate(self, img):
    # 1. NO HACEMOS cv2.cvtColor!
    # Ultralytics YOLO procesa directamente el formato BGR de OpenCV.

    # 2. Inferencia con conf=0.40 para filtrar detecciones dudosas e imgsz=640
    results = self.yolo_model.predict(
        source=img, conf=0.40, imgsz=640, device=self.device, verbose=False
    )

    detecciones = []
    for result in results:
      if result.boxes is None:
        continue
      for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        conf = float(box.conf[0])
        cls_id = int(box.cls[0])

        # Mapear el ID a la letra/número real según las clases del modelo
        char_name = result.names[cls_id]
        char_height = y2 - y1

        detecciones.append((x1, y1, x2, y2, char_name, conf, char_height))

    if not detecciones:
      return None, 0, []

    # 3. Filtrar letras principales por altura (evitar "PERU" o holograma si los hubiera)
    max_height = max(d[6] for d in detecciones)
    main_chars = [d for d in detecciones if d[6] >= (max_height * 0.45)]

    # 4. Ordenar estrictamente de izquierda a derecha por coordenada x1
    main_chars.sort(key=lambda d: d[0])

    # 5. Reconstruir el texto
    raw_text = ''.join([d[4] for d in main_chars])
    clean_text = re.sub(r'[^A-Z0-9]', '', raw_text.upper())

    formatted_text = (
        f'{clean_text[:3]}-{clean_text[3:]}'
        if len(clean_text) == 6
        else clean_text
    )
    avg_conf = sum(d[5] for d in main_chars) / len(main_chars)

    # Cajas para retornar al frontend HTML
    boxes_list = [
        {'box': [d[0], d[1], d[2], d[3]], 'label': d[4], 'conf': round(d[5], 2)}
        for d in main_chars
    ]

    return formatted_text, avg_conf, boxes_list

  async def handle_client(self, websocket):
    logger.info('⚡ Cliente conectado por WebSocket')

    try:
      async for message in websocket:
        start_time = time.time()

        try:
          data = json.loads(message)
        except Exception:
          continue

        if data.get('type') == 'frame':
          image_b64 = data.get('image')
          if not image_b64:
            continue

          frame = self.decode_frame(image_b64)
          if frame is None:
            continue

          height, width, _ = frame.shape
          detected_text, conf, boxes = self.detect_plate(frame)
          elapsed = round((time.time() - start_time) * 1000, 1)

          is_valid = self.is_valid_car_plate(detected_text)

          if detected_text:
            logger.info(
                f'📥 Detección: "{detected_text}" | Cajas: {len(boxes)} |'
                f' {elapsed}ms'
            )

          response = {
              'type': 'detection',
              'plate': detected_text if is_valid else None,
              'raw_text': detected_text,
              'ocr_conf': round(conf, 3),
              'process_time': elapsed,
              'frame_size': [width, height],
              'boxes': boxes,
          }
          await websocket.send(json.dumps(response))

    except websockets.exceptions.ConnectionClosed:
      logger.info('🔌 Cliente desconectado')


async def main():
  server = PlateServer()
  async with websockets.serve(server.handle_client, '0.0.0.0', 8765):
    logger.info('=' * 60)
    logger.info('🚀 SERVIDOR ACTIVO EN ws://localhost:8765')
    logger.info('=' * 60)
    await asyncio.Future()


if __name__ == '__main__':
  asyncio.run(main())