<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Mahasiswa extends Model
{
    // Nama tabel ditulis eksplisit agar tidak
    // dijamakkan otomatis menjadi "mahasiswas"
    protected $table = 'mahasiswa';
 
    // Kolom yang boleh diisi lewat create()/update()
    protected $fillable = [
        'nim', 
        'nama', 
        'prodi', 
        'email'];
}
