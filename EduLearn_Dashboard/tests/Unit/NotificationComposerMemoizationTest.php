<?php

namespace Tests\Unit;

use App\Models\School;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\View;
use Tests\TestCase;

class NotificationComposerMemoizationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('dashboard_notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id')->nullable();
            $table->string('type')->default('test');
            $table->string('title')->default('Test');
            $table->text('message')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('dashboard_notifications');
        parent::tearDown();
    }

    public function test_view_composer_memoizes_notifications_across_multiple_view_renders(): void
    {
        $user = new User;
        $user->id = 1;
        $user->school_id = 999;
        $this->actingAs($user);

        $school = new School;
        $school->name = 'Test School';
        $school->admin_name = 'Test Admin';

        DB::enableQueryLog();
        DB::flushQueryLog();

        // Render multiple view instances that each trigger View::composer('*')
        View::make('emails.school_approved', ['school' => $school])->render();
        View::make('emails.school_approved', ['school' => $school])->render();
        View::make('emails.school_approved', ['school' => $school])->render();

        $queries = DB::getQueryLog();
        $notificationQueries = array_filter($queries, function ($q) {
            return str_contains($q['query'], 'dashboard_notifications');
        });

        // Exactly 2 queries expected (1 latest take 5, 1 unread count) regardless of how many views are rendered
        $this->assertCount(2, $notificationQueries, 'Notification queries should be executed exactly twice per request due to once() memoization.');
    }
}
