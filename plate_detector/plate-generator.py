import cv2
import numpy as np
import random
import string
import os


# ==================================================
# Configuración
# ==================================================

NUM_PLACAS = 500

ANCHO_PLACA = 520
ALTO_PLACA = 110

OUTPUT = "synthetic_plates"

IMG_DIR = os.path.join(OUTPUT, "images")
LBL_DIR = os.path.join(OUTPUT, "labels")


os.makedirs(IMG_DIR, exist_ok=True)
os.makedirs(LBL_DIR, exist_ok=True)


# ==================================================
# Clases YOLO
# ==================================================

CLASES = {}

# Letras A-Z
for i, c in enumerate(string.ascii_uppercase):
    CLASES[c] = i

# Números 0-9
for i, c in enumerate(string.digits):
    CLASES[c] = 26 + i

# Guion
CLASES["-"] = 36


NOMBRES_CLASES = list(CLASES.keys())


# ==================================================
# Generar placa peruana
# ==================================================

def generar_codigo():

    letras = ''.join(
        random.choices(
            string.ascii_uppercase,
            k=3
        )
    )

    numeros = ''.join(
        random.choices(
            string.digits,
            k=3
        )
    )

    return f"{letras}-{numeros}"



# ==================================================
# Crear imagen de placa
# ==================================================

def crear_placa(texto):

    img = np.full(
        (ALTO_PLACA, ANCHO_PLACA, 3),
        255,
        dtype=np.uint8
    )


    # borde negro
    cv2.rectangle(
        img,
        (5, 5),
        (ANCHO_PLACA-5, ALTO_PLACA-5),
        (0,0,0),
        4
    )


    fuente = cv2.FONT_HERSHEY_SIMPLEX

    escala = 2.5
    grosor = 5


    x = 45
    y = 75


    posiciones = []


    for char in texto:

        (w,h), baseline = cv2.getTextSize(
            char,
            fuente,
            escala,
            grosor
        )


        cv2.putText(
            img,
            char,
            (x,y),
            fuente,
            escala,
            (0,0,0),
            grosor,
            cv2.LINE_AA
        )


        # bounding box del caracter

        x1 = x
        y1 = y-h

        x2 = x+w
        y2 = y+baseline


        posiciones.append(
            (
                char,
                x1,
                y1,
                x2,
                y2
            )
        )


        x += w + 12


    return img, posiciones



# ==================================================
# Crear etiquetas YOLO
# ==================================================

def crear_labels(posiciones):

    labels=[]


    for char,x1,y1,x2,y2 in posiciones:


        if char not in CLASES:
            continue


        clase=CLASES[char]


        # centro YOLO

        cx=((x1+x2)/2)/ANCHO_PLACA
        cy=((y1+y2)/2)/ALTO_PLACA


        w=(x2-x1)/ANCHO_PLACA
        h=(y2-y1)/ALTO_PLACA


        labels.append(
            f"{clase} {cx:.6f} {cy:.6f} {w:.6f} {h:.6f}"
        )


    return labels



# ==================================================
# Dataset YAML
# ==================================================

def crear_yaml():

    yaml_path = os.path.join(
        OUTPUT,
        "dataset.yaml"
    )


    with open(yaml_path,"w") as f:

        f.write(
f"""
path: {OUTPUT}

train: images
val: images

nc: 37

names:
"""
        )


        for i,c in enumerate(NOMBRES_CLASES):

            f.write(
                f"  {i}: '{c}'\n"
            )


    print(
        f"Dataset YAML creado: {yaml_path}"
    )



# ==================================================
# Generar dataset
# ==================================================

for i in range(NUM_PLACAS):


    texto = generar_codigo()


    imagen, posiciones = crear_placa(
        texto
    )


    # ruido

    if random.random() > 0.5:

        imagen = cv2.GaussianBlur(
            imagen,
            (3,3),
            0
        )


    if random.random() > 0.5:

        ruido = np.random.normal(
            0,
            10,
            imagen.shape
        )

        imagen = np.clip(
            imagen + ruido,
            0,
            255
        ).astype(np.uint8)



    # guardar imagen

    nombre = texto + ".jpg"


    cv2.imwrite(
        os.path.join(
            IMG_DIR,
            nombre
        ),
        imagen
    )



    # guardar labels

    labels = crear_labels(
        posiciones
    )


    with open(
        os.path.join(
            LBL_DIR,
            texto+".txt"
        ),
        "w"
    ) as f:

        f.write(
            "\n".join(labels)
        )


    print(
        f"{i+1}/{NUM_PLACAS}: {texto}"
    )



crear_yaml()


print("\n==============================")
print(" Dataset sintético generado")
print("==============================")