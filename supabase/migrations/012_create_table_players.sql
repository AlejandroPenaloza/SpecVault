/*
  Project:   SpecVault
  Migration: 012_create_table_players
  Author:    Alejandro Penaloza
  Created:   2026/01/30
  
  Purpose: 
  To create table 'players' (for subcollection trading cards).
  It is intended to be used by junction table 'trading_card_players' 
  (yet to be created).
  */


-- create table trading_cards
CREATE TABLE players (
  id uuid PRIMARY KEY
    DEFAULT uuid_generate_v4(),

  first_name text NOT NULL,               -- Player first name
  last_name text NOT NULL,                -- Player last name, useful when searching
  nationality char(2),                    -- ISO-3166-1 alpha-2 (e.g. VE, US)

  birth_year integer 
    CHECK (
      birth_year >= 1850                -- Useful for differentiating
      AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE - 15)
    ),
  notes text                              -- Any other information
);
