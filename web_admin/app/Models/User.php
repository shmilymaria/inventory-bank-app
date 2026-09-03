<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $table = 'users';

    protected $fillable = [
        'role_id',
        'nama_lengkap',
        'username',
        'password',
        'email',
        'nomor_hp',
        'bagian',
        'jabatan',
        'status_aktif',
    ];

    protected $hidden = [
        'password',
    ];

    public function role()
    {
        return $this->belongsTo(Role::class, 'role_id');
    }
}