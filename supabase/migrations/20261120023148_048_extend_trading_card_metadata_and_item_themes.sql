/*
  Project: SpecVault
  Migration: 20261120023148_048_extend_trading_card_metadata_and_item_themes
  Author: Alejandro Penaloza
  Created: 2026/11/19

  Purpose: 
  To add trading_card columns:
  
  card_date_format: format in which the date appears on the card. 
  Independent of card_date and card_date_precision.

  relic_type: material embedded in the card, e.g. Jersey, Patch, Bat. 
  NULL indicates no relic is recorded.

  thickness: card thickness measured in points (pt). Default: 35 pt.

  Include card_date validation with constraint chk_trading_cards_date_format
  To treat facsimile signatures in trading cards as non-authentic autographs, and subsequent data update.
  Include an update-autograph synchronization function to work between trading_cards.autogrpah_type and items.is_autographed.
  To convert items.theme from text into text[].
*/


-- add columns card_date, relic_type, thickness
ALTER TABLE trading_cards
  ADD COLUMN card_date_format text,
  ADD COLUMN relic_type text,
  ADD COLUMN thickness numeric NOT NULL DEFAULT 35;


-- NULL means the printed date format was not recorded
-- otherwise, the format must match card_date_precision
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_date_format
CHECK (
  card_date_format IS NULL
  OR (
    card_date_precision IS NOT NULL
    AND (
      (
        card_date_precision = 'year'
        AND card_date_format IN (
          'YYYY',
          'YY'
        )
      )
      OR (
        card_date_precision = 'month'
        AND card_date_format IN (
          'YYYY-MM',
          'MM/YYYY',
          'MM/YY'
        )
      )
      OR (
        card_date_precision = 'day'
        AND card_date_format IN (
          'YYYY-MM-DD',
          'MM/DD/YYYY',
          'MM/DD/YY',
          'DD/MM/YYYY',
          'DD/MM/YY'
        )
      )
    )
  )
);


-- thickness must be positive, units as points (pt)
-- NULL is prohibited by the column definition
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_thickness_positive
CHECK (thickness > 0);


-- trading_cards.autograph_type is authoritative for cards
-- 'Not autographed' and 'Facsimile' map to FALSE, 
-- all other non-NULL classifications map to TRUE

-- existing synchronization trigger remains unchanged
CREATE OR REPLACE FUNCTION sync_trading_card_autograph()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE items
  SET is_autographed =
    (NEW.autograph_type NOT IN (
      'Not autographed',
      'Facsimile'
    ))
  WHERE id = NEW.item_id
    AND is_autographed IS DISTINCT FROM
      (NEW.autograph_type NOT IN (
        'Not autographed',
        'Facsimile'
      ));

  RETURN NEW;
END;
$$;


-- reject direct changes to items.is_autographed when they contradict the trading card's classification

-- existing validation trigger remains unchanged
CREATE OR REPLACE FUNCTION validate_item_autograph()
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
       (v_autograph_type NOT IN (
         'Not autographed',
         'Facsimile'
       ))
  THEN
    RAISE EXCEPTION
      'Autograph status conflicts with trading card for item %',
      NEW.id
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;


-- previously, facsimile signatures were interpreted as
-- autographed because they differed from 'Not autographed'

-- correct existing parent records under the new logic
UPDATE items AS i
SET is_autographed = FALSE
FROM trading_cards AS tc
WHERE i.id = tc.item_id
  AND tc.autograph_type = 'Facsimile'
  AND i.is_autographed IS DISTINCT FROM FALSE;


-- PostgreSQL text[] supports multiple themes per item
--
-- existing values:
--   'Baseball' -> {'Baseball'}
--   NULL       -> {}

-- existing strings are preserved as single elements
-- (comma-separated values are not automatically split)
-- remove any existing scalar text default before conversion
ALTER TABLE items
  ALTER COLUMN theme DROP DEFAULT;

ALTER TABLE items
  ALTER COLUMN theme TYPE text[]
  USING CASE
    WHEN theme IS NULL THEN ARRAY[]::text[]
    ELSE ARRAY[theme]
  END;

-- New records receive an empty array by default.
ALTER TABLE items
  ALTER COLUMN theme SET DEFAULT ARRAY[]::text[];

-- Prevent NULL arrays; use {} for items without themes.
ALTER TABLE items
  ALTER COLUMN theme SET NOT NULL;
