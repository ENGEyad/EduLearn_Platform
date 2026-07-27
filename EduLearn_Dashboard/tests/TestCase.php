<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Creates the application and configures dual connections for testing with SQLite.
     *
     * @return \Illuminate\Foundation\Application
     */
    public function createApplication()
    {
        $app = parent::createApplication();

        // Redirect 'app_mysql' and 'mysql' connections to 'sqlite' for seamless testing
        $app['config']->set('database.connections.app_mysql', $app['config']->get('database.connections.sqlite'));
        $app['config']->set('database.connections.mysql', $app['config']->get('database.connections.sqlite'));

        return $app;
    }
}
