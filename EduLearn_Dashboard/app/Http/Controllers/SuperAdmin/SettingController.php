<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index()
    {
        $rawSettings = SystemSetting::all();
        $settings = [];
        foreach ($rawSettings as $s) {
            $settings[$s->group][$s->key] = $s->value;
        }
        return view('super_admin.settings.index', compact('settings'));
    }

    public function update(Request $request)
    {
        \Log::info('Settings Update Attempted', ['data' => $request->all()]);
        // Debugging: Ensure we are getting data
        // if(empty($request->all())) return redirect()->back()->with('error', 'No data received');

        // 1. Process Logo
        if ($request->hasFile('site_logo')) {
            $path = $request->file('site_logo')->store('settings', 'public');
            SystemSetting::updateOrCreate(
                ['key' => 'site_logo'],
                ['value' => $path, 'group' => 'branding']
            );
        }

        // 2. Process Branding & Social
        $inputData = $request->all();
        $mapping = [
            'site_name_ar' => 'branding',
            'site_name_en' => 'branding',
            'site_description' => 'branding',
            'facebook_url' => 'social',
            'twitter_url' => 'social'
        ];

        foreach ($mapping as $key => $group) {
            if (isset($inputData[$key])) {
                SystemSetting::updateOrCreate(
                    ['key' => $key],
                    ['value' => $inputData[$key], 'group' => $group, 'type' => 'text']
                );
            }
        }

        // 3. Process Dynamic Contact Channels
        if ($request->has('contact_channels')) {
            $channels = array_values($request->contact_channels);
            $jsonValue = json_encode($channels);
            
            SystemSetting::updateOrCreate(
                ['key' => 'contact_channels'],
                ['value' => $jsonValue, 'group' => 'contact', 'type' => 'text']
            );

            // Backward Compatibility
            foreach ($channels as $channel) {
                if ($channel['type'] === 'email') {
                    SystemSetting::updateOrCreate(['key' => 'official_email'], ['value' => $channel['value'], 'group' => 'contact']);
                }
                if ($channel['type'] === 'phone') {
                    SystemSetting::updateOrCreate(['key' => 'support_phone'], ['value' => $channel['value'], 'group' => 'contact']);
                }
            }
        }

        return redirect()->back()->with('success', 'تم تحديث الإعدادات بنجاح');
    }
}
