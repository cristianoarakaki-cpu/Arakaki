BEGIN TRANSACTION;
CREATE TABLE servidores(id INTEGER PRIMARY KEY, nome TEXT NOT NULL, setor TEXT, horas INTEGER CHECK(horas>=0));
INSERT INTO "servidores" VALUES(1,'Pessoa Exemplo A','Enfermagem',12);
INSERT INTO "servidores" VALUES(2,'Pessoa Exemplo B','Administrativo',6);
INSERT INTO "servidores" VALUES(3,'Pessoa Exemplo C','Enfermagem',12);
COMMIT;