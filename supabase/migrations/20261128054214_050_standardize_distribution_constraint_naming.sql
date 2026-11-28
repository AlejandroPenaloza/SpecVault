/*
  Project: SpecVault
  Migration: 20261128054214_standardize_distribution_constraint_naming
  Author: Alejandro Penaloza
  Created: 2026/11/27

  Purpose: adequate constraints naming used in table distribution areas, 
  after finding database auditing discrepancies.
*/


-- Standardize constraint names in distribution_areas
ALTER TABLE public.distribution_areas
  RENAME CONSTRAINT regions_pkey
  TO distribution_areas_pkey;

ALTER TABLE public.distribution_areas
  RENAME CONSTRAINT regions_parent_code_fkey
  TO distribution_areas_parent_code_fkey;


-- Standardize constraint names in taxon_dist_areas
ALTER TABLE public.taxon_dist_areas
  RENAME CONSTRAINT taxon_regions_pkey
  TO taxon_dist_areas_pkey;

ALTER TABLE public.taxon_dist_areas
  RENAME CONSTRAINT taxon_regions_taxon_id_fkey
  TO taxon_dist_areas_taxon_id_fkey;

ALTER TABLE public.taxon_dist_areas
  RENAME CONSTRAINT taxon_regions_region_code_fkey
  TO taxon_dist_areas_area_code_fkey;
