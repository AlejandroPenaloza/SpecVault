/*
  Project:   SpecVault
  Migration: 021_add_player_position_columns_and_format_validation_constraints
  Author:    Alejandro Penaloza
  Created:   2026/02/19
  
  Purpose: 
  To add player field position, represented by:
  - players.primary_position: usual/career playing position abbreviation. 
      Not required since this one is not meant to match the trading card.
  - trading_card_players.postion: specific playing position abbreviation for 
      corresponding trading card.
*/


-- add position column to players
ALTER TABLE players
ADD COLUMN primary_position text;

-- add card-specific position to trading_card_players
ALTER TABLE trading_card_players
ADD COLUMN position text;

-- format validation (traditional position abbreviations)
-- for both columns 
ALTER TABLE players
ADD CONSTRAINT chk_players_prim_pos_format 
CHECK (primary_position IS NULL OR primary_position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$');

ALTER TABLE trading_card_players
ADD CONSTRAINT chk_trading_card_players_position_format
CHECK (position IS NULL OR position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$')
