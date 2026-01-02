/*
  Project:   SpecVault
  Migration: 002_items_replace_category_w_subcollection_and_theme
  Author:    Alejandro Penaloza
  Created:   2026/01/01
  
  Purpose:
  To add columns 'subcollection' and 'theme' while eliminating column 'category'. 
*/


-- add columns subcollection, theme
ALTER TABLE items
ADD COLUMN subcollection text,
ADD COLUMN theme text;

-- eliminate column category
ALTER TABLE items
DROP COLUMN category;
