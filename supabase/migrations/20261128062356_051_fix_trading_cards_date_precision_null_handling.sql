/*
  Project: SpecVault
  Migration: 20261128062356_051_fix_trading_cards_date_precision_null_handling
  Author: Alejandro Penaloza
  Created: 2026/11/28

  Purpose:
      Fix NULL handling in the trading card date precision constraint. 
      A recorded card date must have an associated date precision.
*/

ALTER TABLE public.trading_cards
  DROP CONSTRAINT chk_trading_cards_date_precision,
  ADD CONSTRAINT chk_trading_cards_date_precision
  CHECK (
    (card_date IS NULL AND card_date_precision IS NULL)
    OR (
      card_date IS NOT NULL
      AND card_date_precision IS NOT NULL
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
  