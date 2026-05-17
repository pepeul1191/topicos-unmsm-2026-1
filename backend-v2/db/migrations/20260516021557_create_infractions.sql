-- migrate:up

CREATE TABLE infractions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    car_id INTEGER NOT NULL,
    created DATETIME,
    FOREIGN KEY (car_id) REFERENCES cars(id)
);

-- migrate:down

DROP TABLE infractions;