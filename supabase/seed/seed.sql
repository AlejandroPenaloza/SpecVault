/*
  Project: SpecVault
  File: seed.sql
  Alejandro Penaloza
  Created: 2026/01/02
  Updated: 2026/04/19

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


-- Insert single demo trading card row to base table items
-- Subsequently, to tables trading_cards, players, and junction 
-- table trading_card_players
BEGIN;

WITH
-- base item and capture id
new_item AS (
  INSERT INTO items (name, acquired_date, subcollection, theme, obtained_from)
  VALUES (
    'Bobby Abreu Baseball Card Fleer 2001',
    '2014-11-15',
    'trading cards',
    'Baseball Cards',
    'Previous collection'
  )
  RETURNING id
),

-- trading_cards row using new item id
new_card AS (
  INSERT INTO trading_cards (
    item_id, topic, brand, set_name, year, card_number, is_autographed
  )
  SELECT
    id,
    'Baseball',
    'Fleer',
    'Fleer 2001',
    2001,
    '76',
    false
  FROM new_item
  RETURNING item_id
),

-- player row
new_player AS (
  INSERT INTO players (first_name, last_name, nationality, birth_year, primary_position)
  VALUES ('Bobby', 'Abreu', 'VE', 1974, 'OF')
  RETURNING id
)

-- 4) Link player to the card (junction row)
INSERT INTO trading_card_players (
  trading_card_id, player_id, player_order, team_name, jersey_number, position
)
SELECT
  (SELECT item_id FROM new_card),
  (SELECT id FROM new_player),
  1,
  'Philadelphia Phillies',
  53,
  'OF';

COMMIT;


-- Insert another demo item record
-- single transaction using common table expression 
-- and returning result (generated id)
BEGIN;

WITH new_item AS (
  INSERT INTO items (
    name, acquired_date, subcollection, theme, obtained_from
  )
  VALUES (
    '3 Cents USA Stamp 1952',
    '2022-05-30',
    'stamps',
    'USA',
    'Mount Rushmore National Memorial gift shop; Keystone, SD'
  )
  RETURNING id
)
INSERT INTO stamps (
  item_id,
  country,
  issue_year,
  issue_date,
  denomination_text,
  currency,
  stamp_type,
  format,
  perforation,
  printing_method,
  main_color,
  condition,
  catalog_system,
  catalog_number,
  notes
)
SELECT
  id,
  'USA',
  1952,
  '1952-08-11',
  '3 cents',
  'USD',
  'commemorative',
  'single',
  '10 1/2 x 11',
  'rotary press',
  'green',
  'Mint',
  'Scott',
  'US1011',
  'Commemorates the 25th anniversary of the Mount Rushmore National Memorial. 
    Obtained there during road trip to South Dakota.'
FROM new_item;

COMMIT;


-- 2026-04-17: first insert of data for subcollection Lepidoptera, by using two transactions.
-- The first one adds the distribution area (only one) into distribution_areas and the taxa into taxa

BEGIN;

-- Distribution area insert
INSERT INTO distribution_areas (
  code,
  name,
  area_type,
  parent_code,
  notes
)
VALUES (
  'NEO',
  'Neotropical realm',
  'biogeographic_region',
  NULL,
  'Seed distribution area for Lepidoptera specimen data'
);

-- Superfamily
INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
VALUES
  ('Papilionoidea', 'superfamily', NULL, 'Latreille, 1802', 'Seed taxonomy row');

-- Families
INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Nymphalidae', 'family', id, 'Rafinesque, 1815', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Papilionoidea' AND rank = 'superfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Pieridae', 'family', id, 'Swainson, 1820', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Papilionoidea' AND rank = 'superfamily';

-- Subfamilies
INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Charaxinae', 'subfamily', id, 'Doherty, 1886', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalidae' AND rank = 'family';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Cyrestinae', 'subfamily', id, 'Guenée, 1865', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalidae' AND rank = 'family';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Nymphalinae', 'subfamily', id, 'Swainson, 1827', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalidae' AND rank = 'family';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Morphinae', 'subfamily', id, 'Newman, 1834', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalidae' AND rank = 'family';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Heliconiinae', 'subfamily', id, 'Swainson, 1822', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalidae' AND rank = 'family';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Coliadinae', 'subfamily', id, 'Swainson, 1827', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Pieridae' AND rank = 'family';

-- Tribes
INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Anaeini', 'tribe', id, 'Reuter, 1896', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Charaxinae' AND rank = 'subfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Cyrestini', 'tribe', id, 'Guenée, 1865', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Cyrestinae' AND rank = 'subfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Coeini', 'tribe', id, 'Scudder, 1893', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Nymphalinae' AND rank = 'subfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Brassolini', 'tribe', id, 'Boisduval, 1836', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Morphinae' AND rank = 'subfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Heliconiini', 'tribe', id, 'Swainson, 1822', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Heliconiinae' AND rank = 'subfamily';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Coliadini', 'tribe', id, 'Swainson, 1821', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Coliadinae' AND rank = 'subfamily';

-- Genera
INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Consul', 'genus', id, 'Hübner, 1807', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Anaeini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Memphis', 'genus', id, 'Hübner, 1819', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Anaeini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Marpesia', 'genus', id, 'Hübner, 1818', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Cyrestini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Smyrna', 'genus', id, 'Hübner, 1823', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Coeini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Caligo', 'genus', id, 'Hübner, 1819', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Brassolini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Heliconius', 'genus', id, 'Kluk, 1780', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Heliconiini' AND rank = 'tribe';

INSERT INTO taxa (tax_name, rank, parent_id, authority, notes)
SELECT 'Phoebis', 'genus', id, 'Hübner, 1819', 'Seed taxonomy row'
FROM taxa
WHERE tax_name = 'Coliadini' AND rank = 'tribe';

COMMIT;


-- 2026-04-18: inserted single demo specimen ('Consul fabius') for subcollection Lepidoptera.

-- inserting in taxa
BEGIN;

-- inserting in taxa
WITH new_species AS (
  INSERT INTO taxa (
    tax_name,
    rank,
    parent_id,
    authority,
    type_locality,
    notes
  )
  SELECT
    'fabius',
    'species',
    t.id,
    'Fabricius, 1775',
    'Peru',
    'Obtained as genus Anaea (junior synonym).'
  FROM taxa t
  WHERE t.tax_name = 'Consul'
    AND t.rank = 'genus'
  RETURNING id
),
-- inserting in items
new_item AS (
  INSERT INTO items (
    name,
    description,
    acquired_date,
    subcollection,
    acquisition_cost,
    obtained_from
  )
  VALUES (
    'Consul fabius specimen',
    'Lepidoptera specimen',
    DATE '2025-08-17',
    'lepidoptera',
    6.47,
    'BicBugs'
  )
  RETURNING id
),
-- inserting in specimens
new_specimen AS (
  INSERT INTO specimens (
    item_id,
    taxon_id,
    sex,
    dorsal_main_color,
    ventral_main_color,
    notes
  )
  SELECT
    ni.id,
    ns.id,
    'unknown',
    'red',
    'brown',
    'Obtained as genus Anaea (junior synonym).'
  FROM new_item ni
  CROSS JOIN new_species ns
  RETURNING taxon_id
)
-- inserting in taxon_dist_areas
INSERT INTO taxon_dist_areas (
  taxon_id,
  area_code,
  occurrence_status
)
SELECT
  taxon_id,
  'NEO',
  'present'
FROM new_specimen;

COMMIT;


-- 2026-04-19: inserted single demo specimen ('Memphis clytemnestra') for subcollection Lepidoptera.

BEGIN;

-- inserting in taxa
WITH new_species AS (
  INSERT INTO taxa (
    tax_name,
    rank,
    parent_id,
    authority,
    type_locality,
    notes
  )
  SELECT
    'clytemnestra',
    'species',
    t.id,
    'Cramer, 1777',
    'Peru',
    'Obtained as genus Anaea (junior synonym).'
  FROM taxa t
  WHERE t.tax_name = 'Memphis'
    AND t.rank = 'genus'
  RETURNING id
),
-- inserting in items
new_item AS (
  INSERT INTO items (
    name, 
    description, 
    acquired_date, 
    subcollection,
    acquisition_cost, 
    obtained_from
  )
  VALUES (
    'Memphis clytemnestra specimen',
    'Lepidoptera specimen',
    DATE '2025-08-17',
    'lepidoptera',
    6.47,
    'BicBugs'
  )
  RETURNING id
),
-- inserting in specimens
new_specimen AS (
  INSERT INTO specimens (
    item_id, 
    taxon_id, 
    sex,
    dorsal_main_color, 
    ventral_main_color,
    notes)
  SELECT 
    ni.id, 
    ns.id, 
    'unknown',
    'brown', 
    'brown', 
    'Obtained as genus Anaea (junior synonym).'
  FROM new_item ni
  CROSS JOIN new_species ns
  RETURNING taxon_id
)
-- inserting in taxon_dist_areas
INSERT INTO taxon_dist_areas (
  taxon_id, 
  area_code, 
  occurrence_status
)
SELECT 
  taxon_id, 
  'NEO', 
  'present'
FROM new_specimen;

COMMIT;
