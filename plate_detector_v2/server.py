import asyncio
import base64
import json
import logging
from pathlib import Path
import re
import time
import cv2
import websockets
import numpy as np
import torch
from ultralytics import YOLO

# Configurar logs visibles en consola
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
      logger.error(f'❌ No se encontró el archivo de pesos en: {model_path}')
      raise FileNotFoundError(f'No existe: {model_path}')

    self.device = '0' if torch.cuda.is_available() else 'cpu'
    self.yolo_model = YOLO(str(model_path))
    logger.info(
        f'✅ Modelo YOLO cargado correctamente en dispositivo: {self.device}'
    )

    self.frame_counter = 0

  def decode_frame(self, frame_data):
    """Decodifica la imagen Base64 a matriz OpenCV."""
    try:
      frame_bytes = base64.b64decode(frame_data)
      nparr = np.frombuffer(frame_bytes, np.uint8)
      img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
      return img
    except Exception as e:
      logger.error(f'❌ Error decodificando Base64: {e}')
      return None

  def is_valid_car_plate(self, plate_text):
    """Valida formato de placa peruana (6 caracteres alfanuméricos)."""
    if not plate_text:
      return False
    clean = re.sub(r'[^A-Z0-9]', '', plate_text.upper())
    return len(clean) == 6 and clean[3:].isdigit()

  def detect_plate_yolo(self, img):
    """Inferencia con YOLO."""
    # conf=0.25 para capturar detecciones con menor umbral durante pruebas
    results = self.yolo_model.predict(
        source=img, conf=0.25, device=self.device, verbose=False
    )

    detecciones = []
    for result in results:
      if result.boxes is None:
        continue
      for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        conf = float(box.conf[0])
        cls_id = int(box.cls[0])
        char_name = result.names[cls_id]
        detecciones.append((x1, y1, x2, y2, char_name, conf))

    if not detecciones:
      return None, 0

    # Ordenar caracteres de izquierda a derecha
    detecciones.sort(key=lambda d: d[0])
    raw_text = ''.join([d[4] for d in detecciones])

    # Formatear
    clean_text = re.sub(r'[^A-Z0-9]', '', raw_text.upper())
    formatted_text = (
        f'{clean_text[:3]}-{clean_text[3:]}'
        if len(clean_text) == 6
        else clean_text
    )
    avg_conf = sum(d[5] for d in detecciones) / len(detecciones)

    return formatted_text, avg_conf

  async def handle_client(self, websocket):
    logger.info('⚡ Cliente Flutter conectado')

    try:
      async for message in websocket:
        start_time = time.time()
        self.frame_counter += 1

        try:
          data = json.loads(message)
        except Exception:
          logger.warning('⚠️ Mensaje recibido no es un JSON válido')
          continue

        if data.get('type') == 'frame':
          image_b64 = data.get('image')
          if not image_b64:
            logger.warning('⚠️ Frame recibido sin datos de imagen')
            continue

          # Decodificar imagen
          frame = self.decode_frame(image_b64)
          if frame is None:
            logger.warning('⚠️ No se pudo decodificar la imagen recibida')
            continue

          # Procesar con YOLO
          detected_text, conf = self.detect_plate_yolo(frame)
          elapsed = round((time.time() - start_time) * 1000, 1)

          is_valid = self.is_valid_car_plate(detected_text)

          # Log en consola Python de CADA frame recibido
          if detected_text:
            logger.info(
                f'📥 Frame #{self.frame_counter} | Texto:'
                f' "{detected_text}" | Valido: {is_valid} | Conf:'
                f' {conf:.1%} | {elapsed}ms'
            )
          else:
            logger.info(
                f'📥 Frame #{self.frame_counter} | Sin caracteres detectados'
                f' | {elapsed}ms'
            )

          # Responder a Flutter SIEMPRE para actualizar métricas
          response = {
              'type': 'detection',
              'plate': detected_text if is_valid else None,
              'raw_text': detected_text,
              'ocr_conf': round(conf, 3),
              'process_time': elapsed,
          }
          await websocket.send(json.dumps(response))

        elif data.get('type') == 'ping':
          await websocket.send(json.dumps({'type': 'pong'}))

    except websockets.exceptions.ConnectionClosed:
      logger.info('🔌 Cliente desconectado')
    except Exception as e:
      logger.error(f'💥 Error inesperado en el socket: {e}')


async def main():
  server = PlateServer(relative_model_path='runs/exp_nano-5/weights/best.pt')

  # Escuchar en todas las interfaces de red locales
  host = '0.0.0.0'
  port = 8765

  async with websockets.serve(server.handle_client, host, port):
    logger.info('=' * 60)
    logger.info(
        f'🚀 SERVIDOR ACTIVO Y ESCUCHANDO EN ws://localhost:{port} (o la IP de'
        ' tu PC)'
    )
    logger.info('=' * 60)
    await asyncio.Future()


if __name__ == '__main__':
  asyncio.run(main())