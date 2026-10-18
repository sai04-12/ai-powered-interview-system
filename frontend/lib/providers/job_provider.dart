import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/job_model.dart';
import 'package:frontend/services/job_service.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService();
});

final jobsListProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  final service = ref.watch(jobServiceProvider);
  return service.getJobs();
});

class JobActionState {
  final bool isLoading;
  final String? errorMessage;
  final JobModel? createdJob;

  const JobActionState({
    this.isLoading = false,
    this.errorMessage,
    this.createdJob,
  });

  JobActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    JobModel? createdJob,
  }) {
    return JobActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdJob: createdJob ?? this.createdJob,
    );
  }
}

class JobActionNotifier extends Notifier<JobActionState> {
  late final JobService _service;

  @override
  JobActionState build() {
    _service = ref.watch(jobServiceProvider);
    return const JobActionState();
  }

  Future<JobModel?> createJob({
    required String title,
    String? company,
    required String description,
    required List<String> requiredSkills,
    List<String> preferredSkills = const [],
    int? minExperienceYears,
    String? educationRequirements,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final job = await _service.createJob(
        title: title,
        company: company,
        description: description,
        requiredSkills: requiredSkills,
        preferredSkills: preferredSkills,
        minExperienceYears: minExperienceYears,
        educationRequirements: educationRequirements,
      );
      state = state.copyWith(isLoading: false, createdJob: job);
      ref.invalidate(jobsListProvider);
      return job;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<void> deleteJob(String id) async {
    try {
      await _service.deleteJob(id);
      ref.invalidate(jobsListProvider);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final jobActionProvider = NotifierProvider<JobActionNotifier, JobActionState>(
  JobActionNotifier.new,
);
