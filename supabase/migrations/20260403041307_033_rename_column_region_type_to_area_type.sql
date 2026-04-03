/*
  Project:   SpecVault
  Migration: 20260403041307_033_rename_column_region_type_to_area_type
  Author:    Alejandro Penaloza
  Created:   2026/04/02

  Purpose:
  To rename column 'region_type' from table 'regions' to 'area_type'. 
  The old name seemed less descriptive and accurate to represent the 
  biogeographical range where the specimens occur.
*/


-- rename column region_type -> area_type
ALTER TABLE regions
RENAME COLUMN region_type TO area_type;
