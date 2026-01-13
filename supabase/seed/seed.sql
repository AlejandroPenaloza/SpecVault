/*
  Project: SpecVault
  File: seed.sql
  Alejandro Penaloza
  Created: 2026/01/02
  Updated: 2026/01/13

  Purpose:
  Insert representative sample data for development
  and demonstration.
*/

-- Included to clear existing demo data (if necessary)
TRUNCATE TABLE coins CASCADE;
TRUNCATE TABLE items CASCADE;

-- Insert demo item record (explicit UUID)
INSERT INTO items (
  id,
  name,
  subcollection,
  theme,
  acquired_date
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  '1914 1 Cent',
  'coins',
  'US Coins',
  '2020-01-01'
);

-- Insert corresponding coin record (one row)
INSERT INTO coins (
  item_id,
  denomination,
  year,
  country,
  mint,
  composition,
  edge,
  weight,
  diameter,
  condition,
  notes
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  0.01,
  1914,
  'United States',
  'US Mint (Philadelphia)',
  'Bronze',
  'Smooth',
  3.11,
  19.05,
  'Circulated',
  'Specification from ucoin.net.'
);

-- Insert another demo item record
-- single transaction using common table expression 
-- and returning result (generated id)
BEGIN;

WITH new_item AS (
  INSERT INTO items (
    name, 
    acquired_date, 
    subcollection,
    theme,
    obtained_from
  )
  VALUES (
    '1 Bolivar 10/05/1989', 
    '2024-08-03', 
    'banknotes',
    'Venezuelan banknotes', 
    'Ebay/geraval'
  )
  RETURNING id
)
INSERT INTO banknotes (
  item_id,
  denomination,
  currency, 
  country, 
  issuer, 
  issue_date, 
  issue_date_precision, 
  width, 
  height, 
  series
)
SELECT
  id,
  1.00, 
  'Bolivares',
  'Venezuela', 
  'Banco Central de Venezuela (BCV)', 
  '1989-05-10', 
  'day', 
  115, 
  55, 
  'A51283218'
FROM new_item;

COMMIT;
