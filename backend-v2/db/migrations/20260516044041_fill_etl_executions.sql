-- migrate:up

INSERT INTO etl_executions (id, description, succeded, created) VALUES
(1,  'Initial sync: cars → LevelDB', 1, '2026-05-01 10:00:00'),
(2,  'Sync technical reviews batch', 1, '2026-05-02 11:15:00'),
(3,  'Sync complains batch', 1, '2026-05-03 09:40:00'),
(4,  'Sync infractions batch', 1, '2026-05-04 14:20:00'),
(5,  'Full ETL execution (all tables)', 1, '2026-05-05 22:00:00'),
(6,  'Retry failed sync (cars module)', 0, '2026-05-06 08:30:00'),
(7,  'Incremental sync technical reviews', 1, '2026-05-07 12:10:00'),
(8,  'Incremental sync complains', 1, '2026-05-08 13:25:00'),
(9,  'Infractions sync failed (schema mismatch)', 0, '2026-05-09 16:45:00'),
(10, 'Nightly ETL full refresh', 1, '2026-05-10 23:55:00'),
(11, 'Delta sync cars updated records', 1, '2026-05-11 07:20:00'),
(12, 'LevelDB index rebuild', 1, '2026-05-12 01:05:00'),
(13, 'ETL validation run (data integrity check)', 1, '2026-05-13 15:00:00'),
(14, 'Emergency rollback ETL execution', 0, '2026-05-14 18:40:00');

-- migrate:down

DELETE FROM etl_executions;