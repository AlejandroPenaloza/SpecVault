/*
  Project:   SpecVault
  Migration: 20260329043117_031_create_table_taxon_regions
  Author:    Alejandro Penaloza
  Created:   2026/03/28

  Purpose:
  To create table 'taxon_regions', which represents the
  many-to-many relation between taxa and geographic regions
  where they occur. 
  It is one of the tables used for subcollection Lepidoptera.
  It supports taxon distribution records
  and efficient lookup by both taxon and region.
*/


-- create table taxon_regions
CREATE TABLE taxon_regions (
  taxon_id uuid NOT NULL
    REFERENCES taxa(id)
    ON DELETE CASCADE,
  region_code text NOT NULL
    REFERENCES regions(code)
    ON DELETE RESTRICT,
  occurrence_status text
    CHECK (
      occurrence_status IS NULL OR occurrence_status IN (
        'present',
        'native',
        'endemic',
        'introduced',
        'uncertain'
      )
    ),
  notes text,
  PRIMARY KEY (taxon_id, region_code)
);

-- index for lookup of taxon-region rows by region
CREATE INDEX idx_taxon_regions_region_code
ON taxon_regions(region_code);

-- index for lookup of taxon-region rows by taxon
CREATE INDEX idx_taxon_regions_taxon_id
ON taxon_regions(taxon_id);
