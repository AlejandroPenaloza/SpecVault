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
  Updated: 2026/02/23
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

-- migrate existing data in coins.obtained_from to items.obtained_from
UPDATE items i
SET obtained_from = c.obtained_from
FROM coins c
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
);


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


-- create table players
CREATE TABLE players (
  id uuid PRIMARY KEY
    DEFAULT uuid_generate_v4(),

  first_name text NOT NULL,               -- Player first name
  last_name text NOT NULL,                -- Player last name, useful when searching
  nationality char(2),                    -- ISO-3166-1 alpha-2 (e.g. VE, US)

  birth_year integer 
    CHECK (
      birth_year >= 1850                  -- Enforcing time (year) range
      -- BUG: substracts days, not years. 
      -- 2026-02-09: See migration 016_fix_players_birth_year_constraint.sql
      AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE - 15)
    ),
  notes text                              -- Any other information
);

-- create constraint chk_players_nationality_format
ALTER TABLE players
ADD CONSTRAINT chk_players_nationality_format
CHECK (nationality IS NULL OR nationality ~ '^[A-Z]{2}$');


-- create junction table trading_card_players
CREATE TABLE trading_card_players (
  trading_card_id uuid
    REFERENCES trading_cards(item_id) ON DELETE CASCADE,

  player_id uuid
    REFERENCES players(id) ON DELETE CASCADE,

  player_order smallint NOT NULL,       -- Position/order on the card (1–3)
  team_name text,                       -- Team shown for this player on this card
  jersey_number smallint,               -- Jersey number shown on this card

  PRIMARY KEY (trading_card_id, player_id)
);


-- create constraint uq_trading_card_player_order
-- enforce player_order not repeated between multiple players in trading card
ALTER TABLE trading_card_players
ADD CONSTRAINT uq_trading_card_player_order
UNIQUE (trading_card_id, player_order);


-- 2026-02-09: fix CHECK constraint in players.birth_year (CURRENT_DATE - 15 days, not years)
-- drop incorrect constraint
ALTER TABLE players
DROP CONSTRAINT IF EXISTS players_birth_year_check;

-- add fixed constraint (players)
ALTER TABLE players
ADD CONSTRAINT chk_players_birth_year_range
CHECK (
  birth_year >= 1850
  AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
);


-- 2026-02-09: created constraints for trading_card_players.player_order 
-- and trading_card_players.jersey_number.
-- add constraint chk_player_order_range
ALTER TABLE trading_card_players
ADD CONSTRAINT chk_player_order_range
CHECK (player_order BETWEEN 1 AND 3);

-- add constraint chk_player_jersey_number_range
ALTER TABLE trading_card_players
ADD CONSTRAINT chk_player_jersey_number_range
CHECK (jersey_number IS NULL OR jersey_number BETWEEN 0 AND 99);


-- 2026-02-10: altered columns items.created_at, items.updated_at, 
-- trading_cards.is_autographed to be NOT NULL (no meaningful NULL state)
-- alter created_at, updated_at to be NOT NULL
ALTER TABLE items
ALTER COLUMN created_at SET NOT NULL,
ALTER COLUMN updated_at SET NOT NULL;

-- alter is_autographed to be NOT NULL
ALTER TABLE trading_cards
ALTER COLUMN is_autographed SET NOT NULL;


-- 2026-02-10: drop existing constraint chk_players_birth_year_range and add it 
-- again allowing NULL values for players.birth_year.

-- drop current constraint chk_players_birth_year_range
ALTER TABLE players
DROP CONSTRAINT chk_players_birth_year_range;

-- recreate constraint allowing NULL
ALTER TABLE players
ADD CONSTRAINT chk_players_birth_year_range
CHECK (
  birth_year IS NULL OR (
    birth_year >= 1850
    AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
  )
);


-- 2026-02-19: add player position columns in players, trading_card_players 
-- and corresponding constraints for format validation

-- add position column to players
ALTER TABLE players
ADD COLUMN primary_position text;

-- add card-specific position to trading_card_players
ALTER TABLE trading_card_players
ADD COLUMN position text;

-- format validation (traditional position abbreviations)
-- for both columns 
ALTER TABLE players
ADD CONSTRAINT chk_players_prim_pos_format 
CHECK (primary_position IS NULL OR primary_position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$');

ALTER TABLE trading_card_players
ADD CONSTRAINT chk_trading_card_players_position_format
CHECK (position IS NULL OR position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$')


-- insert single demo trading card row to base table items
-- subsequently, to tables trading_cards, players, and junction 
-- table trading_card_players
BEGIN;

WITH
-- base item and capture id
new_item AS (
  INSERT INTO items (name, acquired_date, subcollection, theme, obtained_from)
  VALUES (
    'Bobby Abreu Baseball Card Fleer 2001',
    '2014-11-15',
    'trading cards',
    'Baseball Cards',
    'Previous collection'
  )
  RETURNING id
),

-- trading_cards row using new item id
new_card AS (
  INSERT INTO trading_cards (
    item_id, topic, brand, set_name, year, card_number, is_autographed
  )
  SELECT
    id,
    'Baseball',
    'Fleer',
    'Fleer 2001',
    2001,
    '76',
    false
  FROM new_item
  RETURNING item_id
),

-- player row
new_player AS (
  INSERT INTO players (first_name, last_name, nationality, birth_year, primary_position)
  VALUES ('Bobby', 'Abreu', 'VE', 1974, 'OF')
  RETURNING id
)

-- 4) Link player to the card (junction row)
INSERT INTO trading_card_players (
  trading_card_id, player_id, player_order, team_name, jersey_number, position
)
SELECT
  (SELECT item_id FROM new_card),
  (SELECT id FROM new_player),
  1,
  'Philadelphia Phillies',
  53,
  'OF';

COMMIT;


-- 2026-02-23: create table stamps to represents subcollection stamps

-- create table stamps
-- stamp-specific attributes (1-to-1 with items)
CREATE TABLE stamps (
  item_id uuid PRIMARY KEY
    REFERENCES items(id)
    ON DELETE CASCADE,

  country text,                           -- Issuing country/region
  issue_year integer                      -- approximate year if exact date unknown
    CHECK (issue_year IS NULL OR 
      (issue_year >= 1600 AND issue_year <= EXTRACT(YEAR FROM CURRENT_DATE)::int)),

  issue_date date,                        -- exact issue date if known (optional)
  denomination_text text,                 -- "5c", "1 euro", 0.5 bolívares, 2£, etc.
  currency text,                          -- Optional: "USD", "EUR", "GBP", etc. (or leave null)

  stamp_type text,                        -- definitive, commemorative, airmail, revenue, etc.
  format text,                            -- single, pair, strip, block, sheet, souvenir sheet
  perforation text,                       -- e.g., "11", "12 1/2", "imperforate"
  watermark text,                         -- if applicable
  printing_method text,                   -- engraved, litho, offset, etc.
  color text,                             -- free-text

  condition text,                         -- MNH, MH, Used, CTO, etc.
  is_on_cover boolean DEFAULT false NOT NULL,  -- true if item is a cover (simple flag for now)

  catalog_system text,                    -- Scott, Michel, Stanley Gibbons, Yvert, etc.
  catalog_number text,                    -- e.g., "Scott 1234"
  notes text
);
