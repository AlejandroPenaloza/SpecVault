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
  Updated: 2026/10/23
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
  acquisition_format text
  obtained_from text

  is_autographed boolean NOT NULL DEFAULT false
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

  title text,                                      -- Official card name or title
  card_date date,                                  -- Date printed on card
  card_date_precision text,                        -- Precision: year, month, day
  card_number text,                                -- Alphanumeric identifier number in card
  serial_number text,                              -- Individual printed numbered copy
  
  brand text,                                      -- Topps, Panini, Upper Deck
  set_name text,                                   -- Set or series name
  product_line text,                               -- Topps NOW, Prizm,...
  card_family text,                                -- Base, Autograph, ...
  subset text,                                     -- Named subset or insert grouping
  parallel text,                                   -- Card variation
  badges text[],                                   -- Printed and shown designation, badges, logos

  sport_or_topic text NOT NULL,                    -- Sport or topic of the card
  tournament text,                                 -- Tournament, league, competition; if applies

  condition text,                                  -- NM, EX, PSA 9,...
  dimensions text NOT NULL DEFAULT '2.5" x 3.5"',  -- Card dimensions: width x height including unit
  front_orientation text,                          -- Portrait or landscape
  back_orientation text,                           -- Portrait or landscape
  is_wrapper_stored boolean NOT NULL DEFAULT false, 
  
  autograph_type text NOT NULL DEFAULT 'Not autographed',
                                                   -- Type of autograph present in the card, if it is
  product_type text,                               -- Whether print on demand
  available_from_date date,                        -- Start of Topps NOW purchasing window
  available_to_date date,                          -- End of Topps NOW purchasing window
  print_run integer,                               -- Total number of copies produced, intended for Topps NOW
  theme text,
  notes text,

  CONSTRAINT chk_trading_cards_dimensions_format
  CHECK (
    dimensions ~ '^[0-9]+(\.[0-9]+)?(\"| mm) x [0-9]+(\.[0-9]+)?(\"| mm)$'
  ),

  -- card date precision
  CONSTRAINT chk_trading_cards_date_precision
  CHECK (
    (card_date IS NULL AND card_date_precision IS NULL)
    OR (
      card_date IS NOT NULL
      AND card_date_precision IN ('year', 'month', 'day')
      AND (
        card_date_precision = 'day'
        OR (
          card_date_precision = 'month'
          AND EXTRACT(DAY FROM card_date) = 1
        )
        OR (
          card_date_precision = 'year'
          AND EXTRACT(MONTH FROM card_date) = 1
          AND EXTRACT(DAY FROM card_date) = 1
        )
      )
    )
  ),

  -- card orientation
  CONSTRAINT chk_trading_cards_front_orientation
  CHECK (
    front_orientation IS NULL
    OR front_orientation IN ('portrait', 'landscape')
  ),

  CONSTRAINT chk_trading_cards_back_orientation
  CHECK (
    back_orientation IS NULL
    OR back_orientation IN ('portrait', 'landscape')
  ),


  -- print run boundaries
  CONSTRAINT chk_trading_cards_print_run_positive
  CHECK (
    print_run IS NULL OR print_run > 0
  ),

  CONSTRAINT chk_trading_cards_topps_now_start_date
  CHECK (
    available_from_date IS NULL
    OR available_from_date >= DATE '2016-04-04'
  ),

  -- when both available_from_date, available_to_date present, 
  -- the start date cannot be later than the end date
  CONSTRAINT chk_trading_cards_availability_dates
  CHECK (
    available_from_date IS NULL
    OR available_to_date IS NULL
    OR available_from_date <= available_to_date
  )
);

-- Topps NOW first date explanation in PostgreSQL metadata
COMMENT ON CONSTRAINT chk_trading_cards_topps_now_start_date
ON trading_cards
IS 'Minimum purchasing-window start date: April 4, 2016, the launch of the original Topps NOW baseball program.';


-- autograph synchronization function
-- trading_cards.autograph_type is authoritative for trading cards. 
-- Value 'Not autographed' maps to false; every other non-NULL value maps to true.
-- Locking the parent items row serializes competing changes to the autograph status of the same collectible
CREATE FUNCTION sync_trading_card_autograph()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE items
  SET is_autographed =
    (NEW.autograph_type <> 'Not autographed')
  WHERE id = NEW.item_id
    AND is_autographed IS DISTINCT FROM
      (NEW.autograph_type <> 'Not autographed');

  RETURN NEW;
END;
$$;


