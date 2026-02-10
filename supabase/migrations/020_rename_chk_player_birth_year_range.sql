/*
  Project:   SpecVault
  Migration: 020_rename_chk_player_birth_year_range
  Author:    Alejandro Penaloza
  Created:   2026/02/10
  
  Purpose: 
  To standardize player.birth_year CHECK constraint name 
  (plural to singular).
  From 'chk_players_birth_year_range' to 
  'chk_player_birth_year_range'.
*/


-- alter players to rename constraint to chk_player_birth_year_range
ALTER TABLE players
RENAME CONSTRAINT chk_player_birth_year_range
TO chk_players_birth_year_range;
