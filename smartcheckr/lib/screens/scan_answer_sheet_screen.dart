import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../bloc/omr_bloc.dart';
import '../models/test_model.dart';
import 'processing_result_screen.dart';

class ScanAnswerSheetScreen extends StatefulWidget {
  final Test? selectedTest;
  
  const ScanAnswerSheetScreen({super.key, this.selectedTest});

  @override
  State<ScanAnswerSheetScreen> createState() => _ScanAnswerSheetScreenState();
}

class _ScanAnswerSheetScreenState extends State<ScanAnswerSheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  Test? _selectedTest;
  List<Test> _availableTests = [];
  bool _isLoadingTests = false;

  @override
  void initState() {
    super.initState();
    // If a test was passed, use it as the selected test
    if (widget.selectedTest != null) {
      _selectedTest = widget.selectedTest;
      _availableTests = [widget.selectedTest!];
    }
    _loadTests();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _loadTests() {
    setState(() {
      _isLoadingTests = true;
    });
    context.read<OmrBloc>().add(LoadTests());
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null; // Clear file reference for web
          });
        } else {
          // For mobile, use file
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null; // Clear bytes for mobile
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _processAnswerSheet() {
    if (_formKey.currentState!.validate() && 
        (_selectedImage != null || _selectedImageBytes != null) && 
        _selectedTest != null) {
      
      File? imageFile;
      if (kIsWeb && _selectedImageBytes != null) {
        // For web, create a temporary file from bytes
        // Note: This might need adjustment based on your OMR processing requirements
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web image processing not fully supported yet. Please use mobile device.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      } else if (_selectedImage != null) {
        imageFile = _selectedImage!;
      }
      
      if (imageFile != null) {
        context.read<OmrBloc>().add(
          ProcessAnswerSheet(
            imageFile: imageFile,
            testId: _selectedTest!.id,
            studentName: _studentNameController.text.trim(),
            studentId: _studentIdController.text.trim(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Answer Sheet'),
      ),
      body: BlocListener<OmrBloc, OmrState>(
        listener: (context, state) {
          if (state is TestsLoaded) {
            setState(() {
              // If no test was pre-selected, use all available tests
              if (widget.selectedTest == null) {
                _availableTests = state.tests;
                if (_availableTests.isNotEmpty && _selectedTest == null) {
                  _selectedTest = _availableTests.first;
                }
              }
              _isLoadingTests = false;
            });
          } else if (state is AnswerSheetProcessed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProcessingResultScreen(
                  result: state.result,
                  test: _selectedTest!,
                ),
              ),
            );
          } else if (state is OmrError) {
            setState(() {
              _isLoadingTests = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<OmrBloc, OmrState>(
          builder: (context, state) {
            if (state is OmrLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitChasingDots(
                      color: Colors.blue,
                      size: 50.0,
                    ),
                    SizedBox(height: 16),
                    Text('Processing answer sheet...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test Selection
                    Text(
                      'Select Test',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingTests)
                      const Center(child: CircularProgressIndicator())
                    else if (_availableTests.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.quiz, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('No tests available'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadTests,
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: DropdownButtonFormField<Test>(
                          value: _selectedTest,
                          decoration: const InputDecoration(
                            labelText: 'Choose Test',
                            prefixIcon: Icon(Icons.quiz),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          items: _availableTests.map((test) {
                            return DropdownMenuItem<Test>(
                              value: test,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      test.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${test.totalItems}Q',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (Test? newValue) {
                            setState(() {
                              _selectedTest = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a test';
                            }
                            return null;
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Student Information
                    Text(
                      'Student Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        hintText: 'Enter student name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter student name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentIdController,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: 'Enter student ID',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter student ID';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Image Selection
                    Text(
                      'Answer Sheet Image',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Image preview or placeholder
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: (_selectedImage != null || _selectedImageBytes != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb && _selectedImageBytes != null
                                    ? Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(), // Fallback
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select answer sheet image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Camera or Gallery',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    if (_selectedImage != null || _selectedImageBytes != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _showImageSourceActionSheet,
                            icon: const Icon(Icons.edit),
                            label: const Text('Change Image'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Process Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ((_selectedImage != null || _selectedImageBytes != null) && 
                                   _selectedTest != null && 
                                   !_isLoadingTests) 
                            ? _processAnswerSheet 
                            : null,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Process Answer Sheet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    
                    if ((_selectedImage == null && _selectedImageBytes == null) || _selectedTest == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Please select a test and capture/select an answer sheet image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 