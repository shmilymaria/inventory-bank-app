-- =====================================================
-- DATABASE INVENTORI BANK
-- =====================================================

CREATE DATABASE IF NOT EXISTS inventori_bank
CHARACTER SET utf8mb4
COLLATE utf8mb4_general_ci;

USE inventori_bank;

-- =====================================================
-- ROLES
-- =====================================================

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO roles (role_name)
VALUES
('Admin'),
('Staff'),
('Pimpinan');

-- =====================================================
-- USERS
-- =====================================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,

    nama_lengkap VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,

    email VARCHAR(100),
    nomor_hp VARCHAR(20),

    bagian VARCHAR(100),
    jabatan VARCHAR(100),

    status_aktif ENUM('Aktif','Nonaktif')
    DEFAULT 'Aktif',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_users_role
    FOREIGN KEY (role_id)
    REFERENCES roles(id)
);

-- =====================================================
-- KATEGORI BARANG
-- =====================================================

CREATE TABLE kategori_barang (
    id INT AUTO_INCREMENT PRIMARY KEY,

    nama_kategori VARCHAR(100) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- BARANG
-- =====================================================

CREATE TABLE barang (
    id INT AUTO_INCREMENT PRIMARY KEY,

    kategori_id INT NOT NULL,

    kode_barang VARCHAR(50) UNIQUE NOT NULL,
    nama_barang VARCHAR(150) NOT NULL,

    stok INT DEFAULT 0,

    stok_minimum INT DEFAULT 5,

    satuan VARCHAR(20),

    lokasi_penyimpanan VARCHAR(100),

    deskripsi TEXT,

    status_barang ENUM(
        'Tersedia',
        'Stok Menipis',
        'Habis'
    ) DEFAULT 'Tersedia',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_barang_kategori
    FOREIGN KEY (kategori_id)
    REFERENCES kategori_barang(id)
);

-- =====================================================
-- PERMINTAAN BARANG
-- =====================================================

CREATE TABLE permintaan (
    id INT AUTO_INCREMENT PRIMARY KEY,

    nomor_permintaan VARCHAR(50) UNIQUE,

    user_id INT NOT NULL,

    tanggal_permintaan DATETIME
    DEFAULT CURRENT_TIMESTAMP,

    prioritas ENUM(
        'Normal',
        'Penting',
        'Mendesak'
    ) DEFAULT 'Normal',

    catatan TEXT,

    status_permintaan ENUM(
        'Pending',
        'Approved',
        'Rejected',
        'Revision',
        'Distributed'
    ) DEFAULT 'Pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_permintaan_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
);

-- =====================================================
-- DETAIL PERMINTAAN
-- =====================================================

CREATE TABLE detail_permintaan (
    id INT AUTO_INCREMENT PRIMARY KEY,

    permintaan_id INT NOT NULL,

    barang_id INT NOT NULL,

    jumlah INT NOT NULL,

    keterangan TEXT,

    CONSTRAINT fk_detail_permintaan
    FOREIGN KEY (permintaan_id)
    REFERENCES permintaan(id)
    ON DELETE CASCADE,

    CONSTRAINT fk_detail_barang
    FOREIGN KEY (barang_id)
    REFERENCES barang(id)
);

-- =====================================================
-- APPROVAL PIMPINAN
-- =====================================================

CREATE TABLE approval (
    id INT AUTO_INCREMENT PRIMARY KEY,

    permintaan_id INT NOT NULL,

    pimpinan_id INT NOT NULL,

    keputusan ENUM(
        'Approved',
        'Rejected',
        'Revision'
    ) NOT NULL,

    catatan_approval TEXT,

    tanggal_approval DATETIME
    DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_approval_permintaan
    FOREIGN KEY (permintaan_id)
    REFERENCES permintaan(id),

    CONSTRAINT fk_approval_pimpinan
    FOREIGN KEY (pimpinan_id)
    REFERENCES users(id)
);

-- =====================================================
-- DISTRIBUSI BARANG
-- =====================================================

CREATE TABLE distribusi (
    id INT AUTO_INCREMENT PRIMARY KEY,

    permintaan_id INT NOT NULL,

    admin_id INT NOT NULL,

    tanggal_distribusi DATETIME
    DEFAULT CURRENT_TIMESTAMP,

    status_distribusi ENUM(
        'Diproses',
        'Selesai'
    ) DEFAULT 'Diproses',

    catatan_distribusi TEXT,

    CONSTRAINT fk_distribusi_permintaan
    FOREIGN KEY (permintaan_id)
    REFERENCES permintaan(id),

    CONSTRAINT fk_distribusi_admin
    FOREIGN KEY (admin_id)
    REFERENCES users(id)
);

-- =====================================================
-- RIWAYAT STOK
-- =====================================================

CREATE TABLE riwayat_stok (
    id INT AUTO_INCREMENT PRIMARY KEY,

    barang_id INT NOT NULL,

    jenis_transaksi ENUM(
        'Masuk',
        'Keluar'
    ) NOT NULL,

    jumlah INT NOT NULL,

    stok_sebelum INT NOT NULL,
    stok_sesudah INT NOT NULL,

    keterangan TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_riwayat_barang
    FOREIGN KEY (barang_id)
    REFERENCES barang(id)
);

-- =====================================================
-- NOTIFIKASI
-- =====================================================

CREATE TABLE notifikasi (
    id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    judul VARCHAR(150),
    pesan TEXT,

    status_baca ENUM(
        'Belum Dibaca',
        'Sudah Dibaca'
    ) DEFAULT 'Belum Dibaca',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notifikasi_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
);

-- =====================================================
-- DATA AWAL ADMIN
-- =====================================================

INSERT INTO users (
    role_id,
    nama_lengkap,
    username,
    password,
    email,
    bagian,
    jabatan
)
VALUES
(
    1,
    'Administrator',
    'admin',
    '$2y$10$examplehash',
    'admin@bankxyz.com',
    'Bagian Umum',
    'Administrator'
);