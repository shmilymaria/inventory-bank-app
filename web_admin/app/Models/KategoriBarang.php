<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KategoriBarang extends Model
{
    protected $table = 'kategori_barang';

    public $timestamps = false;

    protected $fillable = [
        'nama_kategori',
    ];

    public function barang()
    {
        return $this->hasMany(Barang::class, 'kategori_id');
    }
}