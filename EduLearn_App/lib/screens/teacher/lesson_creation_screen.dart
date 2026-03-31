// import 'package:flutter/material.dart';

// /// # Lesson Builder Architecture
// /// 
// /// This screen implements a simplified, linear 4-step workflow designed for teachers.
// /// 
// /// ## Components:
// /// 1. **State Management**: Uses a standard `StatefulWidget` to manage local state (metadata, uploaded files, and generated questions) to keep the prototype clean and readable.
// /// 2. **Layout**: A `SingleChildScrollView` ensures the form is accessible on various screen sizes, with content organized into logical `Card` sections.
// /// 3. **Workflow Logic**: 
// ///    - **Metadata**: Standard form fields with a placeholder for AI title suggestions.
// ///    - **Content Upload**: Simulated file picker that adds "chips" to the UI for visual feedback.
// ///    - **AI Question Generation**: Simulates an asynchronous API call with a 2-second delay, returning a pre-defined set of various educational question types.
// ///    - **Publishing**: A sticky bottom bar for easy access to primary actions.
// /// 4. **Modern UI**: Uses a professional Blue/Grey palette with clear visual indicators (badges, icons, and loading states).

// // =============================================================================
// // MODELS
// // =============================================================================

// /// Dummy model representing a Lesson
// class LessonMetadata {
//   String title;
//   String subject;
//   String gradeLevel;

//   LessonMetadata({this.title = '', this.subject = 'Mathematics', this.gradeLevel = 'Grade 10'});
// }

// /// Enum for Question Types
// enum QuestionType { multipleChoice, trueFalse, fillInBlank, matching, flashcard }

// /// Dummy model representing a Generated Question
// class GeneratedQuestion {
//   final String id;
//   QuestionType type;
//   String questionText;
//   List<String>? options;
//   String answer;
//   bool isEditing;

//   GeneratedQuestion({
//     required this.id,
//     required this.type,
//     required this.questionText,
//     this.options,
//     required this.answer,
//     this.isEditing = false,
//   });
// }

// // =============================================================================
// // MAIN SCREEN
// // =============================================================================

// class LessonCreationScreen extends StatefulWidget {
//   const LessonCreationScreen({super.key});

//   @override
//   State<LessonCreationScreen> createState() => _LessonCreationScreenState();
// }

// class _LessonCreationScreenState extends State<LessonCreationScreen> {
//   // State variables
//   final _metadata = LessonMetadata();
//   final List<String> _uploadedFiles = [];
//   List<GeneratedQuestion> _questions = [];
//   bool _isGeneratingQuestions = false;

//   // Controllers
//   final TextEditingController _titleController = TextEditingController();

//   @override
//   void dispose() {
//     _titleController.dispose();
//     super.dispose();
//   }

//   // Helper: Simulate File Picking
//   void _simulateFilePick(String type) {
//     // TODO: Implement real File Picker (e.g., file_picker package)
//     setState(() {
//       _uploadedFiles.add("new_lesson_${type.toLowerCase()}_${_uploadedFiles.length + 1}.ext");
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Simulated $type upload success!')),
//     );
//   }

//   // Helper: Remove File
//   void _removeFile(int index) {
//     setState(() {
//       _uploadedFiles.removeAt(index);
//     });
//   }

//   // Helper: Simulate AI Question Generation
//   Future<void> _generateQuestions() async {
//     if (_uploadedFiles.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please upload some content first!'), backgroundColor: Colors.orange),
//       );
//       return;
//     }

//     setState(() => _isGeneratingQuestions = true);

//     // TODO: Integrate with backend AI API (e.g., Gemini / OpenAI)
//     await Future.delayed(const Duration(seconds: 2));

//     setState(() {
//       _isGeneratingQuestions = false;
//       _questions = [
//         GeneratedQuestion(
//           id: '1',
//           type: QuestionType.multipleChoice,
//           questionText: "What is the primary function of a cell's mitochondria?",
//           options: ["Energy Production", "DNA Storage", "Waste Removal", "Structural Support"],
//           answer: "Energy Production",
//         ),
//         GeneratedQuestion(
//           id: '2',
//           type: QuestionType.trueFalse,
//           questionText: "The Great Wall of China is visible from space with the naked eye.",
//           answer: "False",
//         ),
//         GeneratedQuestion(
//           id: '3',
//           type: QuestionType.fillInBlank,
//           questionText: "The capital city of France is _____.",
//           answer: "Paris",
//         ),
//         GeneratedQuestion(
//           id: '4',
//           type: QuestionType.matching,
//           questionText: "Match the following Countries to their Capitals.",
//           answer: "Japan: Tokyo, UK: London, Egypt: Cairo",
//         ),
//         GeneratedQuestion(
//           id: '5',
//           type: QuestionType.flashcard,
//           questionText: "OOP (Object-Oriented Programming)",
//           answer: "A programming paradigm based on the concept of 'objects'.",
//         ),
//       ];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text('Create New Lesson', style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionHeader("Step 1: Lesson Details"),
//                   _buildMetadataCard(),
                  
//                   const SizedBox(height: 24),
//                   _buildSectionHeader("Step 2: Source Material"),
//                   _buildUploadCard(),

//                   const SizedBox(height: 24),
//                   _buildSectionHeader("Step 3: AI Assessment Review"),
//                   _buildAIQuestionsCard(),
                  
//                   const SizedBox(height: 100), // Space for bottom bar
//                 ],
//               ),
//             ),
//           ),
//           _buildBottomActionBar(),
//         ],
//       ),
//     );
//   }

//   // =================== SECTION WIDGETS ===================

