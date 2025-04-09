CREATE DATABASE say_it_database;

CREATE TABLE videos (id SERIAL PRIMARY KEY,nombre TEXT NOT NULL,video BYTEA NOT NULL);

CREATE TABLE sinonimos ( id SERIAL PRIMARY KEY, forma TEXT UNIQUE NOT NULL, palabra_id INTEGER NOT NULL REFERENCES videos(id) ON DELETE CASCADE );

SELECT id, nombre, octet_length(video) AS tamanio_bytes FROM videos;

INSERT INTO sinonimos (forma, palabra_id) VALUES ('abrazo', 1), ('abrazando', 1), ('abrazado', 1), ('abrazarme', 1);


sudo -u postgres psql -d say_it_database

CREATE USER sayitadmin WITH PASSWORD 'Juanes123UWU';
ALTER ROLE sayitadmin SET client_encoding TO 'utf8';
ALTER ROLE sayitadmin SET default_transaction_isolation TO 'read committed';
ALTER ROLE sayitadmin SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE say_it_database TO sayitadmin;
GRANT ALL PRIVILEGES ON TABLE videos TO sayitadmin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sayitadmin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO sayitadmin;
