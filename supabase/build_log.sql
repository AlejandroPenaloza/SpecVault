/*
  SpecVault Database
  build_log.sql
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
  Updated: 2026/04/10
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
CHECK (position IS NULL OR position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$');


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


-- 2026-02-23: create table stamps to represent subcollection stamps

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
  color text,                             -- dominating color in stamp

  condition text,                         -- MNH, MH, Used, CTO, etc.
  is_on_cover boolean DEFAULT false NOT NULL,  -- true if item is a cover (simple flag for now)

  catalog_system text,                    -- Scott, Michel, Stanley Gibbons, Yvert, etc.
  catalog_number text,                    -- e.g., "Scott 1234"
  notes text
);

-- alter table stamps to rename column to main_color
ALTER TABLE stamps
RENAME COLUMN color TO main_color;


-- 2026-03-04: create table taxa to be included in representation of 
-- subcollection lepidoptera

-- create table taxa
-- biological taxonomy hierarchy used to classify Lepidoptera specimens
CREATE TABLE taxa (
  id uuid PRIMARY KEY
    DEFAULT uuid_generate_v4(),

  tax_name text NOT NULL,
  rank text NOT NULL,

  parent_id uuid
    REFERENCES taxa(id)
    ON DELETE RESTRICT,

  authority text,     -- e.g. "Linnaeus, 1758"
  common_name text,   -- optional vernacular name
  notes text,

  CONSTRAINT chk_taxa_rank
    CHECK (
      rank IN (
        'family',
        'subfamily',
        'tribe',
        'subtribe',
        'genus',
        'species',
        'subspecies'
      )
    )
);


-- 2026-03-20: update table taxa

-- alter table taxa to add column type_locality
ALTER TABLE taxa
ADD COLUMN type_locality text;

-- add indexes for traversal of taxa
CREATE INDEX idx_taxa_tax_name
ON taxa(tax_name);

CREATE INDEX idx_taxa_parent_id
ON taxa(parent_id);


-- 2026-03-21: add trigger function validate_parent_child_rank to be used in trigger trg_parent_child_rank
-- also to add table specimens and corresponding trigger.

-- validate taxa hierarchy by enforcing allowed parent-child rank combinations.
-- ensures family is root-only and lower ranks attach only to valid parent ranks.
CREATE OR REPLACE FUNCTION validate_parent_child_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  parent_rank text;
BEGIN
  -- family must not have a parent
  IF NEW.rank = 'family' THEN
    IF NEW.parent_id IS NOT NULL THEN
      RAISE EXCEPTION
        'Taxon with rank "family" cannot have a parent';
    END IF;

    RETURN NEW;
  END IF;

  -- all non-family ranks must have a parent
  IF NEW.parent_id IS NULL THEN
    RAISE EXCEPTION
      'Taxon with rank "%" must have a parent', NEW.rank;
  END IF;

  -- prevent self-parenting
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION
      'Taxon cannot be its own parent';
  END IF;

  -- look up parent rank
  SELECT t.rank
  INTO parent_rank
  FROM taxa t
  WHERE t.id = NEW.parent_id;

  -- validate allowed parent-child combinations
  IF NEW.rank = 'subfamily' AND parent_rank <> 'family' THEN
    RAISE EXCEPTION
      'Invalid parent rank: subfamily must have parent rank family, got %', parent_rank;

  ELSIF NEW.rank = 'tribe' AND parent_rank NOT IN ('family', 'subfamily') THEN
    RAISE EXCEPTION
      'Invalid parent rank: tribe must have parent rank family or subfamily, got %', parent_rank;

  ELSIF NEW.rank = 'subtribe' AND parent_rank NOT IN ('family', 'subfamily', 'tribe') THEN
    RAISE EXCEPTION
      'Invalid parent rank: subtribe must have parent rank family, subfamily, or tribe, got %', parent_rank;

  ELSIF NEW.rank = 'genus' AND parent_rank NOT IN ('family', 'subfamily', 'tribe', 'subtribe') THEN
    RAISE EXCEPTION
      'Invalid parent rank: genus must have parent rank family, subfamily, tribe, or subtribe, got %', parent_rank;

  ELSIF NEW.rank = 'species' AND parent_rank <> 'genus' THEN
    RAISE EXCEPTION
      'Invalid parent rank: species must have parent rank genus, got %', parent_rank;

  ELSIF NEW.rank = 'subspecies' AND parent_rank <> 'species' THEN
    RAISE EXCEPTION
      'Invalid parent rank: subspecies must have parent rank species, got %', parent_rank;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_parent_child_rank ON taxa;

CREATE TRIGGER trg_validate_parent_child_rank
BEFORE INSERT OR UPDATE OF rank, parent_id
ON taxa
FOR EACH ROW
EXECUTE FUNCTION validate_parent_child_rank();


-- create table specimens
-- Under the current project scope, at most one specimen is stored
-- per species or subspecies represented in the collection.
CREATE TABLE specimens (
  item_id uuid PRIMARY KEY
    REFERENCES items(id)
    ON DELETE CASCADE,

  taxon_id uuid NOT NULL
    REFERENCES taxa(id)
    ON DELETE RESTRICT,

  sex text
    CHECK (sex IN (
      'male', 
      'female', 
      'unknown'
    )
  ),

  wingspan_mm numeric(5,2)
    CHECK (wingspan_mm IS NULL OR wingspan_mm > 0),

  main_color text,
  notes text,

  CONSTRAINT uq_specimens_taxon_id
    UNIQUE (taxon_id)
);

-- create function check_spec_taxon_rank()
-- Ensure specimen records reference only species- or subspecies-level taxa.
CREATE OR REPLACE FUNCTION check_spec_taxon_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_rank text;
BEGIN
  SELECT rank
  INTO v_rank
  FROM taxa
  WHERE id = NEW.taxon_id;

  IF v_rank IS NULL THEN
    RAISE EXCEPTION
      'taxon_id % does not exist in taxa',
      NEW.taxon_id;
  END IF;

  IF v_rank NOT IN ('species', 'subspecies') THEN
    RAISE EXCEPTION
      'specimens.taxon_id must reference a taxon of rank species or subspecies (got %)',
      v_rank;
  END IF;

  RETURN NEW;
END;
$$;

-- create trigger trg_spec_check_taxon_rank
-- Validate that each specimen points only to a species- or subspecies-level taxon.
CREATE TRIGGER trg_spec_check_taxon_rank
BEFORE INSERT OR UPDATE OF taxon_id
ON specimens
FOR EACH ROW
EXECUTE FUNCTION check_spec_taxon_rank();


-- 2026-03-27: add table regions and corresponding indexes 
-- idx_regions_parent_node and idx_regions_name

-- create table regions
-- hierarchical geographic regions used of taxon occurrence/distribution
CREATE TABLE regions (
  code text PRIMARY KEY,
  name text NOT NULL,
  region_type text NOT NULL,
  parent_code text
    REFERENCES regions(code)
    ON DELETE RESTRICT,
  notes text,
  CONSTRAINT chk_regions_type
    CHECK (
      region_type IN (
        'continent',
        'country',
        'state',
        'province',
        'department',
        'region',
        'locality',
        'other'
      )
    ),
  CONSTRAINT chk_regions_not_self_parent
    CHECK (parent_code IS NULL OR parent_code <> code)
);

-- index for recursive traversal of the geographic region hierarchy
CREATE INDEX idx_regions_parent_code
ON regions(parent_code);

-- index for lookup of regions by name
CREATE INDEX idx_regions_name
ON regions(name);



-- 2026-03-29: add table taxon_regions and 
-- idx_taxon_regions_region_code and idx_taxon_regions_taxon_id

-- create table taxon_regions
-- many-to-many relation between taxa and geographic regions where they occur
CREATE TABLE taxon_regions (
  taxon_id uuid NOT NULL
    REFERENCES taxa(id)
    ON DELETE CASCADE,
  region_code text NOT NULL
    REFERENCES regions(code)
    ON DELETE RESTRICT,
  occurrence_status text
    CHECK (
      occurrence_status IS NULL OR occurrence_status IN (
        'present',
        'native',
        'endemic',
        'introduced',
        'uncertain'
      )
    ),
  notes text,
  PRIMARY KEY (taxon_id, region_code)
);

-- index for lookup of taxon-region rows by region
CREATE INDEX idx_taxon_regions_region_code
ON taxon_regions(region_code);

-- index for lookup of taxon-region rows by taxon
CREATE INDEX idx_taxon_regions_taxon_id
ON taxon_regions(taxon_id);


-- 2026-04-02: substitute constraint to check on options for the type of 
-- geographical distribution area of specimens' occurrence, by dropping 
-- chk_regions_type and adding chk_area_type
-- Also, to update column regions.region_type to area_type

-- drop old constraint
ALTER TABLE regions
DROP CONSTRAINT chk_regions_type;

-- add new constraint
ALTER TABLE regions
ADD CONSTRAINT chk_area_type
CHECK (
  region_type IN (
    'hemisphere',
    'continent',
    'country',
    'state',
    'province',
    'department',
    'biogeographic_region',
    'ecoregion',
    'habitat_zone',
    'other'
  )
);

-- rename column region_type -> area_type
ALTER TABLE regions
RENAME COLUMN region_type TO area_type;


-- 2026-04-03: rename table regions to distribution_areas, so that it represents 
-- more accurately the geographical ranges of occurrence of specimens
-- Also renaming corresponding indexes and constraint

-- rename table regions to distribution_areas
ALTER TABLE regions
RENAME TO distribution_areas;

-- rename indexes
ALTER INDEX idx_regions_parent_code
RENAME TO idx_dist_areas_parent_code;

ALTER INDEX idx_regions_name
RENAME TO idx_dist_areas_name;

-- rename constraint within table
ALTER TABLE distribution_areas
RENAME CONSTRAINT chk_regions_not_self_parent TO chk_dist_areas_not_self_parent;


-- 2026-04-05: renamed table taxon_regions to taxon_dist_areas, unnamed constraint, so as 
-- column regions_code to area_code and indexes idx_taxon_regions_region_code, 
-- idx_taxon_regions_taxon_id to idx_taxon_dist_areas_area_code, idx_dist_areas_taxon_id respectively

-- rename table
ALTER TABLE taxon_regions
RENAME TO taxon_dist_areas;

-- rename to taxon_dist_areas.area_code
ALTER TABLE taxon_dist_areas
RENAME COLUMN region_code TO area_code;

-- rename taxon_dist_areas indexes
ALTER INDEX idx_taxon_regions_region_code
RENAME TO idx_taxon_dist_areas_area_code;

ALTER INDEX idx_taxon_regions_taxon_id
RENAME TO idx_taxon_dist_areas_taxon_id;

-- search for unnamed constraint within taxon_dist_areas definition. 
-- the following query run in Supabase SQL Editor searches for its name. 
SELECT
  con.conname AS constraint_name,
  rel.relname AS table_name,
  pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
JOIN pg_class rel
  ON rel.oid = con.conrelid
JOIN pg_namespace nsp
  ON nsp.oid = rel.relnamespace
-- just in case, use initial table and updated names
WHERE rel.relname IN ('taxon_regions', 'taxon_dist_areas')
  AND con.contype = 'c'
ORDER BY rel.relname, con.conname;
-- found name: taxon_regions_occurrence_status_check

-- rename constraint to chk_taxon_dist_areas_occur_status
ALTER TABLE taxon_dist_areas
RENAME CONSTRAINT taxon_regions_occurrence_status_check 
TO chk_taxon_dist_areas_occur_status;


-- 2026-04-06: rename constraint for distribution_areas.area_type. 
-- Also, to add new column trading_cards.serial_number, representing a limited edition identifier 
-- indicating the specific copy and total production of the card.

-- rename constraint
ALTER TABLE distribution_areas
RENAME CONSTRAINT chk_area_type
TO chk_distribution_areas_area_type;


-- add column serial_number
-- limited edition identifier
ALTER TABLE trading_cards
ADD COLUMN serial_number text;


-- 2026-04-10: add column dimensions to trading_cards, to store cards size.

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
