-- Migration: 0003_powersync_setup.sql
-- Purpose: Configure Postgres logical replication publication for PowerSync (offline-first)
-- Idempotent: drops existing publication before recreating

-- Drop existing publication if it exists (idempotency)
DROP PUBLICATION IF EXISTS powersync;

-- Create publication including only the tables the mobile app needs offline.
-- These tables are replicated to the client via PowerSync's logical replication stream.
CREATE PUBLICATION powersync FOR TABLE
    diseases,
    drugs,
    protocols,
    pocus_items,
    favorites,
    recent_items;
