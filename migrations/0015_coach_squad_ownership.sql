PRAGMA foreign_keys = OFF;

CREATE TABLE IF NOT EXISTS squads (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    coach_id TEXT NOT NULL,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (coach_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS squad_players (
    squad_id TEXT NOT NULL,
    player_id TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (squad_id, player_id),
    FOREIGN KEY (squad_id) REFERENCES squads(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_squads_coach ON squads(coach_id);
CREATE INDEX IF NOT EXISTS idx_squads_school ON squads(school_id);
CREATE INDEX IF NOT EXISTS idx_squad_players_player ON squad_players(player_id);

PRAGMA foreign_keys = ON;
