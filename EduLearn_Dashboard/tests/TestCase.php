<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Creates the application and overrides database connections dynamically for SQLite testing.
     */
    public function createApplication()
    {
        $app = require __DIR__.'/../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        // Point mysql and app_mysql connections to use sqlite in-memory config during tests
        $sqliteConfig = config('database.connections.sqlite');
        config([
            'database.connections.mysql' => $sqliteConfig,
            'database.connections.app_mysql' => $sqliteConfig,
        ]);

        return $app;
    }
}