-- autograph validation function
-- reject direct changes to items.is_autographed contradicting trading card's autograph type
CREATE FUNCTION validate_item_autograph()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_autograph_type text;
BEGIN
  SELECT tc.autograph_type
  INTO v_autograph_type
  FROM trading_cards AS tc
  WHERE tc.item_id = NEW.id
  FOR UPDATE OF tc;

  IF FOUND AND
     NEW.is_autographed IS DISTINCT FROM
       (v_autograph_type <> 'Not autographed')
  THEN
    RAISE EXCEPTION
      'Autograph status conflicts with trading card for item %',
      NEW.id
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;


-- autograph triggers
-- changes to the card classification synchronize the parent
CREATE TRIGGER trg_sync_trading_card_autograph
AFTER INSERT OR UPDATE OF autograph_type
ON trading_cards
FOR EACH ROW
EXECUTE FUNCTION sync_trading_card_autograph();

-- direct parent updates are validated against the card
CREATE TRIGGER trg_validate_item_autograph
BEFORE UPDATE OF is_autographed
ON items
FOR EACH ROW
EXECUTE FUNCTION validate_item_autograph();


-- create table card_subjects
CREATE TABLE card_subjects (
  id uuid PRIMARY KEY
    DEFAULT uuid_generate_v4(),

  first_name text NOT NULL,               -- Subject first name
  last_name text NOT NULL,                -- Subject last name, useful when searching
  nationality char(2),                    -- ISO-3166-1 alpha-2 (e.g. VE, US)

  birth_year integer 
    CONSTRAINT chk_card_subjects_birth_year_range
    CHECK (
      birth_year IS NULL OR (             -- Enforcing time (year) range
        birth_year >=1850
        AND birth_year <= (EXTRACT(YEAR FROM CURRENT_DATE)::int - 15)
      )
    ),
  notes text,                             -- Any other information
  primary_position text,                  -- Usual/career playing position

  CONSTRAINT chk_card_subjects_nationality_format
    CHECK (nationality IS NULL OR nationality ~ '^[A-Z]{2}$'),

  CONSTRAINT chk_card_subjects_prim_pos_format
    CHECK (primary_position IS NULL OR primary_position ~ '^[A-Z]{1,2}[A-Z]?$|^[1-3]B$')
);


-- create junction table subject_appearances
CREATE TABLE subject_appearances (
  trading_card_id uuid
    REFERENCES trading_cards(item_id) ON DELETE CASCADE,

  subject_id uuid
    REFERENCES card_subjects(id) ON DELETE CASCADE,

  subject_order smallint NOT NULL,      -- Position/order on the card (1–3)
  team_name text,                       -- Team shown for this player on this card
  jersey_number smallint,               -- Jersey number shown on this card
  position text,                        -- Card-specific playing position

  PRIMARY KEY (trading_card_id, subject_id),

  CONSTRAINT uq_subject_appearance_order
    UNIQUE (trading_card_id, subject_order),

  CONSTRAINT chk_subject_order_range
    CHECK (subject_order BETWEEN 1 AND 3),

  CONSTRAINT chk_subject_jersey_number_range
    CHECK (jersey_number IS NULL OR jersey_number BETWEEN 0 AND 99),

  CONSTRAINT chk_subject_appearances_position_format
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
        'superfamily',
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
-- Ensures superfamily is root-only and lower ranks attach only to valid parent ranks.
CREATE OR REPLACE FUNCTION validate_parent_child_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  parent_rank text;
BEGIN
  -- superfamily must not have a parent
  IF NEW.rank = 'superfamily' THEN
    IF NEW.parent_id IS NOT NULL THEN
      RAISE EXCEPTION
        'Taxon with rank "superfamily" cannot have a parent';
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
  IF NEW.rank = 'family' AND parent_rank <> 'superfamily' THEN
    RAISE EXCEPTION
      'Invalid parent rank: family must have parent rank superfamily, got %', parent_rank;

  ELSIF NEW.rank = 'subfamily' AND parent_rank NOT IN ('superfamily', 'family') THEN
    RAISE EXCEPTION
      'Invalid parent rank: subfamily must have parent rank superfamily or family, got %', parent_rank;

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
    CHECK (wingspan_mm IS NULL OR wingspan_mm > 0),  -- Wingspan size in milimeters

  dorsal_main_color text,                            -- Dominant color on dorsal side
  ventral_main_color text,                           -- Dominant color on ventral side
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


-- create table distribution_areas
-- hierarchical geographic distribution areas used of taxon occurrence
CREATE TABLE distribution_areas (
  code text PRIMARY KEY,
  name text NOT NULL,
  area_type text NOT NULL,
  parent_code text
    REFERENCES distribution_areas(code)
    ON DELETE RESTRICT,
  notes text,
  CONSTRAINT chk_dist_areas_area_type
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

-- index for recursive traversal of the geographic distribution area hierarchy
CREATE INDEX idx_dist_areas_parent_code
ON distribution_areas(parent_code);

-- index for lookup of distribution areas by name
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
