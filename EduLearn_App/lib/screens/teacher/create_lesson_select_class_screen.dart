
// import 'package:flutter/material.dart';
// import '../../theme.dart';
// import 'lesson_builder_screen.dart';

// class CreateLessonSelectClassScreen extends StatefulWidget {
//   final List<dynamic> assignments;
//   final String fullName;
//   final String teacherCode;
//   final int totalAssignedStudents;

//   const CreateLessonSelectClassScreen({
//     super.key,
//     required this.assignments,
//     required this.fullName,
//     required this.teacherCode,
//     required this.totalAssignedStudents,
//   });

//   @override
//   State<CreateLessonSelectClassScreen> createState() =>
//       _CreateLessonSelectClassScreenState();
// }

// class _CreateLessonSelectClassScreenState
//     extends State<CreateLessonSelectClassScreen> {
//   int? _selectedIndex;

//   String _buildClassKey({
//     required String grade,
//     required String section,
//     required String subjectName,
//   }) {
//     return '${grade.trim()}_${section.trim()}_${subjectName.trim()}';
//   }

//   int _parseInt(dynamic value) {
//     if (value == null) return 0;
//     if (value is int) return value;
//     return int.tryParse(value.toString()) ?? 0;
//   }

//   void _onContinue() async {
//     if (_selectedIndex == null) return;

//     final item = widget.assignments[_selectedIndex!];
//     if (item is! Map<String, dynamic>) return;

//     final String grade = (item['class_grade'] ?? '').toString();
//     final String section = (item['class_section'] ?? '').toString();
//     final String subjectName = (item['subject_name'] ?? '').toString();
//     final int studentsCount = (item['students_count'] as int?) ?? 0;

//     // ✅ IDs من الـ assignment
//     final int assignmentId = _parseInt(item['assignment_id']);
//     final int classSectionId = _parseInt(item['class_section_id']);
//     final int subjectId = _parseInt(item['subject_id']);

//     final String title =
//         grade.isNotEmpty ? '$grade - $subjectName' : subjectName;
//     final classKey =
//         _buildClassKey(grade: grade, section: section, subjectName: subjectName);

//     final saved = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (_) => LessonBuilderScreen(
//           classKey: classKey,
//           classTitle: title,
//           studentsCount: studentsCount,

//           teacherCode: widget.teacherCode,
//           assignmentId: assignmentId,
//           classSectionId: classSectionId,
//           subjectId: subjectId,
//         ),
//       ),
//     );

//     if (saved == true && mounted) {
//       Navigator.of(context).pop(); // نغلق شاشة اختيار الكلاس
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: EduTheme.background,
//       appBar: AppBar(
//         title: const Text('Create New Lesson'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//               color: EduTheme.primaryDark),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Text(
//               'Select a class to assign this lesson to.',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: EduTheme.textMuted,
//                   ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: ListView.builder(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               itemCount: widget.assignments.length,
//               itemBuilder: (context, index) {
//                 final item = widget.assignments[index];
//                 if (item is! Map<String, dynamic>) {
//                   return const SizedBox.shrink();
//                 }

//                 final String grade =
//                     (item['class_grade'] ?? '').toString();
//                 final String subjectName =
//                     (item['subject_name'] ?? '').toString();
//                 final int studentsCount =
//                     (item['students_count'] as int?) ?? 0;

//                 final String title = subjectName;
//                 final String gradeLabel =
//                     grade.isNotEmpty ? '$grade Grade' : '';

//                 final bool selected = _selectedIndex == index;

//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6),
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(20),
//                     onTap: () {
//                       setState(() {
//                         _selectedIndex = index;
//                       });
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: selected
//                             ? const Color(0xFFE8F6FF)
//                             : Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: selected
//                               ? EduTheme.primary
//                               : Colors.transparent,
//                           width: 1.2,
//                         ),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Color(0x11000000),
//                             blurRadius: 10,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 12),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 52,
//                             height: 52,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFE8F3FF),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: const Icon(
//                               Icons.calculate_rounded,
//                               color: EduTheme.primary,
//                               size: 26,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   title,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w800,
//                                     color: EduTheme.primaryDark,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 Text(
//                                   gradeLabel.isNotEmpty
//                                       ? '$gradeLabel • $studentsCount Students'
//                                       : '$studentsCount Students',
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: EduTheme.textMuted,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Radio<int>(
//                             value: index,
//                             groupValue: _selectedIndex,
//                             activeColor: EduTheme.primary,
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedIndex = value;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed:
//                     _selectedIndex == null ? null : _onContinue,
//                 child: const Text('Continue'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
