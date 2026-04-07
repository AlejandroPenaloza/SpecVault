/*
  Project: SpecVault
  Migration: 20260406151837_039_add_column_serial_number
  Author: Alejandro Penaloza
  Created: 2026/04/06

  Purpose:
  To add column serial_number into table trading_cards. 
  It represents a limited edition identifier indicating specific copy and total production of the card.
*/

-- add column serial_number
-- limited edition identifier
ALTER TABLE trading_cards
ADD COLUMN serial_number text;
