<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use App\Models\Mahasiswa;
use Illuminate\Database\Seeder;

class MahasiswaSeeder extends Seeder
{
    /**
     * `updateOrCreate` dipakai agar seeder aman dijalankan berulang.
     * Sebelumnya `create` akan gagal di indeks unik `nim` saat seed kedua.
     */
    public function run(): void
    {
        Mahasiswa::updateOrCreate(
            ['nim' => '2341720001'],
            [
                'nama'  => 'Andi Pratama',
                'prodi' => 'D4 Teknik Informatika',
                'email' => 'andi@example.com',
            ],
        );

        Mahasiswa::updateOrCreate(
            ['nim' => '2341720002'],
            [
                'nama'  => 'Bunga Lestari',
                'prodi' => 'D4 Sistem Informasi Bisnis',
                'email' => 'bunga@example.com',
            ],
        );
    }
}
