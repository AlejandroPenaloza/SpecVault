/*
  Project:   SpecVault
  Migration: 20260320222219_026_add_indexes_to_taxa
  Author:    Alejandro Penaloza
  Created:   2026/03/20

  Purpose:
  Add indexes to table 'taxa' to support lookups by taxon name
  and traversal of the taxonomic hierarchy.
*/

CREATE INDEX idx_taxa_tax_name
ON taxa(tax_name);

CREATE INDEX idx_taxa_parent_id
ON taxa(parent_id);
