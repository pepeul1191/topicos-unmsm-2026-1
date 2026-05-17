# README

This README would normally document whatever steps are necessary to get the
application up and running.

### .env

    # .env
    #### DBMATE
    DB=sqlite:db/app.db
    #### RAILS
    BASE_URL=http://localhost:3000
    STATIC_URL=http://localhost:3000
    USERNAME=admin
    PASSWORD=123
    #### ACCESS SERVICE
    SYSTEM_ID=1
    X_AUTH_ACCESS_SERVICE=dXNlci1zdGlja3lfc2VjcmV0XzEyMzQ1Njc
    URL_ACCESS_SERVICE=http://localhost:8085
    #### FILES SERVICE
    URL_FILES_SERVICE=http://localhost:4000
    X_AUTH_FILES_SERVICE=dXNlci1zdGlja3lfc2VjcmV0XzEyMzQ1Njc
    #### GOOGLE OAUTH
    GOOGLE_CLIENT_ID=your_google_client_id
    GOOGLE_CLIENT_SECRET=your_google_client_secret

### Migraciones con DBMATE

Instalar dependencias:

    $ npm install

Crear migración:

    $ npm run db:new <nombre-migración>

Ejecutar

    $ npm run db:up

Deshacer

    $ npm run db:rollback

Ejemplos de código en Sqlite3

```sql
-- Crear una entidad fuerte
CREATE TABLE paises (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  nombre VARCHAR(40) NOT NULL,
  bandera_url VARCHAR(100) NOT NULL,
  gentilicio VARCHAR(30) NOT NULL
);
-- Crear una entidad debil
CREATE TABLE recurso_coleccion (
  id	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  coleccion_id INTEGER NOT NULL,
  recurso_id INTEGER NOT NULL,
  FOREIGN KEY (coleccion_id) REFERENCES coleccion (id),
  FOREIGN KEY (recurso_id) REFERENCES recurso (id)
);
```
