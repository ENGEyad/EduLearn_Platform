<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Broadcast;

class BroadcastAuthController extends Controller
{
    public function auth(Request $request)
    {
        return Broadcast::auth($request);
    }
}