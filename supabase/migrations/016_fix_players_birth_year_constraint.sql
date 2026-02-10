/*
  Project:   SpecVault
  Migration: 016_fix_players_birth_year_constraint
  Author:    Alejandro Penaloza
  Created:   2026/02/09
  
  Purpose: 
  To fix incorrect birth_year CHECK constraint in table 
  'players'.
  Buggy constraint 'players_birth_year_check', defined when 
  creating 'players', is dropped. 
  Then, correct CHECK constraint 'chk_players_birth_year_range' 
  added. 
*/


-- drop incorrect constraint
ALTER TABLE players
DROP CONSTRAINT IF EXISTS players_birth_year_check;

-- add fixed constraint (players)
ALTER TABLE players
ADD CONSTRAINT chk_players_birth_year_range
CHECK (
  birth_year >= 1850
  AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
);
