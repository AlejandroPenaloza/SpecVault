/*
  Project: SpecVault
  Migration: 20261128173827_standardize_uuid_generation
  Author: Alejandro Penaloza
  Created: 2026/11/28

  Purpose: 
    Standardize UUID generation using PostgreSQL's native gen_random_uuid() function.
    Existing UUID values and foreign key relationships are preserved.
*/


ALTER TABLE public.card_subjects
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

ALTER TABLE public.taxa
  ALTER COLUMN id SET DEFAULT gen_random_uuid();
