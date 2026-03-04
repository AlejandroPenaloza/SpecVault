/*
  Project:   SpecVault
  Migration: 005_add_coins_weight_diameter_constraints
  Author:    Alejandro Penaloza
  Created:   2026/01/01
  
  Purpose: 
  To enforce positive numeric values through constraints 
  'coins_weight_positive' and 'coins_diameter_positive'.
*/


-- constraints of positivity for weight and diameter
ALTER TABLE coins
ADD CONSTRAINT coins_weight_positive
CHECK (weight IS NULL OR weight > 0);

ALTER TABLE coins
ADD CONSTRAINT coins_diameter_positive
CHECK (diameter IS NULL OR diameter > 0);
-- note that weight/diameter IS NULL is not necessary and used for readibility
