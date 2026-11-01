<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\MahasiswaController;
use Illuminate\Support\Facades\Route;

// Autentikasi aplikasi mobile.
Route::post('/login', [AuthController::class, 'login']);

// Wajib membawa Bearer token.
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/refresh', [AuthController::class, 'refresh']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
});

// Tanpa middleware: perangkat mendaftar sebelum pengguna login.
Route::post('/devices', [DeviceController::class, 'store']);

// Satu baris ini membuat 5 route CRUD sekaligus
Route::apiResource('mahasiswa', MahasiswaController::class);
