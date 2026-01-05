/*
  Project:   SpecVault
  Migration: 007_columns_created_updated_at_type_to_timestamptz
  Author:    Alejandro Penaloza
  Created:   2026/01/04
  
  Purpose: 
  To change data type of column 'created_at' and 'updated_at' 
  in table 'items' from type timestamp to timestamptz.
*/


-- change of type from timestamp to timestamptz
ALTER TABLE items
  ALTER COLUMN created_at TYPE timestamptz
  USING created_at AT TIME ZONE 'UTC';

ALTER TABLE items
  ALTER COLUMN updated_at TYPE timestamptz
  USING updated_at AT TIME ZONE 'UTC';

