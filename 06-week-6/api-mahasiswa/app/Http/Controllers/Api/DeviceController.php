<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    /**
     * Menyimpan Firebase Installation ID perangkat.
     *
     * Endpoint ini sengaja tidak memakai middleware `auth:sanctum`. Registrasi
     * FCM berjalan saat aplikasi dibuka, yaitu sebelum pengguna login, sehingga
     * permintaan pertama datang tanpa token. Kalau diwajibkan login, ID tidak
     * pernah sampai ke server dan pengguna tidak akan menerima push.
     *
     * `updateOrCreate` mencegah baris ganda setiap aplikasi dibuka ulang.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string|max:255',
            'platform' => 'nullable|string|in:android,ios',
        ]);

        // Guard dipanggil manual: null bila permintaan belum membawa token.
        $user = $request->user('sanctum');

        $device = Device::updateOrCreate(
            ['fcm_token' => $validated['fcm_token']],
            [
                'user_id' => $user?->id,
                'platform' => $validated['platform'] ?? 'android',
            ],
        );

        return response()->json([
            'success' => true,
            'message' => $user
                ? 'Perangkat terhubung ke akun'
                : 'Perangkat terdaftar tanpa akun',
            'data' => [
                'id' => $device->id,
                'user_id' => $device->user_id,
                'platform' => $device->platform,
            ],
        ], 201);
    }
}
