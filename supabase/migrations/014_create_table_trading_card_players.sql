/*
  Project:   SpecVault
  Migration: 014_create_table_playing_card_players
  Author:    Alejandro Penaloza
  Created:   2026/02/05
  
  Purpose: 
  To create junction table 'trading_card_players'.
  It will use previous tables 'trading_cards' and 'players' 
  to represent trading cards subcollection.
  */


-- create junction table trading_card_players
CREATE TABLE trading_card_players (
  trading_card_id uuid
    REFERENCES trading_cards(item_id) ON DELETE CASCADE,

  player_id uuid
    REFERENCES players(id) ON DELETE CASCADE,

  player_order smallint NOT NULL,       -- Position/order on the card (1–3)
  team_name text,                       -- Team shown for this player on this card
  jersey_number smallint,               -- Jersey number shown on this card

  PRIMARY KEY (trading_card_id, player_id)
);
