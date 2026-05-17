CREATE TABLE IF NOT EXISTS "schema_migrations" (version varchar(128) primary key);
CREATE TABLE cars (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner VARCHAR(40) NOT NULL,
  branch VARCHAR(30) NOT NULL,
  model VARCHAR(30) NOT NULL,
  color VARCHAR(12) NOT NULL,
  frabricated INTEGER NOT NULL,
  plate VARCHAR(7) NOT NULL
);
CREATE TABLE technical_reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    car_id INTEGER NOT NULL,
    created DATETIME,
    FOREIGN KEY (car_id) REFERENCES cars(id)
);
CREATE TABLE infractions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    car_id INTEGER NOT NULL,
    created DATETIME,
    FOREIGN KEY (car_id) REFERENCES cars(id)
);
CREATE TABLE complains (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    car_id INTEGER NOT NULL,
    created DATETIME,
    FOREIGN KEY (car_id) REFERENCES cars(id)
);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE etl_executions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  succeded BOOLEAN NOT NULL DEFAULT 0,
  created DATETIME NOT NULL
);
-- Dbmate schema migrations
INSERT INTO "schema_migrations" (version) VALUES
  ('20260516020409'),
  ('20260516021547'),
  ('20260516021557'),
  ('20260516021605'),
  ('20260516021927'),
  ('20260516022034'),
  ('20260516022123'),
  ('20260516022141'),
  ('20260516043506'),
  ('20260516044041');
