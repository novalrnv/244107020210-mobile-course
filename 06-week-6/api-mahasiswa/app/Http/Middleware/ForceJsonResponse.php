<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Memaksa seluruh permintaan rute API dianggap mengharapkan JSON.
 *
 * Tanpa ini, middleware `Authenticate` mencoba mengalihkan tamu ke route
 * bernama `login`. Aplikasi ini tidak punya halaman login web, sehingga yang
 * terjadi bukan 401 melainkan error 500 "Route [login] not defined".
 */
class ForceJsonResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');

        return $next($request);
    }
}
