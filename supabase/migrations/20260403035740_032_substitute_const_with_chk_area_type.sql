/*
  Project:   SpecVault
  Migration: 20260403035740_032_substitute_const_with_chk_area_type
  Author:    Alejandro Penaloza
  Created:   2026/04/02

  Purpose:
  To substitute (update) the controlled vocabulary to better represent
  geographic and biogeographic occurrence and distribution areas, by 
  dropping constraint 'chk_regions_type' and adding constraint 
  'chk_area_type', in column 'region_type' from table 'regions'.
*/


-- drop old constraint
ALTER TABLE regions
DROP CONSTRAINT chk_regions_type;

-- add new constraint
ALTER TABLE regions
ADD CONSTRAINT chk_area_type
CHECK (
  region_type IN (
    'hemisphere',
    'continent',
    'country',
    'state',
    'province',
    'department',
    'biogeographic_region',
    'ecoregion',
    'habitat_zone',
    'other'
  )
);
