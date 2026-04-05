/*
  Project:   SpecVault
  Migration: 20260405162338_035_taxon_regions_to_taxon_dist_areas
  Author:    Alejandro Penaloza
  Created:   2026/04/05

  Purpose:
    To rename table 'taxon_regions' to 'taxon_dist_areas'
    to be more accurate about representation and consistent 
    with changes in distribution_areas.
*/


ALTER TABLE taxon_regions
RENAME TO taxon_dist_areas;
