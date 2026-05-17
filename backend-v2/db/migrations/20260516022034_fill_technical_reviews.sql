-- migrate:up

INSERT INTO technical_reviews (id, description, car_id, created) VALUES
(1, 'Cambio de aceite y filtros realizado correctamente', 1, '2026-01-10 09:30:00'),
(2, 'Revisión de frenos delanteros y traseros', 1, '2026-02-15 14:10:00'),
(3, 'Alineamiento y balanceo completado', 2, '2026-01-18 11:00:00'),
(4, 'Cambio de batería por desgaste', 2, '2026-03-01 16:45:00'),
(5, 'Inspección general de motor sin observaciones', 3, '2026-01-22 08:20:00'),
(6, 'Reemplazo de neumáticos delanteros', 3, '2026-02-11 10:15:00'),
(7, 'Sistema eléctrico revisado y operativo', 4, '2026-02-05 13:00:00'),
(8, 'Cambio de pastillas de freno', 4, '2026-03-07 15:35:00'),
(9, 'Mantenimiento preventivo de 10,000 km', 5, '2026-01-30 09:50:00'),
(10, 'Revisión de suspensión y amortiguadores', 5, '2026-03-12 12:40:00'),
(11, 'Cambio de aceite de transmisión', 6, '2026-02-02 10:10:00'),
(12, 'Corrección de luces delanteras', 6, '2026-03-18 17:20:00'),
(13, 'Diagnóstico electrónico realizado', 7, '2026-01-14 11:45:00'),
(14, 'Limpieza de inyectores completada', 7, '2026-02-25 14:55:00'),
(15, 'Revisión técnica aprobada', 8, '2026-01-27 08:40:00'),
(16, 'Cambio de correa de distribución', 8, '2026-03-09 16:05:00'),
(17, 'Sistema de aire acondicionado reparado', 9, '2026-02-08 09:15:00'),
(18, 'Cambio de líquido de frenos', 9, '2026-03-20 13:30:00'),
(19, 'Mantenimiento completo de motor', 10, '2026-01-19 10:25:00'),
(20, 'Revisión de caja de cambios sin fallas', 10, '2026-03-28 15:10:00');

-- migrate:down

DELETE FROM technical_reviews;