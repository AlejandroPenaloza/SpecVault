/*
  Project:   SpecVault
  Migration: 20260321041149_027_enforce_taxa_parent_child_rank
  Author:    Alejandro Penaloza
  Created:   2026/03/21

  Purpose:
    Enforce biologically valid parent-child rank combinations in taxa.

  Rules enforced:
    - family must be a root node (parent_id must be NULL)
    - subfamily must have parent family
    - tribe must have parent family or subfamily
    - subtribe must have parent family, subfamily, or tribe
    - genus must have parent family, subfamily, tribe, or subtribe
    - species must have parent genus
    - subspecies must have parent species

  This design allows omitted intermediate ranks above genus
  (for example genus directly under family or subfamily).
  Species and subspecies remain strict.
*/

CREATE OR REPLACE FUNCTION validate_parent_child_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  parent_rank text;
BEGIN
  -- family must not have a parent
  IF NEW.rank = 'family' THEN
    IF NEW.parent_id IS NOT NULL THEN
      RAISE EXCEPTION
        'Taxon with rank "family" cannot have a parent';
    END IF;

    RETURN NEW;
  END IF;

  -- all non-family ranks must have a parent
  IF NEW.parent_id IS NULL THEN
    RAISE EXCEPTION
      'Taxon with rank "%" must have a parent', NEW.rank;
  END IF;

  -- prevent self-parenting
  IF NEW.parent_id = NEW.id THEN
    RAISE EXCEPTION
      'Taxon cannot be its own parent';
  END IF;

  -- look up parent rank
  SELECT t.rank
  INTO parent_rank
  FROM taxa t
  WHERE t.id = NEW.parent_id;

  -- validate allowed parent-child combinations
  IF NEW.rank = 'subfamily' AND parent_rank <> 'family' THEN
    RAISE EXCEPTION
      'Invalid parent rank: subfamily must have parent rank family, got %', parent_rank;

  ELSIF NEW.rank = 'tribe' AND parent_rank NOT IN ('family', 'subfamily') THEN
    RAISE EXCEPTION
      'Invalid parent rank: tribe must have parent rank family or subfamily, got %', parent_rank;

  ELSIF NEW.rank = 'subtribe' AND parent_rank NOT IN ('family', 'subfamily', 'tribe') THEN
    RAISE EXCEPTION
      'Invalid parent rank: subtribe must have parent rank family, subfamily, or tribe, got %', parent_rank;

  ELSIF NEW.rank = 'genus' AND parent_rank NOT IN ('family', 'subfamily', 'tribe', 'subtribe') THEN
    RAISE EXCEPTION
      'Invalid parent rank: genus must have parent rank family, subfamily, tribe, or subtribe, got %', parent_rank;

  ELSIF NEW.rank = 'species' AND parent_rank <> 'genus' THEN
    RAISE EXCEPTION
      'Invalid parent rank: species must have parent rank genus, got %', parent_rank;

  ELSIF NEW.rank = 'subspecies' AND parent_rank <> 'species' THEN
    RAISE EXCEPTION
      'Invalid parent rank: subspecies must have parent rank species, got %', parent_rank;
  END IF;

  RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_parent_child_rank ON taxa;

CREATE TRIGGER trg_validate_parent_child_rank
BEFORE INSERT OR UPDATE OF rank, parent_id
ON taxa
FOR EACH ROW
EXECUTE FUNCTION validate_parent_child_rank();
