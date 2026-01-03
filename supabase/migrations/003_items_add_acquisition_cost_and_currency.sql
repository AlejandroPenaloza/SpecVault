/*
  Project:   SpecVault
  Migration: 003_items_add_acquisition_cost_and_currency
  Author:    Alejandro Penaloza
  Created:   2026/01/01
  
  Purpose:
  To add columns 'acquisition_cost' and 'acquisition currency', 
  and to include constraints 'acquisition_cost_non_negative' and 
  'acquisition_currency_format'. 
*/


-- Add acquisition cost (exact monetary value)
ALTER TABLE items
ADD COLUMN acquisition_cost numeric(10,2);

-- Add acquisition currency (ISO-4217, default USD)
ALTER TABLE items
ADD COLUMN acquisition_currency char(3) DEFAULT 'USD';

-- Enforce non-negative acquisition cost
ALTER TABLE items
ADD CONSTRAINT acquisition_cost_non_negative
CHECK (acquisition_cost IS NULL OR acquisition_cost >= 0);

-- Enforce valid ISO currency format (3 uppercase letters)
ALTER TABLE items
ADD CONSTRAINT acquisition_currency_format
CHECK (acquisition_currency ~ '^[A-Z]{3}$');
