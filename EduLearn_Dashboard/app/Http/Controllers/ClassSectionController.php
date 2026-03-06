<?php

namespace App\Http\Controllers;

use App\Models\ClassSection;
use Illuminate\Http\Request;

class ClassSectionController extends Controller
{
    public function index()
    {
        return view('classes', [
            'pageTitle'         => 'Classes',
            'pageSubtitle'      => 'Manage classes data',
            'CLASSES_ROUTES'    => [
                'list'    => route('classes.list'),
                'store'   => route('classes.store'),
                'update'  => route('classes.update', ['class_section' => '__ID__']),
                'destroy' => route('classes.destroy', ['class_section' => '__ID__']),
            ],
        ]);
    }

    public function list()
    {
        return response()->json(
            ClassSection::orderBy('grade')
                ->orderBy('section')
                ->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'grade'      => 'required|string|max:20',
            'section'    => 'required|string|max:20',
            'name'       => 'required|string|max:255',
            'stage'      => 'nullable|string|max:100',
            'is_active'  => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);

        $class = ClassSection::create($data);

        return response()->json([
            'message' => 'Class section created successfully',
            'class'   => $class,
        ]);
    }

    public function update(Request $request, ClassSection $class_section)
    {
        $data = $request->validate([
            'grade'      => 'required|string|max:20',
            'section'    => 'required|string|max:20',
            'name'       => 'required|string|max:255',
            'stage'      => 'nullable|string|max:100',
            'is_active'  => 'nullable|boolean',
        ]);

        $data['is_active'] = $request->boolean('is_active', true);

        $class_section->update($data);

        return response()->json([
            'message' => 'Class section updated successfully',
            'class'   => $class_section,
        ]);
    }

    public function destroy(ClassSection $class_section)
    {
        $class_section->delete();

        return response()->json([
            'message' => 'Class section deleted successfully',
        ]);
    }
}
