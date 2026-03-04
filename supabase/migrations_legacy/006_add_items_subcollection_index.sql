/*
  Project:   SpecVault
  Migration: 006_add_items_subcollection_index
  Author:    Alejandro Penaloza
  Created:   2026/01/01
  
  Purpose:
  To improve lookup performance on items filtered by subcollection. 
*/


-- index of subcollection in items
CREATE INDEX idx_items_subcollection
ON items(subcollection);
