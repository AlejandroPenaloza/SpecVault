/*
  Project:   SpecVault
  Migration: 010_add_constraint_issue_date_consistency
  Author:    Alejandro Penaloza
  Created:   2026/01/10
  
  Purpose: 
  To add constraint 'banknotes_issue_date_consistency' to be used in column 
  'issue_date' from table 'banknotes'. 
  It enforces consistency so that either both 'issue_date' and 
  'issue_date_precision' are NULL or neither.
  */
  
  
ALTER TABLE banknotes
ADD CONSTRAINT banknotes_issue_date_consistency
CHECK (
  (issue_date IS NULL AND issue_date_precision IS NULL)
  OR
  (issue_date IS NOT NULL AND issue_date_precision IS NOT NULL)
);
