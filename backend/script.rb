require "json"
require "leveldb"

db = LevelDB::DB.new("./db")

vehiculos = {
  "A1B-234" => {
    color: "Rojo",
    marca: "Toyota",
    modelo: "Corolla",
    anio: 2020
  },

  "C3D-567" => {
    color: "Negro",
    marca: "Honda",
    modelo: "Civic",
    anio: 2019
  },

  "E5F-890" => {
    color: "Blanco",
    marca: "Hyundai",
    modelo: "Elantra",
    anio: 2021
  },

  "G7H-123" => {
    color: "Azul",
    marca: "Kia",
    modelo: "Rio",
    anio: 2018
  },

  "J9K-456" => {
    color: "Gris",
    marca: "Mazda",
    modelo: "Mazda 3",
    anio: 2022
  },

  "L2M-789" => {
    color: "Verde",
    marca: "Nissan",
    modelo: "Sentra",
    anio: 2017
  },

  "N4P-321" => {
    color: "Plateado",
    marca: "Chevrolet",
    modelo: "Onix",
    anio: 2020
  },

  "Q6R-654" => {
    color: "Amarillo",
    marca: "Ford",
    modelo: "Focus",
    anio: 2016
  },

  "S8T-987" => {
    color: "Celeste",
    marca: "Volkswagen",
    modelo: "Gol",
    anio: 2015
  },

  "U1V-111" => {
    color: "Marrón",
    marca: "Subaru",
    modelo: "Impreza",
    anio: 2023
  }
}

vehiculos.each do |placa, datos|
  db.put(placa, JSON.generate(datos))
  puts "Guardado: #{placa}"
end

puts "Datos insertados correctamente."