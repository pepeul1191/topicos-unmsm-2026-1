-- migrate:up

INSERT INTO cars (id, owner, branch, model, color, frabricated, plate) VALUES
(1, 'Carlos Mendoza', 'Toyota', 'Corolla', 'Blanco', 2018, 'ABC-123'),
(2, 'Luis Ramirez', 'Hyundai', 'Elantra', 'Negro', 2020, 'BCD-234'),
(3, 'Ana Torres', 'Kia', 'Rio', 'Rojo', 2019, 'CDE-345'),
(4, 'Miguel Castro', 'Chevrolet', 'Spark', 'Azul', 2017, 'DEF-456'),
(5, 'Jorge Salas', 'Nissan', 'Sentra', 'Gris', 2021, 'EFG-567'),
(6, 'Patricia León', 'Mazda', 'CX5', 'Blanco', 2022, 'FGH-678'),
(7, 'Fernando Ruiz', 'Suzuki', 'Swift', 'Verde', 2016, 'GHI-789'),
(8, 'Daniela Flores', 'Volkswagen', 'Polo', 'Negro', 2018, 'HIJ-890'),
(9, 'Ricardo Vega', 'Ford', 'Focus', 'Azul', 2015, 'IJK-901'),
(10, 'María Paredes', 'Honda', 'Civic', 'Rojo', 2020, 'JKL-012');

-- migrate:down

DELETE FROM cars;