import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/request_status.dart';
import '../../../data/models/paginated_response_model.dart';
import '../../../data/models/pickup_request_model.dart';

class JobsState extends ChangeNotifier {
  JobsState({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // State objects
  RequestState<PaginatedResponseModel<PickupRequestModel>> _feedState =
      const RequestState<PaginatedResponseModel<PickupRequestModel>>();
  RequestState<PaginatedResponseModel<PickupRequestModel>> _myJobsState =
      const RequestState<PaginatedResponseModel<PickupRequestModel>>();
  RequestState<PickupRequestModel> _jobDetailState =
      const RequestState<PickupRequestModel>();
  RequestState<PickupRequestModel> _acceptState =
      const RequestState<PickupRequestModel>();
  RequestState<PickupRequestModel> _statusUpdateState =
      const RequestState<PickupRequestModel>();

  // Data lists & pagination variables
  List<PickupRequestModel> _feedJobs = [];
  int _feedCurrentPage = 1;
  bool _feedHasMorePages = true;

  List<PickupRequestModel> _myJobs = [];
  String? _activeJobStatusFilter; // null | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED'
  int _myJobsCurrentPage = 1;
  bool _myJobsHasMorePages = true;

  // Getters
  RequestState<PaginatedResponseModel<PickupRequestModel>> get feedState =>
      _feedState;
  RequestState<PaginatedResponseModel<PickupRequestModel>> get myJobsState =>
      _myJobsState;
  RequestState<PickupRequestModel> get jobDetailState => _jobDetailState;
  RequestState<PickupRequestModel> get acceptState => _acceptState;
  RequestState<PickupRequestModel> get statusUpdateState => _statusUpdateState;

  List<PickupRequestModel> get feedJobs => _feedJobs;
  int get feedCurrentPage => _feedCurrentPage;
  bool get feedHasMorePages => _feedHasMorePages;

  List<PickupRequestModel> get myJobs => _myJobs;
  String? get activeJobStatusFilter => _activeJobStatusFilter;
  int get myJobsCurrentPage => _myJobsCurrentPage;
  bool get myJobsHasMorePages => _myJobsHasMorePages;

  // Feed Jobs Loader
  Future<void> loadFeed({bool reset = true}) async {
    if (reset) {
      _feedCurrentPage = 1;
      _feedJobs = [];
      _feedHasMorePages = true;
    }

    _feedState = const RequestState<PaginatedResponseModel<PickupRequestModel>>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final paginatedResponse = await _apiClient.getJobFeed(
        page: _feedCurrentPage,
      );

      if (reset) {
        _feedJobs = paginatedResponse.data;
      } else {
        _feedJobs = [..._feedJobs, ...paginatedResponse.data];
      }
      _feedHasMorePages = _feedCurrentPage < paginatedResponse.pagination.totalPages;
      _feedState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.success,
        data: paginatedResponse,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _feedState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
    } catch (error) {
      _feedState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> loadMoreFeed() async {
    if (!_feedHasMorePages || _feedState.status == RequestStatus.loading) {
      return;
    }

    _feedCurrentPage += 1;
    await loadFeed(reset: false);
  }

  // My Jobs Loader - mirrors loadPickups exactly
  Future<void> loadMyJobs({
    bool reset = true,
    String? statusFilter,
  }) async {
    if (reset) {
      _myJobsCurrentPage = 1;
      _myJobs = [];
      _myJobsHasMorePages = true;
      _activeJobStatusFilter = statusFilter;
    }

    _myJobsState = const RequestState<PaginatedResponseModel<PickupRequestModel>>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final paginatedResponse = await _apiClient.getMyJobs(
        status: statusFilter ?? _activeJobStatusFilter,
        page: _myJobsCurrentPage,
      );

      if (reset) {
        _myJobs = paginatedResponse.data;
      } else {
        _myJobs = [..._myJobs, ...paginatedResponse.data];
      }
      _myJobsHasMorePages = _myJobsCurrentPage < paginatedResponse.pagination.totalPages;
      _myJobsState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.success,
        data: paginatedResponse,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _myJobsState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
    } catch (error) {
      _myJobsState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> loadMoreMyJobs() async {
    if (!_myJobsHasMorePages || _myJobsState.status == RequestStatus.loading) {
      return;
    }

    _myJobsCurrentPage += 1;
    await loadMyJobs(reset: false);
  }

  // Load Job Detail
  Future<void> loadJobDetail(String id) async {
    _jobDetailState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final job = await _apiClient.getJobById(id);
      _jobDetailState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: job,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _jobDetailState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
    } catch (error) {
      _jobDetailState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  // Accept Job
  Future<bool> acceptJob(String id) async {
    _acceptState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final acceptedJob = await _apiClient.acceptJob(id);

      // On success, remove the job from feedJobs
      _feedJobs = _feedJobs.where((job) => job.id != id).toList();

      _acceptState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: acceptedJob,
      );
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _acceptState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _acceptState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  // Update Job Status
  Future<bool> updateJobStatus(
    String id,
    String status, {
    double? actualWeight,
  }) async {
    _statusUpdateState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final updatedJob = await _apiClient.updateJobStatus(
        id,
        status: status,
        actualWeight: actualWeight,
      );

      // update jobDetailState
      _jobDetailState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: updatedJob,
      );

      // patch the matching entry in myJobs list
      _myJobs = _myJobs.map((job) => job.id == id ? updatedJob : job).toList();

      _statusUpdateState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: updatedJob,
      );
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _statusUpdateState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _statusUpdateState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  String? fieldErrorFor(List<ApiFieldError>? errors, String field) {
    if (errors == null || errors.isEmpty) {
      return null;
    }

    for (final error in errors) {
      if (error.field == field) {
        return error.message;
      }
    }
    return null;
  }
}
