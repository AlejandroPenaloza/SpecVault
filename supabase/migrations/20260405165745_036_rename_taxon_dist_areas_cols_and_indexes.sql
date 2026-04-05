/*
  Project:   SpecVault
  Migration: 20260405162338_035_taxon_regions_to_taxon_dist_areas
  Author:    Alejandro Penaloza
  Created:   2026/04/05

  Purpose:
    To rename column region_code to area_code, so as indexes 
    idx_taxon_regions_region_code, idx_taxon_regions_taxon_id 
    to idx_taxon_dist_areas_area_code, idx_taxon_dist_areas_taxon_id 
    respectively, within table taxon_dist_areas.
*/


-- rename to taxon_dist_areas.area_code
ALTER TABLE taxon_dist_areas
RENAME COLUMN region_code TO area_code;

-- rename taxon_dist_areas indexes
ALTER INDEX idx_taxon_regions_region_code
RENAME TO idx_taxon_dist_areas_area_code;

ALTER INDEX idx_taxon_regions_taxon_id
RENAME TO idx_taxon_dist_areas_taxon_id;
