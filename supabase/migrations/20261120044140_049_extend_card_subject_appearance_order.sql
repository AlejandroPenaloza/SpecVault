/*
  Project: SpecVault
  Migration: 20261120044140_049_extend_card_subject_appearance_order
  Author: Alejandro Penaloza
  Created: 2026/11/19

  Purpose: extend card subject appearance order in card for a maximum of 4.
  That is, to support up to four subjects per trading card.

*/


-- expands allowed subject order from 1–3 to 1–4
-- existing smallint column and uniqueness constraint remain unchanged
ALTER TABLE subject_appearances
  DROP CONSTRAINT chk_subject_order_range;

ALTER TABLE subject_appearances
  ADD CONSTRAINT chk_subject_order_range
  CHECK (subject_order BETWEEN 1 AND 4);
