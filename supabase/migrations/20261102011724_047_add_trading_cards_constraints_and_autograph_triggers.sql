/*
  Project: SpecVault
  Migration: 20261102011724_047_add_trading_cards_constraints_and_autograph_triggers
  Author: Alejandro Penaloza
  Created: 2026/11/01

  Purpose: 
  To add trading-card constraints and autograph synchronization/validation triggers.
*/


-- card date precision
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_date_precision
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
);


-- card orientation
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_front_orientation
CHECK (
  front_orientation IS NULL
  OR front_orientation IN ('portrait', 'landscape')
);

ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_back_orientation
CHECK (
  back_orientation IS NULL
  OR back_orientation IN ('portrait', 'landscape')
);


-- print run boundaries
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_print_run_positive
CHECK (
  print_run IS NULL OR print_run > 0
);


/*
  Topps NOW purchasing window

  April 4, 2016: launch of the original Topps NOW baseball program. 
  This is the minimum valid purchasing-window start.
*/
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_topps_now_start_date
CHECK (
  available_from_date IS NULL
  OR available_from_date >= DATE '2016-04-04'
);

-- Store the historical explanation in PostgreSQL metadata
COMMENT ON CONSTRAINT chk_trading_cards_topps_now_start_date
ON trading_cards
IS 'Minimum purchasing-window start date: April 4, 2016, the launch of the original Topps NOW baseball program.';

-- Both dates may be NULL. 
-- When both are present, the start date cannot be later than the end date.
ALTER TABLE trading_cards
ADD CONSTRAINT chk_trading_cards_availability_dates
CHECK (
  available_from_date IS NULL
  OR available_to_date IS NULL
  OR available_from_date <= available_to_date
);

/*
  Autograph synchronization function

  trading_cards.autograph_type is authoritative for trading cards. 
  The value 'Not autographed' maps to false; every other non-NULL value maps to true.
  Locking the parent items row serializes competing changes to the autograph status of the same collectible.
*/
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


/*
  Autograph validation function

  Reject direct changes to items.is_autographed that
  contradict the trading card's autograph classification.
*/
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


/* 
  Create autograph triggers

  Changes to the card classification synchronize the parent.
*/
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
