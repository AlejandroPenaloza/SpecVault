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
  Updated: 2026/01/10
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

-- change of type from timestamp to timestamptz
ALTER TABLE items
  ALTER COLUMN created_at TYPE timestamptz
  USING created_at AT TIME ZONE 'UTC';

ALTER TABLE items
  ALTER COLUMN updated_at TYPE timestamptz
  USING updated_at AT TIME ZONE 'UTC';

-- decided to move feature 'obtained_from' from 'coins' to base table 'items' 
-- since it is likely a feature for all subcollection (all items).
-- create column 'obtained_from' in 'items'
ALTER TABLE items
ADD COLUMN obtained_from text;

-- migrate existing data in coin's obtained from to item's
UPDATE items i
SET obtained_from = c.obtained_from
FROM coinc c
WHERE c.item_id = i.id
  AND c.obtained_from IS NOT NULL
  AND i.obtained_from IS NULL;

-- eliminate column 'obtained_from' in 'coins'
ALTER TABLE coins
DROP COLUMN obtained_from;


-- create table banknotes
-- banknote-specific attributes (1-to-1 with items)
CREATE TABLE banknotes (
  item_id uuid PRIMARY KEY
    REFERENCES items(id)
    ON DELETE CASCADE,

  denomination numeric(10,2),           -- face value
  currency text,                        -- currency name (may be historical)
  country text,                         -- issuing country or region
  issuer text,                          -- central bank or authority
  material text,                        -- paper, polymer, hybrid

  issue_date date,                      -- stored as full date
  issue_date_precision text             -- date precision reach (year, month, or day)
    CHECK (issue_date_precision IN ('year', 'month', 'day')
  ),

  width numeric(10,2)                   -- millimeters
    CHECK (width IS NULL OR width > 0),
  height numeric(10,2)                  -- millimeters
    CHECK (height IS NULL OR height > 0),

  series text,                          -- series/serial number
  condition text,                       -- grade or condition
  notes text                            -- free-form notes
);

-- Enforce logical consistency between issue_date and issue_date_precision
ALTER TABLE banknotes 
ADD CONSTRAINT banknotes_issue_date_consistency
CHECK (
  (issue_date IS NULL AND issue_date_precision IS NULL)
OR
  (issue_date IS NOT NULL AND issue_date_precision IS NOT NULL)
)


-- Insert another demo item record
-- single transaction using common table expression 
-- and returning result (generated id)
BEGIN;

WITH new_item AS (
  INSERT INTO items (
    name, 
    acquired_date, 
    subcollection,
    theme,
    obtained_from
  )
  VALUES (
    '1 Bolivar 10/05/1989', 
    '2024-08-03', 
    'banknotes',
    'Venezuelan banknotes', 
    'Ebay/geraval'
  )
  RETURNING id
)
INSERT INTO banknotes (
  item_id,
  denomination,
  currency, 
  country, 
  issuer, 
  issue_date, 
  issue_date_precision, 
  width, 
  height, 
  series
)
SELECT
  id,
  1.00, 
  'Bolivares',
  'Venezuela', 
  'Banco Central de Venezuela (BCV)', 
  '1989-05-10', 
  'day', 
  115, 
  55, 
  'A51283218'
FROM new_item;

COMMIT;
