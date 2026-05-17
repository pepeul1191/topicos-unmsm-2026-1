-- migrate:up

INSERT INTO complains (id, description, car_id, created) VALUES
(1, 'Ruido excesivo del motor durante la noche', 1, '2026-01-04 22:15:00'),
(2, 'Vehículo bloqueando entrada de cochera', 1, '2026-02-09 07:40:00'),
(3, 'Conducción agresiva en avenida principal', 2, '2026-01-13 18:25:00'),
(4, 'Emisión excesiva de humo del escape', 2, '2026-03-02 09:10:00'),
(5, 'Uso constante de claxon en zona residencial', 3, '2026-01-20 06:55:00'),
(6, 'Vehículo estacionado sobre la vereda', 3, '2026-02-16 14:35:00'),
(7, 'Fugas de aceite en estacionamiento público', 4, '2026-01-29 11:45:00'),
(8, 'Música a volumen alto en la madrugada', 4, '2026-03-05 01:20:00'),
(9, 'Conducción temeraria cerca de colegio', 5, '2026-02-01 13:15:00'),
(10, 'Vehículo abandonado por varios días', 5, '2026-03-10 08:05:00'),
(11, 'Obstrucción de paso peatonal', 6, '2026-01-17 17:30:00'),
(12, 'Escape con olor fuerte a combustible', 6, '2026-02-24 10:50:00'),
(13, 'Mal estacionamiento en zona comercial', 7, '2026-01-26 15:40:00'),
(14, 'Conducción a alta velocidad en calle angosta', 7, '2026-03-07 19:10:00'),
(15, 'Vehículo generando ruido mecánico constante', 8, '2026-02-03 12:25:00'),
(16, 'Bloqueo de acceso a rampa para discapacitados', 8, '2026-03-14 09:45:00'),
(17, 'Frenadas bruscas recurrentes en tráfico', 9, '2026-01-31 16:55:00'),
(18, 'Vehículo emitiendo humo negro', 9, '2026-03-19 07:35:00'),
(19, 'Conductor usando celular mientras manejaba', 10, '2026-02-06 18:05:00'),
(20, 'Estacionamiento indebido en zona de emergencia', 10, '2026-03-27 11:20:00');

-- migrate:down

DELETE FROM complains;