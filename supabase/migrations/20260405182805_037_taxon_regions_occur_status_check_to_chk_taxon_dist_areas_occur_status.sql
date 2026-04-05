/*
  Project:   SpecVault
  Migration: 
    20260405182805_037_taxon_regions_occur_status_check_to_chk_taxon_dist_areas_occur_status
  Author:    Alejandro Penaloza
  Created:   2026/04/05

  Purpose:
    To rename constraint check defined in table taxon_dist_areas but unnamed within, 
    by querying its assigned name by Supabase: taxon_regions_occurrence_status_check.
    
    This update seeks consistency with previous changes in this table, 
    even though it does not represent a change in functionality.
*/


ALTER TABLE taxon_dist_areas
RENAME CONSTRAINT taxon_regions_occurrence_status_check 
TO chk_taxon_dist_areas_occur_status;
