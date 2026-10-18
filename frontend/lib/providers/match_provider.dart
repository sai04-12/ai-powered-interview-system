import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/match_model.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/services/resume_service.dart';

class MatchState {
  final bool isLoading;
  final MatchModel? matchResult;
  final String? errorMessage;

  const MatchState({
    this.isLoading = false,
    this.matchResult,
    this.errorMessage,
  });

  MatchState copyWith({
    bool? isLoading,
    MatchModel? matchResult,
    String? errorMessage,
  }) {
    return MatchState(
      isLoading: isLoading ?? this.isLoading,
      matchResult: matchResult ?? this.matchResult,
      errorMessage: errorMessage,
    );
  }
}

class MatchNotifier extends Notifier<MatchState> {
  late final ResumeService _resumeService;

  @override
  MatchState build() {
    _resumeService = ref.watch(resumeServiceProvider);
    return const MatchState();
  }

  Future<MatchModel?> evaluateMatch({
    required String resumeId,
    required String jobId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _resumeService.matchResumeToJob(
        resumeId: resumeId,
        jobId: jobId,
      );
      state = state.copyWith(isLoading: false, matchResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  void clearResult() {
    state = const MatchState();
  }
}

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(
  MatchNotifier.new,
);
