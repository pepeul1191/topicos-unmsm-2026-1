-- migrate:up

CREATE TABLE cars (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner VARCHAR(40) NOT NULL,
  branch VARCHAR(30) NOT NULL,
  model VARCHAR(30) NOT NULL,
  color VARCHAR(12) NOT NULL,
  frabricated INTEGER NOT NULL,
  plate VARCHAR(7) NOT NULL
);

-- migrate:down

DROP TABLE cars;