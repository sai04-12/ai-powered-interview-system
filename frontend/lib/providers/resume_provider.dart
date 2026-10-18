import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/resume_model.dart';
import 'package:frontend/services/resume_service.dart';

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

final resumesListProvider = FutureProvider.autoDispose<List<ResumeModel>>((ref) async {
  final service = ref.watch(resumeServiceProvider);
  return service.getMyResumes();
});

class ResumeUploadState {
  final bool isUploading;
  final ResumeModel? uploadedResume;
  final String? errorMessage;

  const ResumeUploadState({
    this.isUploading = false,
    this.uploadedResume,
    this.errorMessage,
  });

  ResumeUploadState copyWith({
    bool? isUploading,
    ResumeModel? uploadedResume,
    String? errorMessage,
  }) {
    return ResumeUploadState(
      isUploading: isUploading ?? this.isUploading,
      uploadedResume: uploadedResume ?? this.uploadedResume,
      errorMessage: errorMessage,
    );
  }
}

class ResumeUploadNotifier extends Notifier<ResumeUploadState> {
  late final ResumeService _service;

  @override
  ResumeUploadState build() {
    _service = ref.watch(resumeServiceProvider);
    return const ResumeUploadState();
  }

  Future<ResumeModel?> upload({
    required List<int> bytes,
    required String filename,
  }) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final resume = await _service.uploadResume(bytes: bytes, filename: filename);
      state = state.copyWith(isUploading: false, uploadedResume: resume);
      ref.invalidate(resumesListProvider);
      return resume;
    } catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  Future<void> deleteResume(String id) async {
    try {
      await _service.deleteResume(id);
      ref.invalidate(resumesListProvider);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearState() {
    state = const ResumeUploadState();
  }
}

final resumeUploadProvider = NotifierProvider<ResumeUploadNotifier, ResumeUploadState>(
  ResumeUploadNotifier.new,
);
