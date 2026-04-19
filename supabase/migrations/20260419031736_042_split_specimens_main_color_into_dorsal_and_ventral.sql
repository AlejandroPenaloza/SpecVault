/*
  Project: SpecVault
  Migration: 20260419031736_042_split_specimens_main_color_into_dorsal_and_ventral
  Author: Alejandro Penaloza
  Created: 2026/04/18

  Purpose:
   To replace column 'main_color' in table 'specimens' with dorsal and ventral main color 
   columns for more accurate Lepidoptera specimen physical attributes description.
*/


-- create columns dorsal_main_color, ventral_main_color
ALTER TABLE specimens
ADD COLUMN dorsal_main_color text,
ADD COLUMN ventral_main_color text;

-- no data yet, so column main_color is dropped
ALTER TABLE specimens
DROP COLUMN main_color;
