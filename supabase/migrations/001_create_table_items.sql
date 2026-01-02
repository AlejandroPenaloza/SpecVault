/*
  Project:   SpecVault
  Migration: 001_create_table_items
  Author:    Alejandro Penaloza
  Created:   2026/01/01
  
  Purpose:
  To create base 'items' table for all collection entries.
  This is to be main table. 
*/


create extension if not exists "uuid-ossp";

create table items (
  id uuid primary key default uuid_generate_v4(), -- internal identifier
  name text not null,
  category text not null,
  description text,
  acquired_date date,
  created_at timestamp default now(),
  updated_at timestamp default now()
);
