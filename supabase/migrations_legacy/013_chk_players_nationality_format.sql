/*
  Project:   SpecVault
  Migration: 013_chk_players_nationality_format
  Author:    Alejandro Penaloza
  Created:   2026/01/31
  
  Purpose: 
  To create cosntraint 'chk_players_nationality_format' for table 
  players, intended to enforce nationality value in table players 
  to be NULL or in uppercase two-letter format (country code).
  */


-- create constraint chk_players_nationality_format
ALTER TABLE players
ADD CONSTRAINT chk_players_nationality_format
CHECK (nationality IS NULL OR nationality ~ '^[A-Z]{2}$');
