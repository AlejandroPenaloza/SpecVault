/*
  Project:   SpecVault
  Migration: 20260403054034_034_rename_regions_to_distribution_areas
  Author:    Alejandro Penaloza
  Created:   2026/04/03

  Purpose:
    To rename table 'regions' to 'distribution_areas'
    so it represents more accurately geographic and 
    biogeographic occurrence areas used in Lepidoptera 
    distribution data.
*/


ALTER TABLE regions
RENAME TO distribution_areas;

ALTER INDEX idx_regions_parent_code
RENAME TO idx_dist_areas_parent_code;

ALTER INDEX idx_regions_name
RENAME TO idx_dist_areas_name;

ALTER TABLE distribution_areas
RENAME CONSTRAINT chk_regions_not_self_parent TO chk_dist_areas_not_self_parent;
