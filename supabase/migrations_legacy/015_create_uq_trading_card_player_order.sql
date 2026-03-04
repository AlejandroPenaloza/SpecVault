/*
  Project:   SpecVault
  Migration: 015_create_uq_trading_card_player_order
  Author:    Alejandro Penaloza
  Created:   2026/02/09
  
  Purpose: 
  To create constraint 'uq_trading_card_player_order' intended to be used 
  in table 'trading_card_players'. 
  Note that there are trading cards with multiple players. 
  Thus, 'trading_card_players' has rows with same 'trading_card_id' 
  that has to have different 'player_id', 'player_order' (and other columns).
  Then, for a given trading card, 'player_order' value can appear only once.
  */


-- create constraint uq_trading_card_player_order
ALTER TABLE trading_card_players
ADD CONSTRAINT uq_trading_card_player_order
UNIQUE (trading_card_id, player_order);
