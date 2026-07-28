# Yolo Placas Perú

Este es un proyecto base que integra un backend en **Flask** con un frontend en **Svelte**. Usa `rollup` para compilar los assets y un entorno virtual de Python para aislar las dependencias del backend.

---

## 📦 Requisitos previos

- [Python 3.8+](https://www.python.org/)
- [Node.js y npm](https://nodejs.org/)
- [Git](https://git-scm.com/)

---

## 🐍 Crear entorno virtual (backend)

### En Windows:

    > python -m venv venv
    > venv\Scripts\activate.bat
    > pip install -r requirements.txt

### En Linux:

    $ python3 -m venv venv
    $ source venv\bin\activate
    $ pip install -r requirements.txt

### .env

    #### DBMATE
    DB=sqlite:db/app.db
    #### RAILS
    BASE_URL=http://localhost:3000/
    STATIC_URL=http://localhost:3000/
    USERNAME=admin
    PASSWORD=123

python3 -m http.server 8000

### Generar dataset

    # cd scripts
    $ python3 letras.py

### Ver dataset

    $ python3 visualizar.py