/*
  Project: SpecVault
  Migration: 20261021012144_043_generalize_trading_card_players_to_subjects
  Author: Alejandro Penaloza
  Created: 2026/10/20

  Purpose: to rename tables players and trading_card_players.
           Also, their columns player_id, player_order.
*/


-- rename table players to card_subjects
ALTER TABLE players
RENAME TO card_subjects;

-- rename table trading_card_players to subject_appearances
ALTER TABLE trading_card_players
RENAME TO subject_appearances;

-- rename column player_id to subject_id
ALTER TABLE subject_appearances
RENAME COLUMN player_id TO subject_id;

-- rename column player_order to subject_order
ALTER TABLE subject_appearances
RENAME COLUMN player_order TO subject_order;
