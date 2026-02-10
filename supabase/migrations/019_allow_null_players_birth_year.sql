/*
  Project:   SpecVault
  Migration: 019_allow_null_players_birth_year
  Author:    Alejandro Penaloza
  Created:   2026/02/10
  
  Purpose: 
  To allow NULL values in players.birth_year while keeping the 
  valid range constraint defined in migration 
  '016_fix_players_birth_year_constraint.sql'.
*/


-- drop current constraint chk_players_birth_year_range
ALTER TABLE players
DROP CONSTRAINT chk_players_birth_year_range;

-- recreate constraint allowing NULL
ALTER TABLE players
ADD CONSTRAINT chk_players_birth_year_range
CHECK (
  birth_year IS NULL OR (
    birth_year >= 1850
    AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
  )
);
