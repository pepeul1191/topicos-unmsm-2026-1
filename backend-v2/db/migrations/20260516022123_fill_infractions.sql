-- migrate:up

INSERT INTO infractions (id, description, car_id, created) VALUES
(1, 'Exceso de velocidad en zona urbana', 1, '2026-01-05 08:15:00'),
(2, 'Estacionamiento en zona prohibida', 1, '2026-02-12 11:30:00'),
(3, 'No respetar luz roja del semáforo', 2, '2026-01-18 19:45:00'),
(4, 'Circular sin SOAT vigente', 2, '2026-03-01 10:20:00'),
(5, 'Uso indebido de claxon', 3, '2026-01-22 14:05:00'),
(6, 'Conducir usando teléfono móvil', 3, '2026-02-14 17:50:00'),
(7, 'Exceso de velocidad en carretera', 4, '2026-01-30 09:10:00'),
(8, 'No portar licencia de conducir', 4, '2026-03-06 13:25:00'),
(9, 'Giro indebido en intersección', 5, '2026-02-03 16:40:00'),
(10, 'Vehículo mal estacionado', 5, '2026-03-11 08:55:00'),
(11, 'No respetar señal de pare', 6, '2026-01-16 12:35:00'),
(12, 'Circular con luces apagadas', 6, '2026-02-28 20:10:00'),
(13, 'Exceso de velocidad en avenida', 7, '2026-01-25 07:45:00'),
(14, 'Falta de revisión técnica', 7, '2026-03-08 15:15:00'),
(15, 'Invadir carril exclusivo', 8, '2026-02-01 18:20:00'),
(16, 'No usar cinturón de seguridad', 8, '2026-03-17 09:05:00'),
(17, 'Circular en sentido contrario', 9, '2026-01-29 21:30:00'),
(18, 'Obstrucción de vía pública', 9, '2026-03-21 11:40:00'),
(19, 'Conducir con documentos vencidos', 10, '2026-02-07 10:50:00'),
(20, 'Exceso de velocidad en zona escolar', 10, '2026-03-25 13:15:00');

-- migrate:down

DELETE FROM infractions;