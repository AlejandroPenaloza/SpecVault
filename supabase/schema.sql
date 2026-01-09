/*
  Project: SpecVault
  schema.sql
  -------------------------
  Canonical schema snapshot representing the current 
  structural state of SpecVault database.
  Derivated from applied migrations.
  -------------------------
  Alejandro Penaloza
  Created: 2026/01/02
  Updated: 2026/01/09
*/


create extension if not exists "uuid-ossp";

-- Create table 'items'
create table items (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  description text,
  acquired_date date,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  subcollection text,
  theme text, 
  acquisition_cost numeric(10,2), 
  acquisition_currency char(3) DEFAULT 'USD', 
  obtained_from text
);

-- Enforce non-negative acquisition cost
ALTER TABLE items
ADD CONSTRAINT acquisition_cost_non_negative
CHECK (acquisition_cost IS NULL OR acquisition_cost >= 0);

-- Enforce valid ISO currency format (3 uppercase letters)
ALTER TABLE items
ADD CONSTRAINT acquisition_currency_format
CHECK (acquisition_currency ~ '^[A-Z]{3}$');

-- Create table 'coins'
-- Coin-specific attributes (1-to-1 with items)
CREATE TABLE coins (
  item_id uuid PRIMARY KEY REFERENCES items(id) ON DELETE CASCADE,

  denomination numeric(10,2),           -- Face value (e.g. 0.25, 1.00)
  currency text,                        -- Currency 
  year integer CHECK (year >= 0),       -- Mint year (AD only)
  country text,                         -- Issuing country
  mint text,                            -- Mint name (e.g. Philadelphia)
  mint_code text,                       -- Mint mark (e.g. P, D, S)
  composition text,                     -- Metal composition
  edge text,                            -- Reeded, plain, lettered
  finish text,                          -- Proof, business strike, etc.
  weight numeric(10,4),                 -- Grams
  diameter numeric(10,2),               -- Millimeters
  mark text,                            -- Special marks or privy marks
  prog_theme text,                      -- Program/theme (e.g. State Quarters)
  condition text,                       -- Grade or condition
  mintage bigint CHECK (mintage >= 0),  -- Number minted
  notes text                            -- Free-form notes
);

-- constraints of positivity for weight and diameter
ALTER TABLE coins
ADD CONSTRAINT coins_weight_positive
CHECK (weight IS NULL OR weight > 0);

ALTER TABLE coins
ADD CONSTRAINT coins_diameter_positive
CHECK (diameter IS NULL OR diameter > 0);
-- note that weight/diameter IS NULL is not necessary and used for readibility

-- index of subcollection in items
CREATE INDEX idx_items_subcollection
ON items(subcollection);
