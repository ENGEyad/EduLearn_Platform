<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Creates the application and overrides database connections for dual-db testing in SQLite memory.
     */
    public function createApplication()
    {
        $app = require __DIR__ . '/../bootstrap/app.php';

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        $sqliteConfig = [
            'driver' => 'sqlite',
            'url' => env('DATABASE_URL'),
            'database' => ':memory:',
            'prefix' => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ];

        config()->set('database.default', 'sqlite');
        config()->set('database.connections.sqlite', $sqliteConfig);
        config()->set('database.connections.mysql', $sqliteConfig);
        config()->set('database.connections.app_mysql', $sqliteConfig);

        return $app;
    }
}
