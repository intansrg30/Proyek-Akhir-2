-- Create the antrian (queue) table for GiliranKu
CREATE TABLE IF NOT EXISTS antrian (
    id              SERIAL PRIMARY KEY,
    no_antrian      VARCHAR(20)  NOT NULL,
    kode_booking    VARCHAR(50)  NOT NULL UNIQUE,
    nik             VARCHAR(16)  NOT NULL,
    nama_pasien     VARCHAR(255) NOT NULL,
    telepon         VARCHAR(20),
    poli_id         INTEGER      NOT NULL,
    dokter_id       INTEGER,
    tanggal         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    waktu_mulai     VARCHAR(10),
    waktu_selesai   VARCHAR(10),
    pembayaran      VARCHAR(20)  NOT NULL DEFAULT 'Umum',
    is_pasien_lama  BOOLEAN      NOT NULL DEFAULT FALSE,
    status          VARCHAR(30)  NOT NULL DEFAULT 'menunggu'
);

CREATE INDEX IF NOT EXISTS idx_antrian_tanggal ON antrian (tanggal);
CREATE INDEX IF NOT EXISTS idx_antrian_poli_tanggal ON antrian (poli_id, tanggal);
