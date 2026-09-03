<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Barang extends Model
{
    protected $table = 'barang';

    protected $fillable = [
        'kategori_id',
        'kode_barang',
        'nama_barang',
        'stok',
        'stok_minimum',
        'satuan',
        'lokasi_penyimpanan',
        'deskripsi',
        'status_barang',
    ];

    public function kategori()
    {
        return $this->belongsTo(KategoriBarang::class, 'kategori_id');
    }

    /**
     * Update status_barang otomatis berdasarkan stok dan stok_minimum.
     * Dipanggil sebelum save.
     */
    public static function hitungStatus(int $stok, int $stokMinimum): string
    {
        if ($stok <= 0) {
            return 'Habis';
        } elseif ($stok <= $stokMinimum) {
            return 'Stok Menipis';
        } else {
            return 'Tersedia';
        }
    }
}