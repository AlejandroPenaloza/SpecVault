/*
  Project:   SpecVault
  Migration: 20260320205900_025_add_column_type_locality
  Author:    Alejandro Penaloza
  Created:   2026/03/20

  Purpose:
  Add field 'type_locality' to table 'taxa' in order to store
  the scientific type locality of a taxon, when relevant.
*/

ALTER TABLE taxa
ADD COLUMN type_locality text;
