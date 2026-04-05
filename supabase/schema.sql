/*
  Project: SpecVault
  schema.sql
  -------------------------
  Canonical schema snapshot representing the current 
  structural state of SpecVault database.
  Derived from applied migrations.
  -------------------------
  Alejandro Penaloza
  Created: 2026/01/02
  Updated: 2026/04/05
*/


create extension if not exists "uuid-ossp";


-- Create base table 'items'
create table items (
  -- Random generated id if not specified
  id uuid primary key default uuid_generate_v4(),

  name text not null,
  description text,
  acquired_date date,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  subcollection text,
  theme text, 

  acquisition_cost numeric(10,2) 
    CHECK (acquisition_cost IS NULL OR acquisition_cost >= 0),
  acquisition_currency char(3) DEFAULT 'USD' 
    CHECK (acquisition_currency ~ '^[A-Z]{3}$'), 
  obtained_from text
);

-- index of subcollection in items
CREATE INDEX idx_items_subcollection
ON items(subcollection);


-- create table 'coins'
-- coin-specific attributes (1-to-1 with items)
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
  weight numeric(10,4)                  -- Grams
    CHECK (weight IS NULL OR weight > 0),
  diameter numeric(10,2)                -- Millimeters
    CHECK (diameter IS NULL OR diameter > 0),
  mark text,                            -- Special marks or privy marks
  prog_theme text,                      -- Program/theme (e.g. State Quarters)
  condition text,                       -- Grade or condition
  mintage bigint CHECK (mintage >= 0),  -- Number minted
  notes text                            -- Free-form notes
);


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
  notes text,                           -- free-form notes

  -- Enforce logical consistency between issue_date and issue_date_precision
  CONSTRAINT banknotes_issue_date_consistency
  CHECK (
    (issue_date IS NULL AND issue_date_precision IS NULL)
    OR
    (issue_date IS NOT NULL AND issue_date_precision IS NOT NULL)
  )
);


-- create table trading_cards
CREATE TABLE trading_cards (
  item_id uuid PRIMARY KEY
    REFERENCES items(id) ON DELETE CASCADE,

  topic text NOT NULL,                           -- Sport, discipline, or other topic
  brand text,                                    -- Topps, Panini, Upper Deck
  set_name text,                                 -- Set or series name
  year integer CHECK (year >= 1800),             -- Card issue year
  card_number text,                              -- Alphanumeric
  condition text,                                -- NM, EX, PSA 9,...
  is_autographed boolean NOT NULL DEFAULT false, -- Whether marker autograph on card
  
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
      birth_year IS NULL OR (             -- Enforcing time (year) range
        birth_year >=1850
        AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
      )
    ),
  notes text,                             -- Any other information
  primary_position text,                  -- Usual/career playing position

  CONSTRAINT chk_players_nationality_format
    CHECK (nationality IS NULL OR nationality ~ '^[A-Z]{2}$'),

  CONSTRAINT chk_players_prim_pos_format
    CHECK (primary_position IS NULL OR primary_position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$')
);


-- create junction table trading_card_players
CREATE TABLE trading_card_players (
  trading_card_id uuid
    REFERENCES trading_cards(item_id) ON DELETE CASCADE,

  player_id uuid
    REFERENCES players(id) ON DELETE CASCADE,

  player_order smallint NOT NULL,       -- Position/order on the card (1–3)
  team_name text,                       -- Team shown for this player on this card
  jersey_number smallint,               -- Jersey number shown on this card
  position text,                        -- Card-specific playing position

  PRIMARY KEY (trading_card_id, player_id),

  CONSTRAINT uq_trading_card_player_order
    UNIQUE (trading_card_id, player_order),

  CONSTRAINT chk_player_order_range
    CHECK (player_order BETWEEN 1 AND 3),

  CONSTRAINT chk_player_jersey_number_range
    CHECK (jersey_number IS NULL OR jersey_number BETWEEN 0 AND 99),

  CONSTRAINT chk_trading_card_players_position_format
    CHECK (position IS NULL OR position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$')
);


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
  main_color text,                        -- dominating color in stamp

  condition text,                         -- MNH, MH, Used, CTO, etc.
  is_on_cover boolean DEFAULT false NOT NULL,  -- true if item is a cover (simple flag for now)

  catalog_system text,                    -- Scott, Michel, Stanley Gibbons, Yvert, etc.
  catalog_number text,                    -- e.g., "Scott 1234"
  notes text
);


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
  type_locality text, -- type locality for taxon
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

-- indexes of taxa for traversal
CREATE INDEX idx_taxa_tax_name
ON taxa(tax_name);

CREATE INDEX idx_taxa_parent_id
ON taxa(parent_id);

-- Validate taxa hierarchy by enforcing allowed parent-child rank combinations.
-- Ensures family is root-only and lower ranks attach only to valid parent ranks.
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


-- create table regions
-- hierarchical geographic regions used of taxon occurrence/distribution
CREATE TABLE distribution_areas (
  code text PRIMARY KEY,
  name text NOT NULL,
  area_type text NOT NULL,
  parent_code text
    REFERENCES distribution_areas(code)
    ON DELETE RESTRICT,
  notes text,
  CONSTRAINT chk_area_type
    CHECK (
      area_type IN (
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
    ),
  CONSTRAINT chk_dist_areas_not_self_parent
    CHECK (parent_code IS NULL OR parent_code <> code)
);

-- index for recursive traversal of the geographic region hierarchy
CREATE INDEX idx_dist_areas_parent_code
ON distribution_areas(parent_code);

-- index for lookup of regions by name
CREATE INDEX idx_dist_areas_name
ON distribution_areas(name);


-- create table taxon_dist_areas
-- many-to-many relation between taxa and geographic distribution areas 
-- where they occur
CREATE TABLE taxon_dist_areas (
  taxon_id uuid NOT NULL
    REFERENCES taxa(id)
    ON DELETE CASCADE,
  area_code text NOT NULL
    REFERENCES distribution_areas(code)
    ON DELETE RESTRICT,

  occurrence_status text
  CONSTRAINT chk_taxon_dist_areas_occur_status
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
  PRIMARY KEY (taxon_id, area_code)
);

-- index for lookup of taxon-dist_area rows by region
CREATE INDEX idx_taxon_dist_areas_area_code
ON taxon_dist_areas(area_code);

-- index for lookup of taxon-dist_area rows by taxon
CREATE INDEX idx_taxon_dist_areas_taxon_id
ON taxon_dist_areas(taxon_id);
