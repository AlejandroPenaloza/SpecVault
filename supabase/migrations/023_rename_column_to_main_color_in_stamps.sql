/*
  Project:   SpecVault
  Migration: 023_rename_column_to_main_color_in_stamps
  Author:    Alejandro Penaloza
  Created:   2026/02/23
  
  Purpose: 
  To rename column 'stamps.color' to 'stamps.main_color'.
*/

-- alter table stamps to rename column to main_color
ALTER TABLE stamps
RENAME COLUMN color TO main_color;
