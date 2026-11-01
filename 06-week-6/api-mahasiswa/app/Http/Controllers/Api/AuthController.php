<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    /**
     * Menukar email + kata sandi dengan token Sanctum.
     *
     * Kegagalan kredensial sengaja dijawab 422, bukan 401. Aplikasi Flutter
     * menerjemahkan 401 menjadi "sesi berakhir", kalimat yang membingungkan
     * saat pengguna baru salah mengetik kata sandi di halaman login.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau kata sandi salah.',
            ], 422);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'token' => $token,
                'user' => $this->profile($user),
            ],
        ]);
    }

    /**
     * Menukar token lama dengan token baru.
     *
     * Token lama dihapus supaya token yang bocor tidak bisa dipakai selamanya.
     * Aplikasi menyimpan token yang sama sebagai access dan refresh karena
     * Sanctum tidak memisahkan keduanya.
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $current = $user->currentAccessToken();

        $token = $user->createToken('mobile')->plainTextToken;

        if ($current instanceof PersonalAccessToken) {
            $current->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Token diperbarui',
            'data' => ['token' => $token],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $current = $request->user()->currentAccessToken();

        if ($current instanceof PersonalAccessToken) {
            $current->delete();
        }

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Profil pengguna',
            'data' => $this->profile($request->user()),
        ]);
    }

    /**
     * Hanya kolom yang aman ditampilkan. Password dan token tidak pernah
     * ikut keluar lewat respons ini.
     *
     * @return array<string, mixed>
     */
    private function profile(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
        ];
    }
}
