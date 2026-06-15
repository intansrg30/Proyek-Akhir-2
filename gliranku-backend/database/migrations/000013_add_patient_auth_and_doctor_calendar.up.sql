-- Add auth columns to pasien
ALTER TABLE pasien ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE DEFAULT NULL;
ALTER TABLE pasien ADD COLUMN IF NOT EXISTS password VARCHAR(255) DEFAULT NULL;

-- Create table for specific doctor status overrides
CREATE TABLE IF NOT EXISTS status_dokter (
    id SERIAL PRIMARY KEY,
    dokter_id INTEGER NOT NULL,
    tanggal DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    keterangan TEXT DEFAULT '',
    UNIQUE(dokter_id, tanggal)
);
