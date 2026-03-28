/*
  Project:   SpecVault
  Migration: 20260328025523_030_create_table_regions
  Author:    Alejandro Penaloza
  Created:   2026/03/27

  Purpose:
  To create table 'regions' for subcollection Lepidoptera,
  and indexes idx_regions_parent_code, idx_regions_name.
  This table represents hierarchical geographic regions used 
  to describe taxon occurrence/distribution.
  It supports recursive geographic queries through a self-referencing
  parent region structure and related lookup indexes.
*/


-- create table regions
CREATE TABLE regions (
  code text PRIMARY KEY,
  name text NOT NULL,
  region_type text NOT NULL,
  parent_code text
    REFERENCES regions(code)
    ON DELETE RESTRICT,
  notes text,
  CONSTRAINT chk_regions_type
    CHECK (
      region_type IN (
        'continent',
        'country',
        'state',
        'province',
        'department',
        'region',
        'locality',
        'other'
      )
    ),
  CONSTRAINT chk_regions_not_self_parent
    CHECK (parent_code IS NULL OR parent_code <> code)
);

CREATE INDEX idx_regions_parent_code
ON regions(parent_code);

CREATE INDEX idx_regions_name
ON regions(name);
