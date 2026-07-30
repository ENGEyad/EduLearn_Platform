<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = parent::createApplication();

        // Dynamically override DB connections for testing to use sqlite in-memory
        $sqliteConfig = config('database.connections.sqlite');
        config(['database.connections.mysql' => $sqliteConfig]);
        config(['database.connections.app_mysql' => $sqliteConfig]);

        return $app;
    }
}
