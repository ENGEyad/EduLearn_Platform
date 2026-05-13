<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index()
    {
        $settingsRaw = SystemSetting::all();
        $settings = [];
        
        foreach ($settingsRaw as $setting) {
            $value = $setting->value;
            // Map logo path to a full URL
            if ($setting->key === 'site_logo' && $value) {
                $value = asset('storage/' . $value);
            }
            $settings[$setting->key] = $value;
        }

        return response()->json([
            'success' => true,
            'data' => $settings
        ]);
    }
}
