# SpecVault

<p align="center">
<img
src="https://raw.githubusercontent.com/AlejandroPenaloza/SpecVault/main/docs/SpecVault_logo_1.jpg" alt="Project SpecVault logo" width="350">
</p>

SpecVault is a cross-platform desktop application built with Flutter and Supabase.
It is intended to be a management system for a personal collection, 
covering diverse items and topics such as numismatics, sports memorabilia, and 
scientific memorabilia.

## Database Design

SpecVault uses a normalized relational model centered around a generic `items` table,
with subcollection tables such as:

- `coins`
- `banknotes`
- `trading_cards`

Each subcollection maintains a 1-to-1 relationship with `items`.
Complex many-to-many relationships (e.g. trading cards ↔ players)
are handled via junction tables.

Thus, tables to immediately include:
- `players`
- `player_cards`


[In Progress]
