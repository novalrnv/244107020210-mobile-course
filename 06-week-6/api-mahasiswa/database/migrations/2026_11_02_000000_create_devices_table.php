<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            // Nullable: perangkat mendaftar sebelum pengguna login.
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('fcm_token', 255)->unique();
            $table->string('platform', 10)->default('android');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
