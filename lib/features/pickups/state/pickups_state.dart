import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/state/request_status.dart';
import '../../../data/models/paginated_response_model.dart';
import '../../../data/models/pickup_request_model.dart';

class PickupsState extends ChangeNotifier {
  PickupsState({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  RequestState<PaginatedResponseModel<PickupRequestModel>> _listState =
      const RequestState<PaginatedResponseModel<PickupRequestModel>>();
  RequestState<PickupRequestModel> _createState =
      const RequestState<PickupRequestModel>();
  RequestState<PickupRequestModel> _detailState =
      const RequestState<PickupRequestModel>();
  RequestState<PickupRequestModel> _updateState =
      const RequestState<PickupRequestModel>();
  RequestState<void> _cancelState = const RequestState<void>();

  List<PickupRequestModel> _pickups = [];
  PickupStatus? _activeStatusFilter;
  int _currentPage = 1;
  bool _hasMorePages = true;

  RequestState<PaginatedResponseModel<PickupRequestModel>> get listState =>
      _listState;
  RequestState<PickupRequestModel> get createState => _createState;
  RequestState<PickupRequestModel> get detailState => _detailState;
  RequestState<PickupRequestModel> get updateState => _updateState;
  RequestState<void> get cancelState => _cancelState;
  List<PickupRequestModel> get pickups => _pickups;
  PickupStatus? get activeStatusFilter => _activeStatusFilter;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;

  Future<void> loadPickups({
    bool reset = true,
    PickupStatus? statusFilter,
  }) async {
    if (reset) {
      _currentPage = 1;
      _pickups = [];
      _hasMorePages = true;
      _activeStatusFilter = statusFilter;
    }

    _listState = const RequestState<PaginatedResponseModel<PickupRequestModel>>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final paginatedResponse = await _apiClient.getMyPickups(
        status: (statusFilter ?? _activeStatusFilter)?.apiValue,
        page: _currentPage,
      );

      if (reset) {
        _pickups = paginatedResponse.data;
      } else {
        _pickups = [..._pickups, ...paginatedResponse.data];
      }
      _hasMorePages = _currentPage < paginatedResponse.pagination.totalPages;
      _listState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.success,
        data: paginatedResponse,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _listState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
    } catch (error) {
      _listState = RequestState<PaginatedResponseModel<PickupRequestModel>>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMorePages || _listState.status == RequestStatus.loading) {
      return;
    }

    _currentPage += 1;
    await loadPickups(reset: false);
  }

  Future<bool> createPickup({
    required File imageFile,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? scheduledTimeIso,
    String? materialType,
    double? estimatedWeight,
  }) async {
    _createState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final pickup = await _apiClient.createPickup(
        imageFile: imageFile,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        scheduledTimeIso: scheduledTimeIso,
        materialType: materialType,
        estimatedWeight: estimatedWeight,
      );

      _pickups = [pickup, ..._pickups];
      _createState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: pickup,
      );
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _createState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _createState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPickupDetail(String id) async {
    _detailState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final pickup = await _apiClient.getPickupById(id);
      _detailState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: pickup,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _detailState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
    } catch (error) {
      _detailState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<bool> updatePickup(String id, Map<String, dynamic> changes) async {
    _updateState = const RequestState<PickupRequestModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final updatedPickup = await _apiClient.updatePickup(id, changes);
      _pickups = _pickups.map((p) => p.id == id ? updatedPickup : p).toList();
      _updateState = RequestState<PickupRequestModel>(
        status: RequestStatus.success,
        data: updatedPickup,
      );
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _updateState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _updateState = RequestState<PickupRequestModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelPickup(String id) async {
    _cancelState = const RequestState<void>(status: RequestStatus.loading);
    notifyListeners();

    try {
      await _apiClient.cancelPickup(id);
      _pickups = _pickups.where((p) => p.id != id).toList();
      _cancelState = const RequestState<void>(status: RequestStatus.success);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _cancelState = RequestState<void>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
        statusCode: error.statusCode,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _cancelState = RequestState<void>(
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
