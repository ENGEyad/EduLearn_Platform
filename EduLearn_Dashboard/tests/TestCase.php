<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

abstract class TestCase extends BaseTestCase
{
    /**
     * Custom refresh database for dual sqlite connections.
     */
    protected function refreshTestDatabase()
    {
        // Purge connections to ensure a fresh state
        DB::purge('mysql');
        DB::purge('app_mysql');

        // Reset Artisan kernel to avoid state leakage
        $this->app->setArtisan(null);

        // Run migrations for both connections
        Artisan::call('migrate:fresh', ['--force' => true]);

        parent::refreshTestDatabase();
    }
}
