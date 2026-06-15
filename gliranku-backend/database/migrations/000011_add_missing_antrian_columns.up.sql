-- Add missing columns to antrian table
ALTER TABLE antrian
    ADD COLUMN IF NOT EXISTS no_antrian_poli VARCHAR(20),
    ADD COLUMN IF NOT EXISTS source          VARCHAR(50) NOT NULL DEFAULT 'smartphone',
    ADD COLUMN IF NOT EXISTS no_rm           VARCHAR(50);
