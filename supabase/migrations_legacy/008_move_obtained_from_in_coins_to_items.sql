/*
  Project:   SpecVault
  Migration: 008_move_obtained_from_in_coins_to_items
  Author:    Alejandro Penaloza
  Created:   2026/01/08
  
  Purpose: 
  To 'move' column "obtained_from" from table 'coins' to 
  table 'items'. This is, to add this column in 'items', 
  migrate existing data from 'coins' to 'items' and finally 
  delete the column from 'coins'.
  */


-- create column 'obtained_from' in 'items'
ALTER TABLE items
ADD COLUMN obtained_from text;

-- migrate existing data in coin's obtained from to item's
UPDATE items i
SET obtained_from = c.obtained_from
FROM coinc c
WHERE c.item_id = i.id
  AND c.obtained_from IS NOT NULL
  AND i.obtained_from IS NULL;

-- eliminate column 'obtained_from' in 'coins'
ALTER TABLE coins
DROP COLUMN obtained_from;
