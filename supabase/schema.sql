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
  Updated: 2026/02/23
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
    CHECK (nationality IS NULL OR nationality ~ '^[A-Z]{2}$')

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
  denomination_text text,                 -- "5c", "1 euro" etc.
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
