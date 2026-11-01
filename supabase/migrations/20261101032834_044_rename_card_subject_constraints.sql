/*
  Project: SpecVault
  Migration: 20261101032834_044_rename_card_subject_constraints
  Author: Alejandro Penaloza
  Created: 2026/10/31

  Purpose:

  Rename constraints following migration 043.
  Align constraint names with the renamed tables and columns.
  Renaming PRIMARY KEY and UNIQUE constraints also renames their associated indexes automatically.
*/


-- for table card_subjects
ALTER TABLE card_subjects
RENAME CONSTRAINT chk_players_birth_year_range
TO chk_card_subjects_birth_year_range;

ALTER TABLE card_subjects
RENAME CONSTRAINT chk_players_nationality_format
TO chk_card_subjects_nationality_format;

ALTER TABLE card_subjects
RENAME CONSTRAINT chk_players_prim_pos_format
TO chk_card_subjects_prim_pos_format;

ALTER TABLE card_subjects
RENAME CONSTRAINT players_pkey
TO card_subjects_pkey;


-- for table subject_appearances
ALTER TABLE subject_appearances
RENAME CONSTRAINT chk_player_jersey_number_range
TO chk_subject_jersey_number_range;

ALTER TABLE subject_appearances
RENAME CONSTRAINT chk_player_order_range
TO chk_subject_order_range;

ALTER TABLE subject_appearances
RENAME CONSTRAINT chk_trading_card_players_position_format
TO chk_subject_appearances_position_format;

ALTER TABLE subject_appearances
RENAME CONSTRAINT trading_card_players_player_id_fkey
TO subject_appearances_subject_id_fkey;

ALTER TABLE subject_appearances
RENAME CONSTRAINT trading_card_players_trading_card_id_fkey
TO subject_appearances_trading_card_id_fkey;

ALTER TABLE subject_appearances
RENAME CONSTRAINT trading_card_players_pkey
TO subject_appearances_pkey;

ALTER TABLE subject_appearances
RENAME CONSTRAINT uq_trading_card_player_order
TO uq_subject_appearance_order;
