<?php

namespace App\Services;

class DashboardInsightPayloadBuilder
{
    /**
     * @param array<string, mixed> $analytics
     * @return array<string, mixed>
     */
    public function build(array $analytics, ?string $schoolName = null): array
    {
        return [
            'school_name' => $schoolName ?: 'EduLearn School',
            'period' => $analytics['period_label'],
            'metrics' => [
                'teachers' => $analytics['stats']['teachers'],
                'students' => $analytics['stats']['students'],
                'classes' => $analytics['stats']['classes'],
                'subjects' => $analytics['stats']['subjects'],
                'attendance_avg' => $analytics['stats']['attendance'],
                'attendance_threshold' => 85,
                'performance_avg' => $analytics['stats']['performance'],
                'performance_threshold' => 70,
            ],
            'trends' => [
                'performance_change_points' => $analytics['performance_change_points'],
                'attendance_change_points' => null,
            ],
            'risks' => $analytics['risks'],
            'anomalies' => $analytics['anomalies'],
            'recommended_focus' => $analytics['recommended_focus'],
            'data_limitations' => $analytics['data_limitations'],
        ];
    }
}
