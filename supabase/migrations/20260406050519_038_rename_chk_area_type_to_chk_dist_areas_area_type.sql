/*
  Project:   SpecVault
  Migration: 20260406050519_038_rename_chk_area_type_to_chk_dist_areas_area_type
  Author:    Alejandro Penaloza
  Created:   2026/04/06

  Purpose:
    To rename constraint chk_area_type in table
    distribution_areas for clearer naming consistency.
*/


-- rename constraint
ALTER TABLE distribution_areas
RENAME CONSTRAINT chk_area_type
TO chk_distribution_areas_area_type;
