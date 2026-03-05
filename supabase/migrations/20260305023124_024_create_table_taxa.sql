/*
  Project:   SpecVault
  Migration: 20260305023124_024_create_table_taxa
  Author:    Alejandro Penaloza
  Created:   2026/03/04
  
  Purpose: 
  To create table 'taxa', which represent biological  
  taxonomy for subcollection Lepidoptera.
  It supports hierarchical classification using a 
  self-referencing 'parent_id'.
*/


-- biological taxonomy hierarchy used to classify Lepidoptera specimens
CREATE TABLE taxa (
  id uuid PRIMARY KEY
    DEFAULT uuid_generate_v4(),

  tax_name text NOT NULL,
  rank text NOT NULL,

  parent_id uuid
    REFERENCES taxa(id)
    ON DELETE RESTRICT,

  authority text,     -- e.g. "Linnaeus, 1758"
  common_name text,   -- optional vernacular name
  notes text,

  CONSTRAINT chk_taxa_rank
    CHECK (
      rank IN (
        'family',
        'subfamily',
        'tribe',
        'subtribe',
        'genus',
        'species',
        'subspecies'
      )
    )
);
