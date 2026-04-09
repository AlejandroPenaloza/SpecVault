/*
 Project: SpecVault
  Migration: 20260409173503_040_add_column_dimensions_to_trading_cards
  Author: Alejandro Penaloza
  Created: 2026/04/09

  Purpose:
  To add column dimensions into table trading_card for storing 
  trading card size information, defaulting to standard size 2.5"x3.5".
*/


-- create column dimensions
ALTER TABLE trading_cards
ADD COLUMN dimensions text NOT NULL DEFAULT '2.5" x 3.5"';

-- create constraint to enforce format
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_dimensions_format
CHECK (
  -- allows width x height with usage of "" or mm
  dimensions ~ '^[0-9]+(\.[0-9]+)?(\"| mm) x [0-9]+(\.[0-9]+)?(\"| mm)$'
);
