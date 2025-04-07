CREATE DATABASE say_it_database;

CREATE TABLE videos (
    id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    video BYTEA NOT NULL
);

CREATE TABLE sinonimos ( id SERIAL PRIMARY KEY, forma TEXT UNIQUE NOT NULL, palabra_id INTEGER NOT NULL REFERENCES videos(id) ON DELETE CASCADE );

SELECT id, nombre, octet_length(video) AS tamanio_bytes FROM videos;

INSERT INTO sinonimos (forma, palabra_id) VALUES ('abrazo', 206), ('abrazando', 206), ('abrazado', 206), ('abrazarme', 206);