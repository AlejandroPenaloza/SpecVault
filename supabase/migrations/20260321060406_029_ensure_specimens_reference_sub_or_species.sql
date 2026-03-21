/*
  Project:   SpecVault
  Migration: 20260321060406_029_ensure_specimens_reference_sub_or_species
  Author:    Alejandro Penaloza
  Created:   2026/03/21

  Purpose:
  To create a function check_spec_taxon_rank() and creates trigger 
  trg_spec_check_taxon_rank to validate that each specimen points only to 
  a species- or subspecies-level taxon.
*/


-- create function check_spec_taxon_rank()
-- Ensure specimen records reference only species- or subspecies-level taxa.
CREATE OR REPLACE FUNCTION check_spec_taxon_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_rank text;
BEGIN
  SELECT rank
  INTO v_rank
  FROM taxa
  WHERE id = NEW.taxon_id;

  IF v_rank IS NULL THEN
    RAISE EXCEPTION
      'taxon_id % does not exist in taxa',
      NEW.taxon_id;
  END IF;

  IF v_rank NOT IN ('species', 'subspecies') THEN
    RAISE EXCEPTION
      'specimens.taxon_id must reference a taxon of rank species or subspecies (got %)',
      v_rank;
  END IF;

  RETURN NEW;
END;
$$;

-- create trigger trg_spec_check_taxon_rank
-- Validate that each specimen points only to a species- or subspecies-level taxon.
CREATE TRIGGER trg_spec_check_taxon_rank
BEFORE INSERT OR UPDATE OF taxon_id
ON specimens
FOR EACH ROW
EXECUTE FUNCTION check_spec_taxon_rank();
