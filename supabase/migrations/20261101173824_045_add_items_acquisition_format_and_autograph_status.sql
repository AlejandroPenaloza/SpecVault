/*
  Project: SpecVault
  Migration: 20261101173824_add_items_acquisition_format_and_autograph_status
  Author: Alejandro Penaloza
  Created: 2026/11/01

  Purpose: 
  To add columns acquisition_format which describes whether the item was obtained individually 
  or in a group configuration, and is_autographed to store whether the item is autographed.
*/


-- add shared acquisition and autograph attributes to items
ALTER TABLE items
  ADD COLUMN acquisition_format text,
  ADD COLUMN is_autographed boolean NOT NULL DEFAULT false;
