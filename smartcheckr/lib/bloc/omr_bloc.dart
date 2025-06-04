import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/test_model.dart';
import '../services/omr_service.dart';

// Events
abstract class OmrEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTests extends OmrEvent {}

class CreateTest extends OmrEvent {
  final Test test;
  CreateTest(this.test);
  
  @override
  List<Object> get props => [test];
}

class UpdateTest extends OmrEvent {
  final Test test;
  UpdateTest(this.test);
  
  @override
  List<Object> get props => [test];
}

class DeleteTest extends OmrEvent {
  final String testId;
  DeleteTest(this.testId);
  
  @override
  List<Object> get props => [testId];
}

class ProcessAnswerSheet extends OmrEvent {
  final File imageFile;
  final String testId;
  final String studentName;
  final String studentId;
  
  ProcessAnswerSheet({
    required this.imageFile,
    required this.testId,
    required this.studentName,
    required this.studentId,
  });
  
  @override
  List<Object> get props => [imageFile, testId, studentName, studentId];
}

// States
abstract class OmrState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OmrInitial extends OmrState {}

class OmrLoading extends OmrState {}

class TestsLoaded extends OmrState {
  final List<Test> tests;
  TestsLoaded(this.tests);
  
  @override
  List<Object> get props => [tests];
}

class TestCreated extends OmrState {
  final Test test;
  TestCreated(this.test);
  
  @override
  List<Object> get props => [test];
}

class TestUpdated extends OmrState {
  final Test test;
  TestUpdated(this.test);
  
  @override
  List<Object> get props => [test];
}

class TestDeleted extends OmrState {
  final String testId;
  TestDeleted(this.testId);
  
  @override
  List<Object> get props => [testId];
}

class AnswerSheetProcessed extends OmrState {
  final ProcessingResult result;
  AnswerSheetProcessed(this.result);
  
  @override
  List<Object> get props => [result];
}

class OmrError extends OmrState {
  final String message;
  OmrError(this.message);
  
  @override
  List<Object> get props => [message];
}

// BLoC
class OmrBloc extends Bloc<OmrEvent, OmrState> {
  final OmrService omrService;

  OmrBloc(this.omrService) : super(OmrInitial()) {
    on<LoadTests>(_onLoadTests);
    on<CreateTest>(_onCreateTest);
    on<UpdateTest>(_onUpdateTest);
    on<DeleteTest>(_onDeleteTest);
    on<ProcessAnswerSheet>(_onProcessAnswerSheet);
  }

  Future<void> _onLoadTests(LoadTests event, Emitter<OmrState> emit) async {
    emit(OmrLoading());
    try {
      final tests = await omrService.getTests();
      emit(TestsLoaded(tests));
    } catch (e) {
      emit(OmrError(e.toString()));
    }
  }

  Future<void> _onCreateTest(CreateTest event, Emitter<OmrState> emit) async {
    emit(OmrLoading());
    try {
      await omrService.saveTest(event.test);
      emit(TestCreated(event.test));
      // Reload tests to show updated list
      add(LoadTests());
    } catch (e) {
      emit(OmrError(e.toString()));
    }
  }

  Future<void> _onUpdateTest(UpdateTest event, Emitter<OmrState> emit) async {
    emit(OmrLoading());
    try {
      await omrService.updateTest(event.test);
      emit(TestUpdated(event.test));
      // Reload tests to show updated list
      add(LoadTests());
    } catch (e) {
      emit(OmrError(e.toString()));
    }
  }

  Future<void> _onDeleteTest(DeleteTest event, Emitter<OmrState> emit) async {
    emit(OmrLoading());
    try {
      await omrService.deleteTest(event.testId);
      emit(TestDeleted(event.testId));
      // Reload tests to show updated list
      add(LoadTests());
    } catch (e) {
      emit(OmrError(e.toString()));
    }
  }

  Future<void> _onProcessAnswerSheet(ProcessAnswerSheet event, Emitter<OmrState> emit) async {
    emit(OmrLoading());
    try {
      final result = await omrService.processAnswerSheet(
        imageFile: event.imageFile,
        testId: event.testId,
        studentName: event.studentName,
        studentId: event.studentId,
      );
      
      emit(AnswerSheetProcessed(result));
    } catch (e) {
      emit(OmrError(e.toString()));
    }
  }
} 