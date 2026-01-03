/*
  Project: SpecVault
  File: seed.sql
  Alejandro Penaloza
  Created: 2026/01/02

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

-- Insert corresponding coin record
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
