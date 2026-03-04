/*
  Project:   SpecVault
  Migration: 022_create_table_stamps
  Author:    Alejandro Penaloza
  Created:   2026/02/23
  
  Purpose: 
  To create table 'stamps' for subcollection stamps.
*/

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
