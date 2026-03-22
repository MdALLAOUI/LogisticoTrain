CREATE TABLE IF NOT EXISTS Voie (
    num_voie INT(11) NOT NULL,
    interdite TINYINT(1) NOT NULL,
    PRIMARY KEY (num_voie)
);

CREATE TABLE IF NOT EXISTS Rame (
    num_serie VARCHAR(12) NOT NULL,
    type_rame VARCHAR(50) NOT NULL,
    voie INT(11),
    conducteur_entrant VARCHAR(50) NOT NULL,
    PRIMARY KEY (num_serie),
    UNIQUE (voie),
    FOREIGN KEY (voie) REFERENCES Voie(num_voie)
);

CREATE TABLE IF NOT EXISTS Tache (
    num_serie_rame VARCHAR(12) NOT NULL,
    num_tache INT(11) NOT NULL,
    tache TEXT NOT NULL,
    PRIMARY KEY (num_serie_rame, num_tache),
    FOREIGN KEY (num_serie_rame) REFERENCES Rame(num_serie)
);