//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0, left: 4),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.blue.shade900,
//         ),
//       ),
//     );
//   }

//   /// STEP 1: METADATA
//   Widget _buildMetadataCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextFormField(
//               controller: _titleController,
//               decoration: const InputDecoration(
//                 labelText: 'Lesson Title',
//                 hintText: 'e.g. Introduction to Photosynthesis',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.title),
//               ),
//               onChanged: (val) => _metadata.title = val,
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _metadata.subject,
//                     decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
//                     items: ['Mathematics', 'Science', 'History', 'Language'].map((s) => 
//                       DropdownMenuItem(value: s, child: Text(s))).toList(),
//                     onChanged: (val) => setState(() => _metadata.subject = val!),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _metadata.gradeLevel,
//                     decoration: const InputDecoration(labelText: 'Grade Level', border: OutlineInputBorder()),
//                     items: ['Grade 10', 'Grade 11', 'Grade 12'].map((g) => 
//                       DropdownMenuItem(value: g, child: Text(g))).toList(),
//                     onChanged: (val) => setState(() => _metadata.gradeLevel = val!),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 icon: const Icon(Icons.auto_awesome),
//                 label: const Text('Generate AI Suggestions'),
//                 style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('AI suggestion feature coming soon.')),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// STEP 2: CONTENT UPLOAD
//   Widget _buildUploadCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Upload Lesson Content",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _uploadIconButton(Icons.mic, "Audio", Colors.orange),
//                 _uploadIconButton(Icons.videocam, "Video", Colors.red),
//                 _uploadIconButton(Icons.description, "Doc", Colors.blue),
//                 _uploadIconButton(Icons.image, "Image", Colors.green),
//                 _uploadIconButton(Icons.text_fields, "Text", Colors.purple),
//               ],
//             ),
//             const SizedBox(height: 20),
//             _uploadedFiles.isEmpty
//                 ? Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20),
//                       child: Column(
//                         children: [
//                           Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
//                           const SizedBox(height: 8),
//                           Text("No content uploaded yet", style: TextStyle(color: Colors.grey.shade600)),
//                         ],
//                       ),
//                     ),
//                   )
//                 : Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: _uploadedFiles.asMap().entries.map((entry) {
//                       return Chip(
//                         label: Text(entry.value, style: const TextStyle(fontSize: 12)),
//                         onDeleted: () => _removeFile(entry.key),
//                         backgroundColor: Colors.blue.shade50,
//                         deleteIconColor: Colors.red,
//                       );
//                     }).toList(),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _uploadIconButton(IconData icon, String label, Color color) {
//     return Column(
//       children: [
//         InkWell(
//           onTap: () => _simulateFilePick(label),
//           borderRadius: BorderRadius.circular(30),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
//             child: Icon(icon, color: color, size: 28),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   /// STEP 3: AI GENERATION
//   Widget _buildAIQuestionsCard() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton.icon(
//             icon: const Icon(Icons.psychology),
//             label: const Text('Generate Exercises & Exam Questions'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue.shade700,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             onPressed: _isGeneratingQuestions ? null : _generateQuestions,
//           ),
//         ),
//         const SizedBox(height: 16),
//         if (_isGeneratingQuestions)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 40),
//               child: Column(
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text("AI is processing your materials..."),
//                 ],
//               ),
//             ),
//           )
//         else if (_questions.isEmpty)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 20),
//               child: Text("Click generate to create AI questions."),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _questions.length,
//             itemBuilder: (context, index) {
//               return _buildQuestionCard(_questions[index], index);
//             },
//           ),
//       ],
//     );
//   }

//   Widget _buildQuestionCard(GeneratedQuestion q, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ExpansionTile(
//         initiallyExpanded: false,
//         leading: _getTypeIcon(q.type),
//         title: Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w500)),
//         subtitle: Text("Type: ${q.type.name.toUpperCase()}", style: const TextStyle(fontSize: 11)),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () {}),
//             IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {
//               setState(() => _questions.removeAt(index));
//             }),
//             const Icon(Icons.expand_more),
//           ],
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (q.options != null) ...[
//                   const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   ...q.options!.map((opt) => Padding(
//                     padding: const EdgeInsets.only(bottom: 4),
//                     child: Text("• $opt"),
//                   )),
//                   const Divider(),
//                 ],
//                 const Text("Answer Review:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   initialValue: q.answer,
//                   decoration: const InputDecoration(
//                     labelText: 'Correct Answer',
//                     filled: true,
//                     fillColor: Colors.grey, // Visually greyed out as per requirement
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Icon _getTypeIcon(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice: return const Icon(Icons.list_alt, color: Colors.blue);
//       case QuestionType.trueFalse: return const Icon(Icons.check_circle_outline, color: Colors.green);
//       case QuestionType.fillInBlank: return const Icon(Icons.edit_note, color: Colors.orange);
//       case QuestionType.matching: return const Icon(Icons.compare_arrows, color: Colors.purple);
//       case QuestionType.flashcard: return const Icon(Icons.style, color: Colors.red);
//     }
//   }

//   /// STICKY BOTTOM BAR
//   Widget _buildBottomActionBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton(
//               onPressed: () => Navigator.pop(context),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 side: const BorderSide(color: Colors.grey),
//               ),
//               child: const Text('Save as Draft', style: TextStyle(color: Colors.grey)),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () {
//                 _showSuccessDialog();
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: const Text('Submit & Publish'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Success!"),
//         content: const Text("Your lesson has been built and published successfully."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Navigator.pop(context);
//             },
//             child: const Text("Awesome"),
//           )
//         ],
//       ),
//     );
//   }
// }
