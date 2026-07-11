import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routing/route_guard.dart';
import '../../../core/state/request_status.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/collector_profile_model.dart';
import '../../../data/models/user_model.dart';

class AuthState extends ChangeNotifier {
  AuthState({
    required ApiClient apiClient,
    required SecureStorageService secureStorageService,
  }) : _apiClient = apiClient,
       _secureStorageService = secureStorageService;

  final ApiClient _apiClient;
  final SecureStorageService _secureStorageService;

  UserModel? _currentUser;
  RequestState<UserModel> _loginState = const RequestState<UserModel>();
  RequestState<void> _registerState = const RequestState<void>();
  RequestState<UserModel> _profileRefreshState =
      const RequestState<UserModel>();
  RequestState<UserModel> _profileUpdateState = const RequestState<UserModel>();

  UserModel? get currentUser => _currentUser;
  RequestState<UserModel> get loginState => _loginState;
  RequestState<void> get registerState => _registerState;
  RequestState<UserModel> get profileRefreshState => _profileRefreshState;
  RequestState<UserModel> get profileUpdateState => _profileUpdateState;

  Future<AppDestination?> login({
    required String email,
    required String password,
  }) async {
    _loginState = const RequestState<UserModel>(status: RequestStatus.loading);
    notifyListeners();

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.authLoginPath,
        data: <String, dynamic>{'email': email, 'password': password},
      );

      final responseData = response.data ?? <String, dynamic>{};
      final data = _normalizedMap(responseData['data']);
      if (data == null) {
        throw ApiException.fromMessage(
          statusCode: response.statusCode,
          message: 'Login response was missing data payload',
        );
      }
      final userJson = _normalizedMap(data['user']);
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      if (userJson == null || accessToken == null || refreshToken == null) {
        throw ApiException.fromMessage(
          statusCode: response.statusCode,
          message: 'Login response was missing required fields',
        );
      }

      final user = UserModel.fromJson(userJson);
      await _secureStorageService.saveTokens(accessToken, refreshToken);
      await _secureStorageService.saveUserRole(user.role);

      _currentUser = user;
      _loginState = RequestState<UserModel>(
        status: RequestStatus.success,
        data: user,
      );
      notifyListeners();
      return _destinationFromRole(user.role);
    } on ApiException catch (error) {
      _loginState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
      );
      notifyListeners();
      return null;
    } catch (error) {
      _loginState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    String? cnicNumber,
    String? vehicleType,
  }) async {
    _registerState = const RequestState<void>(status: RequestStatus.loading);
    notifyListeners();

    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role.apiValue,
    };

    if (role == UserRole.collector) {
      if (cnicNumber != null && cnicNumber.trim().isNotEmpty) {
        payload['cnicNumber'] = cnicNumber.trim();
      }
      if (vehicleType != null && vehicleType.trim().isNotEmpty) {
        payload['vehicleType'] = vehicleType.trim();
      }
    }

    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.authRegisterPath,
        data: payload,
      );

      _registerState = const RequestState<void>(status: RequestStatus.success);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _registerState = RequestState<void>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _registerState = RequestState<void>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    _profileRefreshState = const RequestState<UserModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    try {
      final user = await _apiClient.fetchCurrentUserProfile();
      _currentUser = user;
      await _secureStorageService.saveUserRole(user.role);
      _profileRefreshState = RequestState<UserModel>(
        status: RequestStatus.success,
        data: user,
      );
      notifyListeners();
    } on ApiException catch (error) {
      _profileRefreshState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
      );
      notifyListeners();
    } catch (error) {
      _profileRefreshState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? vehicleType,
    AvailabilityStatus? availabilityStatus,
  }) async {
    _profileUpdateState = const RequestState<UserModel>(
      status: RequestStatus.loading,
    );
    notifyListeners();

    final updates = <String, dynamic>{'name': name, 'phone': phone};

    if (vehicleType != null) {
      updates['vehicleType'] = vehicleType;
    }

    if (availabilityStatus != null) {
      updates['availabilityStatus'] = availabilityStatus.apiValue;
    }

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        ApiConstants.authMePath,
        data: updates,
      );

      final responseData = response.data ?? <String, dynamic>{};
      final data = _normalizedMap(responseData['data']);
      if (data == null) {
        throw ApiException.fromMessage(
          statusCode: response.statusCode,
          message: 'Profile update response was missing data payload',
        );
      }
      final userJson = _normalizedMap(data['user']);
      if (userJson == null) {
        throw ApiException.fromMessage(
          statusCode: response.statusCode,
          message: 'Profile update response was missing user data',
        );
      }

      final user = UserModel.fromJson(userJson);
      _currentUser = user;
      await _secureStorageService.saveUserRole(user.role);

      _profileUpdateState = RequestState<UserModel>(
        status: RequestStatus.success,
        data: user,
      );
      _profileRefreshState = RequestState<UserModel>(
        status: RequestStatus.success,
        data: user,
      );
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _profileUpdateState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.message,
        fieldErrors: error.errors,
      );
      notifyListeners();
      return false;
    } catch (error) {
      _profileUpdateState = RequestState<UserModel>(
        status: RequestStatus.error,
        errorMessage: error.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post<void>(
          ApiConstants.authLogoutPath,
          data: <String, dynamic>{'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore logout API failures and continue local cleanup.
    }

    await _secureStorageService.clearAll();
    _clearInMemoryAuthState();
    notifyListeners();
  }

  Future<void> handleSessionExpired() async {
    await _secureStorageService.clearAll();
    _clearInMemoryAuthState();
    notifyListeners();
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

  AppDestination _destinationFromRole(UserRole role) {
    return switch (role) {
      UserRole.citizen => AppDestination.citizenHome,
      UserRole.collector => AppDestination.collectorHome,
      UserRole.admin || UserRole.vendor => AppDestination.login,
    };
  }

  Map<String, dynamic>? _normalizedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return null;
  }

  void _clearInMemoryAuthState() {
    _currentUser = null;
    _loginState = const RequestState<UserModel>();
    _registerState = const RequestState<void>();
    _profileRefreshState = const RequestState<UserModel>();
    _profileUpdateState = const RequestState<UserModel>();
  }
}
