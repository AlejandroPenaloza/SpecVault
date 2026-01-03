/*
  SpecVault Database
  log.sql
  -------------------------
  Notes to work as a chronological record of SQL code executed 
  during development, including exploratory queries, testing, 
  data insertion, and structural change.

  This file is intended as a scratchpad timeline and development 
  log. 
  Thus, it is not as a migration, not idempotent, and not a 
  deployment artifact.
  It is not expected to be re-run end-to-end.
  -------------------------
  Alejandro Penaloza
  Created: 2026/01/02
  Updated: 2026/01/02
*/
-- DO NOT RUN IN PRODUCTION

create extension if not exists "uuid-ossp";

-- Create base table 'items'
create table items (
  -- Random generated id if not specified 
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text not null,
  description text,
  acquired_date date,
  created_at timestamp default now(),
  updated_at timestamp default now()
);

-- Insert first 'items' record 
INSERT INTO items (name, category)
VALUES ('1914 1 Cent', 'coins');

-- Add columns 'subcollection' and 'theme' in 'items'
ALTER TABLE items
ADD COLUMN subcollection text,
ADD COLUMN theme text;

-- Delete column 'category' in 'items' (columns replacement)
ALTER TABLE items
DROP COLUMN category;

-- Set theme for the first record (accessed by id) in 'items'
UPDATE items
  SET subcollection = 'coins',
  theme = 'US Coins'
WHERE id = '3c5972eb-0a2d-4948-903f-9595965c52e5';

-- Add column 'acquisition cost' (exact monetary value) in 'items'
ALTER TABLE items
ADD COLUMN acquisition_cost numeric(10,2);

-- Add column 'acquisition currency' (ISO-4217, default USD) in 'items'
ALTER TABLE items
ADD COLUMN acquisition_currency char(3) DEFAULT 'USD';

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
  obtained_from text,                   -- Source (dealer, gift, etc.)
  mintage bigint CHECK (mintage >= 0),  -- Number minted
  notes text                            -- Free-form notes
);

-- Insert first coin in 'coins' (corresponding to first item in 'items') 
INSERT INTO coins (
  item_id,
  denomination,
  year,
  country,
  mint,
  composition,
  edge,
  weight,
  diameter,
  condition,
  notes
)
VALUES (
  '3c5972eb-0a2d-4948-903f-9595965c52e5',
  0.01,
  1914,
  'United States',
  'US Mint (Philadelphia)',
  'Bronze',
  'Smooth',
  3.11,
  19.05,
  'Circulated',
  'Specification from ucoin.net.'
);

-- constraints of positivity for weight and diameter
ALTER TABLE coins
ADD CONSTRAINT coins_weight_positive
CHECK (weight IS NULL OR weight > 0);

ALTER TABLE coins
ADD CONSTRAINT coins_diameter_positive
CHECK (diameter IS NULL OR diameter > 0);
-- note that weight/diameter IS NULL is not necessary and used for readability

-- Create index 'idx_items_subcollection' of column 'subcollection' 
-- in 'items'
CREATE INDEX idx_items_subcollection
ON items(subcollection);
