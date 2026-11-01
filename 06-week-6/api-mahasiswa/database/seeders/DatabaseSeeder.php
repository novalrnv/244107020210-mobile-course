<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Akun demo untuk presentasi.
     *
     * Memakai updateOrCreate supaya seeder aman dijalankan berulang: password
     * selalu di-reset ke nilai di bawah, tanpa membuat baris duplikat.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'noval@gmail.com'],
            [
                'name' => 'Noval',
                'password' => '231105',
            ],
        );

        $this->call(MahasiswaSeeder::class);
    }
}
