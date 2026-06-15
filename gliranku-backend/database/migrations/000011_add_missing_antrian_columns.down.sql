-- Rollback: remove added columns from antrian table
ALTER TABLE antrian
    DROP COLUMN IF EXISTS no_antrian_poli,
    DROP COLUMN IF EXISTS source,
    DROP COLUMN IF EXISTS no_rm;
