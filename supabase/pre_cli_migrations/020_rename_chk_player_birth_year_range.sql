/*
  Project:   SpecVault
  Migration: 020_rename_chk_player_birth_year_range
  Author:    Alejandro Penaloza
  Created:   2026/02/10
  
  Purpose: 
  NO-OP
  ------
  This migration was originally intended to rename players.birth_year 
  CHECK constraint.
  However, migration '019_allow_null_players_birth_year' had 
  already standardized the name to 'çhk_players_birth_year_name'.
  Thus, this migration is now intentionally a NO-OP to preserve 
  a clean, replayable migration chain.
*/
