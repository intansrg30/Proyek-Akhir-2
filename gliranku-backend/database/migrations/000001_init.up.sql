-- Giliranku Database Schema (PostgreSQL)

CREATE TABLE Pasien (
    NIK VARCHAR(16) PRIMARY KEY,
    noRM VARCHAR(20),
    patientName VARCHAR(100) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(50)
);

CREATE TABLE Kontrol_Rutin (
    controlID SERIAL PRIMARY KEY,
    controlDate DATE NOT NULL,
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    NIK VARCHAR(16) REFERENCES Pasien(NIK) ON DELETE CASCADE
);

CREATE TABLE Tiket_Apotek (
    queueNumber SERIAL PRIMARY KEY,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Notifikasi (
    notificationID SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    scheduledDate DATE,
    isSent BOOLEAN DEFAULT false,
    sentAt TIMESTAMP,
    NIK VARCHAR(16) REFERENCES Pasien(NIK) ON DELETE CASCADE
);