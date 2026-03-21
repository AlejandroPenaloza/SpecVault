/*
  Project:   SpecVault
  Migration: 017_add_player_order_and_jersey_number_constraints
  Author:    Alejandro Penaloza
  Created:   2026/02/09
  
  Purpose: 
  To add constraints 'chk_player_order_range' and 
  'chk_player_jersey_number_range'. 
  They will check whether trading_card_players.player_order 
  is 1,2, or 3. 
  Similarly, if trading_card_players.jersey_number is a 
  positive integer under 100. 
*/


-- add constraint chk_player_order_range
ALTER TABLE trading_card_players
ADD CONSTRAINT chk_player_order_range
CHECK (player_order BETWEEN 1 AND 3);

-- add constraint chk_player_jersey_number_range
ALTER TABLE trading_card_players
ADD CONSTRAINT chk_player_jersey_number_range
CHECK (jersey_number IS NULL OR jersey_number BETWEEN 0 AND 99);
