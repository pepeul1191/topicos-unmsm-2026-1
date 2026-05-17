-- migrate:up

CREATE TABLE etl_executions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  succeded BOOLEAN NOT NULL DEFAULT 0,
  created DATETIME NOT NULL
);

-- migrate:down

DROP TABLE etl_executions;