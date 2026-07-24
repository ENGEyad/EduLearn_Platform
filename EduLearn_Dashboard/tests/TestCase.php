<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Creates the application.
     */
    public function createApplication()
    {
        $app = parent::createApplication();

        // Dynamically override 'app_mysql' and 'mysql' database connections to use sqlite in-memory for testing,
        // so that migrations running on specific connections succeed under SQLite tests.
        config([
            'database.connections.app_mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'foreign_key_constraints' => false,
            ],
            'database.connections.mysql' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'foreign_key_constraints' => false,
            ],
        ]);

        return $app;
    }
}
