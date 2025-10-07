import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCrudScreen extends StatefulWidget {
  const StudentCrudScreen({super.key});

  @override
  State<StudentCrudScreen> createState() => _StudentCrudScreenState();
}

class _StudentCrudScreenState extends State<StudentCrudScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (_nameController.text.trim().isEmpty || _courseController.text.trim().isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    try {
      await _firestore.collection('students').add({
        'name': _nameController.text.trim(),
        'course': _courseController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _nameController.clear();
      _courseController.clear();
      _showSnackBar('Student added successfully!');
    } catch (e) {
      _showSnackBar('Error adding student: $e', isError: true);
    }
  }

  Future<void> _updateStudent(String docId, String currentName, String currentCourse) async {
    final TextEditingController editNameController = TextEditingController(text: currentName);
    final TextEditingController editCourseController = TextEditingController(text: currentCourse);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editCourseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editNameController.text.trim().isEmpty || editCourseController.text.trim().isEmpty) {
                  _showSnackBar('Please fill in all fields', isError: true);
                  return;
                }

                try {
                  await _firestore.collection('students').doc(docId).update({
                    'name': editNameController.text.trim(),
                    'course': editCourseController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  Navigator.of(context).pop();
                  _showSnackBar('Student updated successfully!');
                } catch (e) {
                  _showSnackBar('Error updating student: $e', isError: true);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent(String docId, String studentName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text('Are you sure you want to delete $studentName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('students').doc(docId).delete();
                  Navigator.of(context).pop();
                  _showSnackBar('Student deleted successfully!');
                } catch (e) {
                  _showSnackBar('Error deleting student: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllStudents() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Students'),
          content: const Text('Are you sure you want to delete all students? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  QuerySnapshot snapshot = await _firestore.collection('students').get();
                  WriteBatch batch = _firestore.batch();
                  
                  for (QueryDocumentSnapshot doc in snapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  
                  await batch.commit();
                  Navigator.of(context).pop();
                  _showSnackBar('All students cleared successfully!');
                } catch (e) {
                  _showSnackBar('Error clearing students: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              print('Logout clicked');
              _showSnackBar('Logout clicked');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Student Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Student',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addStudent,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Student'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Student List Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student List',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // Fixed height for list
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('students').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading students',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students found',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first student using the form above',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown';
                          final course = data['course'] ?? 'Unknown';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                course,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _updateStudent(doc.id, name, course),
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteStudent(doc.id, name),
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearAllStudents,
        tooltip: 'Clear All Students',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
