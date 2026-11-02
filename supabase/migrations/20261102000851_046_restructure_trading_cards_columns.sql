/*
  Project: SpecVault
  Migration: 20261102000851_046_restructure_trading_cards_columns
  Author: Alejandro Penaloza
  Created: 2026/11/01

  Purpose:
  To restructure the columns in table trading_cards, including redefining 
  existing columns, adding and dropping others.
*/


-- rename existing column
ALTER TABLE trading_cards
  RENAME COLUMN topic TO sport_or_topic;

-- add new columns
ALTER TABLE trading_cards
  ADD COLUMN title text,
  ADD COLUMN card_date date,
  ADD COLUMN card_date_precision text,
  ADD COLUMN product_line text,
  ADD COLUMN card_family text,
  ADD COLUMN subset text,
  ADD COLUMN parallel text,
  ADD COLUMN badges text[],
  ADD COLUMN tournament text,
  ADD COLUMN theme text,
  ADD COLUMN front_orientation text,
  ADD COLUMN back_orientation text,
  ADD COLUMN is_wrapper_stored boolean NOT NULL DEFAULT false,
  ADD COLUMN autograph_type text,
  ADD COLUMN product_type text,
  ADD COLUMN available_from_date date,
  ADD COLUMN available_to_date date,
  ADD COLUMN print_run integer;

-- data migration
-- convert existing year values
UPDATE trading_cards
SET
  card_date = make_date(year, 1, 1),
  card_date_precision = 'year'
WHERE year IS NOT NULL;

-- preserve existing autograph information
UPDATE trading_cards
SET autograph_type =
  CASE
    WHEN is_autographed
      THEN 'Autographed - type unknown'
    ELSE 'Not autographed'
  END;

-- synchronize existing parent records
UPDATE items AS i
SET is_autographed =
  (tc.autograph_type <> 'Not autographed')
FROM trading_cards AS tc
WHERE i.id = tc.item_id
  AND i.is_autographed IS DISTINCT FROM
      (tc.autograph_type <> 'Not autographed');

-- make autograph classification mandatory
ALTER TABLE trading_cards
  ALTER COLUMN autograph_type SET NOT NULL,
  ALTER COLUMN autograph_type
    SET DEFAULT 'Not autographed';

-- remove columns whose data has been migrated.
ALTER TABLE trading_cards
  DROP COLUMN year,
  DROP COLUMN is_autographed;
