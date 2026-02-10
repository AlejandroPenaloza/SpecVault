/*
  Project:   SpecVault
  Migration: 018_set_created_at_updated_at_is_autographed_not_null
  Author:    Alejandro Penaloza
  Created:   2026/02/10
  
  Purpose: 
  To enforce columns items.created_at, items.updated_at, 
  and trading_cards.is_autographed to be NOT NULL. 
  They are timestamptz and boolean types, and a determined value 
  is expected from them. A NULL value does not represent a 
  meaningful state for the data.
*/


-- alter created_at, updated_at to be NOT NULL
ALTER TABLE items
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL;

-- alter is_autographed to be NOT NULL
ALTER TABLE trading_cards
ALTER COLUMN is_autographed SET NOT NULL;
