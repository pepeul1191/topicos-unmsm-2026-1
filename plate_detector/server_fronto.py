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
import math
from collections import deque
from enum import Enum

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class PlateFormat(Enum):
    """Enumeración para los formatos de placa peruana"""
    TRADICIONAL = "ABC-123"
    MIXTO = "A1B-234"
    NUMERICO = "123-456"
    INVALIDO = "INVALIDO"

class PlateOnlyServer:
    def __init__(self, yolo_model_path='models/best_upeu_yolo12_100ep.pt'):
        logger.info("🎯 Inicializando detector con validación robusta de placas peruanas...")
        
        self.yolo_model = YOLO(yolo_model_path)
        self.ocr_reader = easyocr.Reader(['es', 'en'], gpu=False)
        
        self.frame_counter = 0
        self.process_every_n_frames = 5
        self.last_plate = None
        self.last_bbox = None
        self.last_confidence = 0
        self.last_angle = 0
        self.is_fronto_parallel = False
        self.last_plate_format = PlateFormat.INVALIDO
        
        # Parámetros de validación fronto-paralela
        self.max_fronto_angle = 25
        self.min_aspect_ratio = 1.5
        self.max_aspect_ratio = 3.5
        self.min_plate_area = 500
        
        # Historial
        self.angle_history = deque(maxlen=5)
        self.plate_history = deque(maxlen=3)
        
        # 🔧 NUEVOS ATRIBUTOS PARA MEJOR ESTABILIDAD
        self.last_update_time = time.time()
        self.max_idle_time = 2.0  # 2 segundos sin actualización
        self.forced_update = False
        self.plate_change_detected = False
        
        # Estadísticas
        self.total_detections = 0
        self.valid_detections = 0
        self.rejected_by_angle = 0
        self.rejected_by_format = 0
        self.corrected_detections = 0
        
        self.format_stats = {
            'tradicional': 0,
            'mixto': 0,
            'numerico': 0,
            'invalidos': 0
        }
        
        # Mapeo de caracteres confusos (OCR) MEJORADO
        self.ocr_confusion_map = {
            'O': '0', 'o': '0',
            'I': '1', 'i': '1',
            'L': '1', 'l': '1',
            'S': '5', 's': '5',
            'Z': '2', 'z': '2',
            'B': '8', 'b': '8',
            'G': '6', 'g': '6',
            'T': '7', 't': '7',
            'A': '4',
            'E': '3',
            'J': 'A',  # 🔧 NUEVO: OCR confunde A con J
            'j': 'A',  # 🔧 NUEVO: Versión minúscula
        }
        
        logger.info("✅ Modo: Validación robusta con corrección de OCR")
        logger.info(f"📐 Ángulo máximo permitido: {self.max_fronto_angle}°")
        logger.info("📋 Formatos aceptados:")
        logger.info("   • ABC-123 (Tradicional)")
        logger.info("   • A1B-234 (Mixto)")
        logger.info("   • 123-456 (Numérico)")
        logger.info("🔧 Correcciones OCR mejoradas:")
        logger.info("  • J → A (nuevo)")
    
    def decode_frame(self, frame_data):
        """Decodifica frame de base64"""
        frame_bytes = base64.b64decode(frame_data)
        nparr = np.frombuffer(frame_bytes, np.uint8)
        return cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    def encode_frame(self, img, quality=60):
        """Codifica frame a base64"""
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, quality])
        return base64.b64encode(buffer).decode('utf-8')
    
    def resize_for_speed(self, img, max_size=480):
        """Redimensiona para velocidad"""
        h, w = img.shape[:2]
        if max(h, w) > max_size:
            scale = max_size / max(h, w)
            new_w = int(w * scale)
            new_h = int(h * scale)
            return cv2.resize(img, (new_w, new_h))
        return img
    
    def convert_ocr_bbox_to_rectangle(self, ocr_bbox):
        """Convierte bbox de OCR (4 puntos) a rectángulo"""
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
        """Filtra solo texto grande (el de la placa)"""
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
    
    def generate_possible_plates(self, first_part, second_part):
        """
        Genera posibles combinaciones de placas
        """
        possibilities = []
        
        # Mapeo de números a letras posibles MEJORADO
        num_to_letters = {
            '4': ['A', '4'],
            '3': ['E', '3'],
            '1': ['I', '1', 'L'],
            'I': ['1', '1', 'J'],
            '0': ['O', '0'],
            '5': ['S', '5'],
            '8': ['B', '8'],
            'B': '8', 'b': '8',  # 🔧 B → 8
            '6': ['G', '6'],
            '7': ['T', '7'],
            '2': ['Z', '2'],
            '9': ['9'],
            'J': ['A', 'J'],  # 🔧 NUEVO: J puede ser A
            'A': ['A', 'J'],  # 🔧 NUEVO: A puede ser J
        }
        
        # Generar combinaciones para la primera parte
        import itertools
        
        char_options = []
        for char in first_part:
            if char in num_to_letters:
                char_options.append(num_to_letters[char])
            else:
                char_options.append([char])
        
        # Generar todas las combinaciones
        for combo in itertools.product(*char_options):
            possible_first = ''.join(combo)
            possible_plate = f"{possible_first}-{second_part}"
            # 🔧 CORREGIDO: Desempaquetar 4 valores
            is_valid, formatted, ftype, _ = self.validate_plate_format(possible_plate, silent=True)
            if is_valid:
                possibilities.append(formatted)
        
        return possibilities
    
    def correct_mixed_plate(self, first_part, second_part):
        """
        Corrige placas mixtas mal leídas
        """
        corrections = []
        
        # Si la primera parte son todos números, intentar convertir
        if first_part.isdigit():
            # Posibles combinaciones con una letra
            for i in range(3):
                for letter in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']:
                    test = list(first_part)
                    test[i] = letter
                    test_plate = f"{''.join(test)}-{second_part}"
                    # 🔧 CORREGIDO: Desempaquetar 4 valores
                    is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                    if is_valid:
                        corrections.append(formatted)
        
        return corrections[0] if corrections else None
    
    def correct_ocr_text(self, text):
        """
        CORRIGE ERRORES COMUNES DE OCR
        Incluye corrección 8 ↔ B
        """
        if not text:
            return text
        
        # Limpiar
        clean = re.sub(r'[^A-Z0-9-]', '', text.upper().strip())
        
        # 🔧 APLICAR MAPA DE CONFUSIONES
        for wrong, correct in self.ocr_confusion_map.items():
            clean = clean.replace(wrong, correct)
        
        # Si ya tiene guión, separar
        if '-' in clean:
            parts = clean.split('-')
            if len(parts) == 2:
                first_part = parts[0]
                second_part = parts[1]
            else:
                return clean
        else:
            # Sin guión, asumir que son 6 caracteres
            if len(clean) >= 6:
                first_part = clean[:3]
                second_part = clean[3:6]
            else:
                return clean
        
        # 🔧 CORRECCIÓN ESPECÍFICA PARA '8' ↔ 'B'
        # Si la primera parte tiene '8' y debería ser 'B' (formato tradicional)
        if '8' in first_part:
            # Probar reemplazar 8 por B
            test_plates = []
            
            # Opción 1: Reemplazar todos los 8 por B
            candidate1 = first_part.replace('8', 'B')
            test_plates.append((candidate1, "8→B todas"))
            
            # Opción 2: Reemplazar solo algunos 8 por B
            for i, char in enumerate(first_part):
                if char == '8':
                    candidate2 = first_part[:i] + 'B' + first_part[i+1:]
                    test_plates.append((candidate2, f"8→B en posición {i}"))
            
            # Verificar cuál es válido
            for candidate, method in test_plates:
                test_plate = f"{candidate}-{second_part}"
                is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                if is_valid:
                    self.corrected_detections += 1
                    logger.info(f"🔧 CORREGIDO: '{first_part}-{second_part}' → '{formatted}' (método: {method})")
                    return formatted
        
        # 🔧 Si la segunda parte tiene 'B' y debería ser '8' (formato numérico)
        if 'B' in second_part:
            # Probar reemplazar B por 8
            for i, char in enumerate(second_part):
                if char == 'B':
                    candidate = second_part[:i] + '8' + second_part[i+1:]
                    test_plate = f"{first_part}-{candidate}"
                    is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                    if is_valid:
                        self.corrected_detections += 1
                        logger.info(f"🔧 CORREGIDO: '{first_part}-{second_part}' → '{formatted}' (B→8 en posición {i})")
                        return formatted
        
        # Si la placa es mixta pero tiene números/letras confusos
        if len(first_part) == 3 and len(second_part) == 3:
            has_letter = any(c.isalpha() for c in first_part)
            has_number = any(c.isdigit() for c in first_part)
            
            if has_number and not has_letter:
                corrected = self.correct_mixed_plate(first_part, second_part)
                if corrected:
                    return corrected
        
        return f"{first_part}-{second_part}"
        
    def extract_plate_text(self, img):
        """
        Extrae el texto de la placa con corrección de OCR
        Maneja confusiones comunes: 8↔B, J↔A, etc.
        """
        h, w = img.shape[:2]
        small_img = self.resize_for_speed(img, 640)
        scale_x = w / small_img.shape[1]
        scale_y = h / small_img.shape[0]
        
        # Preprocesamiento de imagen
        gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(4,4))
        enhanced = clahe.apply(gray)
        _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Múltiples intentos de OCR con diferentes preprocesamientos
        results = self.ocr_reader.readtext(
            binary,
            allowlist='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-',
            paragraph=False,
            detail=1
        )
        
        # Si no hay resultados, intentar con la imagen original
        if not results:
            results = self.ocr_reader.readtext(
                small_img,
                allowlist='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-',
                paragraph=False,
                detail=1
            )
        
        large_texts = self.filter_large_text(results, min_height=25)
        
        if large_texts:
            # Seleccionar el mejor resultado por altura
            best = max(large_texts, key=lambda x: x[3])
            bbox_rect, text, confidence, height = best
            
            # Escalar coordenadas al tamaño original
            x1, y1, x2, y2 = bbox_rect
            x1 = int(x1 * scale_x)
            y1 = int(y1 * scale_y)
            x2 = int(x2 * scale_x)
            y2 = int(y2 * scale_y)
            
            # CORREGIR EL TEXTO DEL OCR
            corrected_text = self.correct_ocr_text(text)
            
            # 🔧 VERIFICACIÓN FINAL: 8 ↔ B
            # Esta verificación captura casos que el corrector principal no manejó
            if '-' in corrected_text:
                parts = corrected_text.split('-')
                if len(parts) == 2:
                    first_part = parts[0]
                    second_part = parts[1]
                    
                    # 🔧 CASO 1: Primera parte tiene '8' (debería ser 'B' para formato tradicional)
                    if '8' in first_part and second_part.isdigit():
                        # Probar reemplazando 8 por B en diferentes posiciones
                        test_plates = []
                        
                        # Opción: Reemplazar todos los 8 por B
                        test_plates.append(first_part.replace('8', 'B'))
                        
                        # Opción: Reemplazar 8 por B individualmente
                        for i, char in enumerate(first_part):
                            if char == '8':
                                test_plates.append(first_part[:i] + 'B' + first_part[i+1:])
                        
                        # Probar cada opción
                        for test_first in test_plates:
                            test_plate = f"{test_first}-{second_part}"
                            is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                            if is_valid:
                                corrected_text = formatted
                                self.corrected_detections += 1
                                logger.info(f"🔧 CORREGIDO FORZADO (8→B): '{text}' → '{formatted}'")
                                break
                    
                    # 🔧 CASO 2: Segunda parte tiene 'B' (debería ser '8' para formato numérico)
                    elif 'B' in second_part and first_part.isalpha():
                        # Probar reemplazando B por 8 en diferentes posiciones
                        test_plates = []
                        
                        # Opción: Reemplazar todos los B por 8
                        test_plates.append(second_part.replace('B', '8'))
                        
                        # Opción: Reemplazar B por 8 individualmente
                        for i, char in enumerate(second_part):
                            if char == 'B':
                                test_plates.append(second_part[:i] + '8' + second_part[i+1:])
                        
                        # Probar cada opción
                        for test_second in test_plates:
                            test_plate = f"{first_part}-{test_second}"
                            is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                            if is_valid:
                                corrected_text = formatted
                                self.corrected_detections += 1
                                logger.info(f"🔧 CORREGIDO FORZADO (B→8): '{text}' → '{formatted}'")
                                break
                    
                    # 🔧 CASO 3: Primera parte tiene 'B' y segunda es numérica (formato mixto)
                    elif 'B' in first_part and second_part.isdigit():
                        # Si la primera parte tiene B y es mixta, mantener B (es correcto)
                        # Solo verificar si el formato es válido
                        is_valid, formatted, ftype, _ = self.validate_plate_format(corrected_text, silent=True)
                        if is_valid:
                            corrected_text = formatted
            
            # 🔧 VERIFICACIÓN FINAL: J ↔ A
            if 'J' in corrected_text:
                # Probar reemplazando J por A
                test_text = corrected_text.replace('J', 'A')
                is_valid, formatted, ftype, _ = self.validate_plate_format(test_text, silent=True)
                if is_valid:
                    corrected_text = formatted
                    self.corrected_detections += 1
                    logger.info(f"🔧 CORREGIDO FORZADO (J→A): '{text}' → '{formatted}'")
            
            # 🔧 VERIFICACIÓN FINAL: Números en la primera parte que deberían ser letras
            if '-' in corrected_text:
                parts = corrected_text.split('-')
                if len(parts) == 2:
                    first_part = parts[0]
                    second_part = parts[1]
                    
                    # Si la primera parte tiene números pero no es formato numérico
                    if any(c.isdigit() for c in first_part) and not first_part.isdigit():
                        # Intentar convertir números a letras
                        num_to_letter = {
                            '4': 'A', '3': 'E', '1': 'I', 
                            '0': 'O', '5': 'S', '2': 'Z',
                            '6': 'G', '7': 'T', '8': 'B', '9': 'P'
                        }
                        
                        test_first = first_part
                        for num, letter in num_to_letter.items():
                            if num in test_first:
                                test_first = test_first.replace(num, letter)
                        
                        test_plate = f"{test_first}-{second_part}"
                        is_valid, formatted, ftype, _ = self.validate_plate_format(test_plate, silent=True)
                        if is_valid:
                            corrected_text = formatted
                            self.corrected_detections += 1
                            logger.info(f"🔧 CORREGIDO FORZADO (número→letra): '{text}' → '{formatted}'")
            
            # Retornar resultados
            if len(corrected_text) == 7 and '-' in corrected_text:
                return corrected_text, [x1, y1, x2, y2], confidence
            elif len(corrected_text) == 6:
                corrected_text = f"{corrected_text[:3]}-{corrected_text[3:]}"
                return corrected_text, [x1, y1, x2, y2], confidence
        
        # Si no se detectó nada
        return None, None, None

    def detect_with_yolo(self, img):
        """Usa YOLO para encontrar la ubicación de la placa"""
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
    
    def calculate_bbox_angle(self, bbox):
        """Calcula el ángulo de inclinación del bbox"""
        if not bbox or len(bbox) != 4:
            return 0
        
        x1, y1, x2, y2 = bbox
        width = abs(x2 - x1)
        height = abs(y2 - y1)
        
        if width == 0 or height == 0:
            return 0
        
        aspect_ratio = width / height
        ideal_ratio = 2.0
        ratio_deviation = abs(aspect_ratio - ideal_ratio) / ideal_ratio
        
        angle = math.degrees(math.atan(ratio_deviation * 1.2))
        angle = min(angle, 45)
        
        return angle
    
    def calculate_angle_from_corners(self, bbox):
        """Calcula el ángulo usando las esquinas del rectángulo"""
        if not bbox or len(bbox) != 4:
            return 0
        
        x1, y1, x2, y2 = bbox
        dx = x2 - x1
        dy = y2 - y1
        
        if dx == 0:
            return 0
        
        angle_rad = math.atan2(abs(dy), abs(dx))
        angle_deg = math.degrees(angle_rad)
        
        if angle_deg > 45:
            angle_deg = 90 - angle_deg
        
        return angle_deg
    
    def validate_fronto_parallel(self, bbox, img_shape=None):
        """Validación robusta fronto-paralela con múltiples criterios"""
        if not bbox or len(bbox) != 4:
            return False, 0, "Bbox inválido"
        
        x1, y1, x2, y2 = bbox
        width = abs(x2 - x1)
        height = abs(y2 - y1)
        area = width * height
        
        if area < self.min_plate_area:
            return False, 0, f"Área muy pequeña: {area}px²"
        
        if height > 0:
            aspect_ratio = width / height
            if aspect_ratio < self.min_aspect_ratio or aspect_ratio > self.max_aspect_ratio:
                return False, 0, f"Relación incorrecta: {aspect_ratio:.2f}"
        else:
            return False, 0, "Altura cero"
        
        angle1 = self.calculate_bbox_angle(bbox)
        angle2 = self.calculate_angle_from_corners(bbox)
        angle = (angle1 + angle2) / 2
        
        is_valid = angle <= self.max_fronto_angle
        
        return is_valid, angle, f"OK (ángulo: {angle:.1f}°)"
    
    def smooth_angle(self, angle):
        """Suaviza el ángulo usando historial"""
        self.angle_history.append(angle)
        
        if len(self.angle_history) < 3:
            return angle
        
        weights = np.linspace(1, 2, len(self.angle_history))
        weighted_avg = np.average(self.angle_history, weights=weights)
        
        return weighted_avg
    
    def is_plate_stable(self, plate_text):
        """
        Verifica si la placa es estable MEJORADO
        Resetea historial cuando cambia la placa
        """
        # Si no hay placa anterior, es la primera detección
        if self.last_plate is None:
            self.plate_history.append(plate_text)
            # Necesita al menos 2 confirmaciones
            return len(self.plate_history) >= 2
        
        # Si es la misma placa
        if plate_text == self.last_plate:
            self.plate_history.append(plate_text)
            # Mantener solo últimos 3
            if len(self.plate_history) > 3:
                self.plate_history.popleft()
            
            # Verificar que la mayoría sean la misma
            unique_plates = set(self.plate_history)
            if len(unique_plates) == 1:
                self.last_update_time = time.time()
                return True  # Todas iguales
            elif len(unique_plates) == 2:
                # Contar ocurrencias
                count = self.plate_history.count(plate_text)
                return count >= 2  # Mayoría
            else:
                return False
        
        # Es una placa DIFERENTE
        else:
            # RESETEAR HISTORIAL PARA NUEVA PLACA
            self.plate_history.clear()
            self.plate_history.append(plate_text)
            
            # Si ha pasado mucho tiempo sin actualización, forzar cambio
            if time.time() - self.last_update_time > self.max_idle_time:
                self.forced_update = True
                self.last_update_time = time.time()
                return True
            
            self.plate_change_detected = True
            return False
    
    def validate_plate_format(self, plate_text, silent=False):
        """
        VALIDACIÓN MEJORADA con soporte para formato mixto
        """
        if not silent:
            print(f"\n🔍 VALIDANDO FORMATO: '{plate_text}'")
        
        if not plate_text:
            if not silent:
                print("❌ Error: Texto vacío")
            return False, "", PlateFormat.INVALIDO, ["Texto vacío"]
        
        # Limpieza robusta
        clean = re.sub(r'[^A-Z0-9]', '', plate_text.upper().strip())
        
        if not silent:
            print(f"📝 Limpio: '{clean}'")
        
        # Verificar longitud
        if len(clean) != 6:
            if not silent:
                print(f"❌ Error: Longitud {len(clean)} (debe ser 6)")
            return False, "", PlateFormat.INVALIDO, [f"Longitud incorrecta: {len(clean)}"]
        
        first_part = clean[:3]
        second_part = clean[3:]
        
        if not silent:
            print(f"📌 Primera parte: '{first_part}'")
            print(f"📌 Segunda parte: '{second_part}'")
        
        # Validar últimos 3 son números
        if not second_part.isdigit():
            if not silent:
                print(f"❌ Error: Últimos 3 no son números: '{second_part}'")
            return False, "", PlateFormat.INVALIDO, ["Últimos 3 caracteres deben ser números"]
        
        formatted_plate = f"{first_part}-{second_part}"
        
        if not silent:
            print(f"📋 Formateada: '{formatted_plate}'")
        
        # Determinar formato
        # TRADICIONAL: 3 letras
        if first_part.isalpha():
            if not silent:
                print("✅ Formato TRADICIONAL (ABC-123)")
            return True, formatted_plate, PlateFormat.TRADICIONAL, []
        
        # NUMERICO: 3 números
        elif first_part.isdigit():
            if not silent:
                print("✅ Formato NUMERICO (123-456)")
            return True, formatted_plate, PlateFormat.NUMERICO, []
        
        # MIXTO: combinación de letras y números
        else:
            has_letter = any(c.isalpha() for c in first_part)
            has_number = any(c.isdigit() for c in first_part)
            
            if not silent:
                print(f"🔢 Tiene letras: {has_letter}, Tiene números: {has_number}")
            
            if has_letter and has_number:
                if not silent:
                    print("✅ Formato MIXTO (A1B-234)")
                return True, formatted_plate, PlateFormat.MIXTO, []
            else:
                if not silent:
                    print(f"❌ Error: Formato mixto inválido: '{first_part}'")
                return False, "", PlateFormat.INVALIDO, [f"Formato mixto inválido: {first_part}"]
    
    def process_frame(self, img):
        """Procesa un frame con validación robusta y corrección de OCR"""
        self.frame_counter += 1
        annotated = img.copy()
        
        should_process = (self.frame_counter % self.process_every_n_frames == 0)
        
        if should_process:
            print("\n" + "🔄"*20)
            print(f"📸 PROCESANDO FRAME #{self.frame_counter}")
            print("🔄"*20)
            
            # Intentar OCR
            plate_text, ocr_bbox, ocr_conf = self.extract_plate_text(img)
            
            print(f"📝 OCR detectó: '{plate_text}'")
            print(f"📍 BBox: {ocr_bbox}")
            print(f"📊 Confianza: {ocr_conf}")
            
            if plate_text and ocr_bbox:
                print("✅ OCR encontró texto y bbox")
                self.total_detections += 1
                
                # Validación fronto-paralela
                is_valid, angle, reason = self.validate_fronto_parallel(ocr_bbox, img.shape)
                smoothed_angle = self.smooth_angle(angle)
                
                print(f"📐 Ángulo: {smoothed_angle:.1f}°")
                print(f"✅ Frontoparalelo: {is_valid}")
                
                if is_valid and smoothed_angle <= self.max_fronto_angle:
                    print("✅ Ángulo válido")
                    
                    # VALIDAR FORMATO DE PLACA (con el texto ya corregido)
                    is_format_valid, formatted_plate, format_type, errors = self.validate_plate_format(plate_text)
                    
                    if is_format_valid:
                        print(f"✅ Formato válido: {formatted_plate} ({format_type.value})")
                        
                        # 🔧 VERIFICAR ESTABILIDAD MEJORADA
                        is_stable = self.is_plate_stable(formatted_plate)
                        
                        # 🔧 FORZAR ACTUALIZACIÓN SI ES NECESARIO
                        if is_stable or self.forced_update:
                            if self.forced_update:
                                logger.info(f"🔄 ACTUALIZACIÓN FORZADA POR TIEMPO: {formatted_plate}")
                                self.forced_update = False
                            
                            # Actualizar todo
                            self.last_plate = formatted_plate
                            self.last_bbox = ocr_bbox
                            self.last_confidence = ocr_conf
                            self.last_angle = smoothed_angle
                            self.is_fronto_parallel = True
                            self.last_plate_format = format_type
                            self.valid_detections += 1
                            self.last_update_time = time.time()
                            
                            # Actualizar estadísticas
                            if format_type == PlateFormat.TRADICIONAL:
                                self.format_stats['tradicional'] += 1
                            elif format_type == PlateFormat.MIXTO:
                                self.format_stats['mixto'] += 1
                            elif format_type == PlateFormat.NUMERICO:
                                self.format_stats['numerico'] += 1
                            
                            logger.info(f"✅ PLACA VÁLIDA: {formatted_plate}")
                            logger.info(f"   Formato: {format_type.value}")
                            logger.info(f"   Confianza: {ocr_conf:.2%}")
                            logger.info(f"   Ángulo: {smoothed_angle:.1f}°")
                            if self.corrected_detections > 0:
                                logger.info(f"   Correcciones OCR: {self.corrected_detections}")
                        else:
                            print("⚠️ Placa inestable - esperando confirmación")
                            if self.plate_change_detected:
                                print("🔄 Nueva placa detectada, resetando historial...")
                                self.plate_change_detected = False
                    else:
                        print(f"❌ FORMATO INVÁLIDO: {plate_text}")
                        for error in errors:
                            print(f"   • {error}")
                        self.rejected_by_format += 1
                        self.format_stats['invalidos'] += 1
                else:
                    print(f"❌ Ángulo inválido: {smoothed_angle:.1f}° > {self.max_fronto_angle}°")
                    self.rejected_by_angle += 1
            else:
                print("❌ No se detectó texto o bbox")
                # Fallback con YOLO
                yolo_box, yolo_conf = self.detect_with_yolo(img)
                if yolo_box:
                    print(f"📍 YOLO detectó ubicación: {yolo_box}")
                    is_valid, angle, reason = self.validate_fronto_parallel(yolo_box, img.shape)
                    smoothed_angle = self.smooth_angle(angle)
                    
                    if is_valid and smoothed_angle <= self.max_fronto_angle:
                        self.last_bbox = yolo_box
                        self.last_confidence = yolo_conf
                        self.last_angle = smoothed_angle
                        self.is_fronto_parallel = True
                        logger.info(f"📍 Ubicación YOLO válida (ángulo: {smoothed_angle:.1f}°)")
        
        # Dibujar resultado
        if self.last_bbox:
            x1, y1, x2, y2 = self.last_bbox
            if all(isinstance(v, int) for v in [x1, y1, x2, y2]):
                format_colors = {
                    PlateFormat.TRADICIONAL: (0, 255, 0),
                    PlateFormat.MIXTO: (255, 165, 0),
                    PlateFormat.NUMERICO: (0, 165, 255),
                    PlateFormat.INVALIDO: (0, 0, 255)
                }
                
                color = format_colors.get(self.last_plate_format, (0, 0, 255))
                
                cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 3)
                
                if self.last_plate:
                    format_name = self.last_plate_format.value if self.last_plate_format != PlateFormat.INVALIDO else "Inválido"
                    info_text = f"{self.last_plate} [{format_name}] {self.last_confidence:.2%}"
                    cv2.putText(annotated, info_text, 
                               (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
                    
                    angle_text = f"Ángulo: {self.last_angle:.1f}°"
                    cv2.putText(annotated, angle_text, 
                               (x1, y2+20), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
                    
                    # Mostrar si fue corregido
                    if self.corrected_detections > 0:
                        cv2.putText(annotated, f"🔧 Corregido: {self.corrected_detections}", 
                                   (x1, y2+45), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)
                else:
                    cv2.putText(annotated, "Leyendo placa...", (x1, y1-10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        else:
            cv2.putText(annotated, "🔍 Coloca la placa frente a la cámara", 
                       (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
        
        # Mostrar estadísticas
        self.draw_stats(annotated)
        
        return annotated
    
    def draw_stats(self, img):
        """Dibuja estadísticas en la imagen"""
        stats_y = 70
        stats_x = 10
        
        overlay = img.copy()
        cv2.rectangle(overlay, (stats_x, stats_y), (stats_x + 320, stats_y + 140), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.5, img, 0.5, 0, img)
        
        stats_text = [
            f"Total: {self.total_detections}",
            f"Válidas: {self.valid_detections}",
            f"Rechazadas (ángulo): {self.rejected_by_angle}",
            f"Rechazadas (formato): {self.rejected_by_format}",
            f"Corregidas OCR: {self.corrected_detections}",
            f"Tasa: {self.valid_detections / max(1, self.total_detections):.1%}"
        ]
        
        for i, text in enumerate(stats_text):
            cv2.putText(img, text, (stats_x + 10, stats_y + 20 + i * 18),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)
        
        # Estadísticas de formatos
        format_y = stats_y + 20
        format_x = stats_x + 180
        
        format_text = [
            f"Trad: {self.format_stats['tradicional']}",
            f"Mix: {self.format_stats['mixto']}",
            f"Num: {self.format_stats['numerico']}",
            f"Inv: {self.format_stats['invalidos']}"
        ]
        
        for i, text in enumerate(format_text):
            cv2.putText(img, text, (format_x + 10, format_y + i * 18),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)
    
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
                        
                        response = {
                            'type': 'detection',
                            'plate': None,
                            'ocr_conf': 0,
                            'fronto_angle': 0,
                            'is_fronto_parallel': False,
                            'plate_format': None,
                            'format_name': None,
                            'corrected': False,
                            'corrections_count': self.corrected_detections,
                            'process_time': round((time.time() - start) * 1000, 1),
                            'stats': {
                                'total_detections': self.total_detections,
                                'valid_detections': self.valid_detections,
                                'rejected_by_angle': self.rejected_by_angle,
                                'rejected_by_format': self.rejected_by_format,
                                'corrected_detections': self.corrected_detections,
                                'formats': self.format_stats
                            }
                        }
                        
                        if self.last_plate and self.is_fronto_parallel:
                            response['plate'] = self.last_plate
                            response['ocr_conf'] = round(self.last_confidence, 3)
                            response['fronto_angle'] = round(self.last_angle, 1)
                            response['is_fronto_parallel'] = True
                            response['plate_format'] = self.last_plate_format.value if self.last_plate_format else None
                            response['format_name'] = self.last_plate_format.name if self.last_plate_format else None
                            
                            logger.info(f"📤 Enviando: {self.last_plate} ({self.last_plate_format.value})")
                            await websocket.send(json.dumps(response))
                        else:
                            await websocket.send(json.dumps(response))
                        
                    elif data['type'] == 'ping':
                        await websocket.send(json.dumps({
                            'type': 'pong',
                            'timestamp': time.time()
                        }))
                        
                except Exception as e:
                    logger.error(f"Error procesando mensaje: {e}")
                    import traceback
                    traceback.print_exc()
                    
        except websockets.exceptions.ConnectionClosed:
            logger.info("Cliente desconectado")
        except Exception as e:
            logger.error(f"Error en handle_client: {e}")

async def main():
    server = PlateOnlyServer(yolo_model_path='models/best_upeu_yolo12_100ep.pt')
    
    host = "192.168.1.23"
    port = 8765
    
    async with websockets.serve(server.handle_client, host, port):
        logger.info("=" * 60)
        logger.info("🚗 SERVIDOR CON CORRECCIÓN DE OCR MEJORADO")
        logger.info("=" * 60)
        logger.info(f"📡 Servidor en: ws://{host}:{port}")
        logger.info(f"📐 Ángulo máximo: {server.max_fronto_angle}°")
        logger.info("=" * 60)
        logger.info("✅ Correcciones automáticas:")
        logger.info("  • 4 → A")
        logger.info("  • 3 → E")
        logger.info("  • 1 → I/L")
        logger.info("  • 0 → O")
        logger.info("  • 5 → S")
        logger.info("  • 8 → B")
        logger.info("  • 6 → G")
        logger.info("  • 7 → T")
        logger.info("  • 2 → Z")
        logger.info("  • J → A 🔧 NUEVO")
        logger.info("=" * 60)
        logger.info("🔄 Estabilidad mejorada:")
        logger.info("  • Reset automático al cambiar placa")
        logger.info("  • Forzado por tiempo (2s sin actualización)")
        logger.info("=" * 60)
        
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 Servidor detenido por el usuario")
    except Exception as e:
        logger.error(f"Error fatal: {e}")