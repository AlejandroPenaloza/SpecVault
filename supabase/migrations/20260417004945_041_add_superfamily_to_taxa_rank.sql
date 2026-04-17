/*
  Project: SpecVault
  Migration: 20260417004945_041_add_superfamily_to_taxa_rank
  Author: Alejandro Penaloza
  Created: 2026/04/16

  Purpose:
  To add rank 'superfamily' to table 'taxa' and update
  the parent-child rank validation trigger accordingly.
*/


-- Drop trigger first
DROP TRIGGER IF EXISTS trg_validate_parent_child_rank ON taxa;

-- Drop and recreate rank constraint
ALTER TABLE taxa
DROP CONSTRAINT chk_taxa_rank;

ALTER TABLE taxa
ADD CONSTRAINT chk_taxa_rank
CHECK (
  rank IN (
    'superfamily',
    'family',
    'subfamily',
    'tribe',
    'subtribe',
    'genus',
    'species',
    'subspecies'
  )
);

-- Replace validation function
CREATE OR REPLACE FUNCTION validate_parent_child_rank()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  parent_rank text;
BEGIN
  -- superfamily must not have a parent
  IF NEW.rank = 'superfamily' THEN
    IF NEW.parent_id IS NOT NULL THEN
      RAISE EXCEPTION
        'Taxon with rank "superfamily" cannot have a parent';
    END IF;

    RETURN NEW;
  END IF;

  -- all non-superfamily ranks must have a parent
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
  IF NEW.rank = 'family' AND parent_rank <> 'superfamily' THEN
    RAISE EXCEPTION
      'Invalid parent rank: family must have parent rank superfamily, got %', parent_rank;

  ELSIF NEW.rank = 'subfamily' AND parent_rank NOT IN ('superfamily', 'family') THEN
    RAISE EXCEPTION
      'Invalid parent rank: subfamily must have parent rank superfamily or family, got %', parent_rank;

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

-- Recreate trigger
CREATE TRIGGER trg_validate_parent_child_rank
BEFORE INSERT OR UPDATE OF rank, parent_id
ON taxa
FOR EACH ROW
EXECUTE FUNCTION validate_parent_child_rank();
