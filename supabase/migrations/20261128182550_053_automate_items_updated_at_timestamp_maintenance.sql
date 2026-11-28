/*
  Project: SpecVault
  Migration: 20261128182550_053_automate_items_updated_at_timestamp_maintenance
  Author: Alejandro Penaloza
  Created: 2026/11/28

  Purpose:
    Automatically maintain the modification timestamp of items.
    Refresh updated_at whenever an existing items row is updated.
*/


CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_items_set_updated_at
BEFORE UPDATE ON public.items
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
