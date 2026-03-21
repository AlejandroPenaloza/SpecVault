/*
  Project:   SpecVault
  Migration: 20260321055313_028_create_table_specimens
  Author:    Alejandro Penaloza
  Created:   2026/03/21

  Purpose:
  To create table 'specimens', which represents owned Lepidoptera 
  specimen records for the current project scope.
  It supports one specimen per represented species/subspecies through a 
  unique reference to table 'taxa'.
*/


-- create table specimens
CREATE TABLE specimens (
  item_id uuid PRIMARY KEY
    REFERENCES items(id)
    ON DELETE CASCADE,

  taxon_id uuid NOT NULL
    REFERENCES taxa(id)
    ON DELETE RESTRICT,

  sex text
    CHECK (sex IN (
      'male', 
      'female', 
      'unknown'
    )
  ),

  wingspan_mm numeric(5,2)
    CHECK (wingspan_mm IS NULL OR wingspan_mm > 0),

  main_color text,
  notes text,

  CONSTRAINT uq_specimens_taxon_id
    UNIQUE (taxon_id)
);
