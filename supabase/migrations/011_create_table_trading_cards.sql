/*
  Project:   SpecVault
  Migration: 011_create_table_trading_cards
  Author:    Alejandro Penaloza
  Created:   2026/01/18
  
  Purpose: 
  To create table 'trading_cards' (for subcollection trading cards).
  It is intended to be used by junction table 'trading_card_players'.
  */


-- create table trading_cards
CREATE TABLE trading_cards (
  item_id uuid PRIMARY KEY
    REFERENCES items(id) ON DELETE CASCADE,

  topic text NOT NULL,                  -- Sport, discipline, or other topic
  brand text,                           -- Topps, Panini, Upper Deck
  set_name text,                        -- Set or series name
  year integer CHECK (year >= 1800),    -- Card issue year
  card_number text,                     -- Alphanumeric
  condition text,                       -- NM, EX, PSA 9,...
  is_autographed boolean DEFAULT false, -- Whether marker autograph on card
  notes text
);
