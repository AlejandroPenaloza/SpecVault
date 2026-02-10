# SpecVault

<p align="center">
<img
src="https://raw.githubusercontent.com/AlejandroPenaloza/SpecVault/main/docs/SpecVault_logo_1.jpg" alt="Project SpecVault logo" width="350">
</p>

SpecVault is a cross-platform desktop application built with Flutter and Supabase.
It is a data-driven collection management system designed to catalogue, organize, and 
explore diverse physical items and subcollections such as numismatics, sports memorabilia, and scientific specimen.
It is intended to be a management system for a personal collection, 
covering diverse items and topics such as numismatics, sports memorabilia, and 
scientific memorabilia.

---

## Tech Stack

- **Frontend:** Flutter (desktop)
- **Backend:** Supabase (PostgreSQL)
- **Database:** PostgreSQL (SQL, migrations, constraints)
- **Other:** Python (data seeding utilities, planned)

---

## Database Design

SpecVault uses a normalized relational model centered around a generic `items` table.
Each subcollection maintains a 1-to-1 relationship with `items`.
Complex many-to-many relationships (e.g. trading cards ↔ players)
are handled via junction tables.

The current schema includes the following tables:

- `coins`
- `banknotes`
- `trading_cards`
- `players`
- `trading_card_players`


### Database Migrations and Schema

This project uses a migration-based approach to manage the database schema.
- The `supabase/migrations/` directory contains sequential, replayable migrations that 
represent the authoritative history of schema changes.
- The `supabase/schema.sql` file is a canonical snapshot of the current database structure, 
derived from the applied migrations. 
Intended for documentation and reference, not deployment.
- The `supabase/dev_log.sql` file is a development log / scratchpad that records 
exploratory SQL, data moves, and intermediate steps taken during development. 
It is not idempotent and not meant to be executed end-to-end.

Migrations are designed to be applied in order to reproduce the schema from an empty database. 
During early development, migrations may be amended to fix mistakes and keep the migration chain consistent and replayable. 
As the project stabilizes, schema changes are expected to be introduced via new 
migrations rather than rewrites, keeping the evolution explicit and auditable.

*(A visual schema diagram will be added once the core tables are finalized.)*

---

## Project Structure (so far)

```text
SpecVault/
├── supabase/
│   ├── migrations/      # Incremental schema changes
│   ├── schema.sql       # Canonical schema snapshot
│   ├── seed/            # Seed data (minimal, illustrative)
│   └── dev_log.sql      # SQL scratchpad / development notes
├── app/                 # Flutter application (in progress)
├── docs
    └── SpecVault_logo_1
├── README.md
└── LICENSE
```

[In Progress]
