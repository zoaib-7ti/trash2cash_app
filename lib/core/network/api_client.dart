import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';

import '../../data/models/user_model.dart';
import '../../data/models/pickup_request_model.dart';
import '../../data/models/paginated_response_model.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required SecureStorageService secureStorageService,
    required String apiBaseUrl,
  }) : _secureStorageService = secureStorageService,
       _dio = Dio(
         BaseOptions(
           baseUrl: apiBaseUrl,
           headers: const <String, dynamic>{'Content-Type': 'application/json'},
         ),
       ),
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: apiBaseUrl,
           headers: const <String, dynamic>{'Content-Type': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  static const String _retryMarker = 'api_client_auth_retry';

  final SecureStorageService _secureStorageService;
  final Dio _dio;
  final Dio _refreshDio;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  Completer<void>? _refreshCompleter;

  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(method: method) ?? Options(method: method),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException.fromResponse(
        statusCode: error.response?.statusCode,
        responseData: error.response?.data,
        fallbackMessage: error.message,
      );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return request<T>(
      path,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return request<T>(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Map<String, dynamic>> getHealth() async {
    final response = await get<Map<String, dynamic>>(
      ApiConstants.healthPath,
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<UserModel> fetchCurrentUserProfile() async {
    final response = await get<Map<String, dynamic>>(ApiConstants.authMePath);
    final responseData = response.data ?? <String, dynamic>{};
    final dataSection = responseData['data'];

    Map<String, dynamic>? userJson;
    if (dataSection is Map<String, dynamic>) {
      final userValue = dataSection['user'];
      if (userValue is Map<String, dynamic>) {
        userJson = userValue;
      } else if (userValue is Map) {
        userJson = userValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } else if (dataSection is Map) {
      final normalizedData = dataSection.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final userValue = normalizedData['user'];
      if (userValue is Map<String, dynamic>) {
        userJson = userValue;
      } else if (userValue is Map) {
        userJson = userValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (userJson == null) {
      throw ApiException.fromMessage(
        statusCode: response.statusCode,
        message: 'Profile response was missing the user payload',
      );
    }

    return UserModel.fromJson(userJson);
  }

  Future<PickupRequestModel> createPickup({
    required File imageFile,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? scheduledTimeIso,
    required List<String> materialTypes,
    double? estimatedWeight,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'image': MultipartFile.fromFileSync(imageFile.path),
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
    });

    if (scheduledTimeIso != null && scheduledTimeIso.isNotEmpty) {
      formData.fields.add(MapEntry('scheduledTime', scheduledTimeIso));
    }
    if (materialTypes.isNotEmpty) {
      formData.fields.add(MapEntry('materialTypes', materialTypes.join(',')));
    }
    if (estimatedWeight != null) {
      formData.fields.add(
        MapEntry('estimatedWeight', estimatedWeight.toString()),
      );
    }

    final response = await post<Map<String, dynamic>>(
      ApiConstants.pickupsPath,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final responseData = response.data ?? <String, dynamic>{};
    final dataSection = responseData['data'];
    Map<String, dynamic>? pickupJson;

    if (dataSection is Map<String, dynamic>) {
      final pickupValue = dataSection['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } else if (dataSection is Map) {
      final normalizedData = dataSection.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final pickupValue = normalizedData['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (pickupJson == null) {
      throw ApiException.fromMessage(
        statusCode: response.statusCode,
        message: 'Create pickup response was missing the pickup payload',
      );
    }

    return PickupRequestModel.fromJson(pickupJson);
  }

  Future<PaginatedResponseModel<PickupRequestModel>> getMyPickups({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await get<Map<String, dynamic>>(
      ApiConstants.pickupsPath,
      queryParameters: queryParameters,
    );
    final responseData = response.data ?? <String, dynamic>{};

    final dataSection = responseData['data'];
    Map<String, dynamic>? normalizedData;
    if (dataSection is Map<String, dynamic>) {
      normalizedData = dataSection;
    } else if (dataSection is Map) {
      normalizedData = dataSection.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (normalizedData == null) {
      throw ApiException.fromMessage(
        statusCode: response.statusCode,
        message: 'Get pickups response was missing data payload',
      );
    }

    return PaginatedResponseModel.fromJson(
      normalizedData,
      (json) => PickupRequestModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PickupRequestModel> getPickupById(String id) async {
    final response = await get<Map<String, dynamic>>(
      ApiConstants.pickupByIdPath(id),
    );
    final responseData = response.data ?? <String, dynamic>{};
    final dataSection = responseData['data'];

    Map<String, dynamic>? pickupJson;
    if (dataSection is Map<String, dynamic>) {
      final pickupValue = dataSection['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } else if (dataSection is Map) {
      final normalizedData = dataSection.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final pickupValue = normalizedData['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (pickupJson == null) {
      throw ApiException.fromMessage(
        statusCode: response.statusCode,
        message: 'Get pickup response was missing the pickup payload',
      );
    }

    return PickupRequestModel.fromJson(pickupJson);
  }

  Future<PickupRequestModel> updatePickup(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final response = await put<Map<String, dynamic>>(
      ApiConstants.pickupByIdPath(id),
      data: changes,
    );

    final responseData = response.data ?? <String, dynamic>{};
    final dataSection = responseData['data'];

    Map<String, dynamic>? pickupJson;
    if (dataSection is Map<String, dynamic>) {
      final pickupValue = dataSection['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } else if (dataSection is Map) {
      final normalizedData = dataSection.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final pickupValue = normalizedData['pickup'];
      if (pickupValue is Map<String, dynamic>) {
        pickupJson = pickupValue;
      } else if (pickupValue is Map) {
        pickupJson = pickupValue.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    if (pickupJson == null) {
      throw ApiException.fromMessage(
        statusCode: response.statusCode,
        message: 'Update pickup response was missing the pickup payload',
      );
    }

    return PickupRequestModel.fromJson(pickupJson);
  }

  Future<void> cancelPickup(String id) async {
    await delete(ApiConstants.pickupByIdPath(id));
  }

  Future<void> dispose() async {
    await _sessionExpiredController.close();
    _dio.close();
    _refreshDio.close();
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuthHeader(options.path, options.extra)) {
      handler.next(options);
      return;
    }

    final accessToken = await _secureStorageService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final statusCode = response?.statusCode;
    final requestOptions = error.requestOptions;

    if (statusCode != 401) {
      handler.reject(_wrapAsDioException(error, _toApiException(error)));
      return;
    }

    if (_isAuthPublicPath(requestOptions.path)) {
      handler.reject(_wrapAsDioException(error, _toApiException(error)));
      return;
    }

    if (_isRefreshPath(requestOptions.path) ||
        requestOptions.extra[_retryMarker] == true) {
      await _forceSessionLogout();
      handler.reject(
        _wrapAsDioException(error, const SessionExpiredException()),
      );
      return;
    }

    try {
      await _refreshAccessTokenOnce();
      final retryResponse = await _retryWithFreshToken(requestOptions);
      handler.resolve(retryResponse);
    } on SessionExpiredException catch (sessionExpired) {
      handler.reject(_wrapAsDioException(error, sessionExpired));
    } on ApiException catch (apiException) {
      handler.reject(_wrapAsDioException(error, apiException));
    }
  }

  Future<Response<dynamic>> _retryWithFreshToken(
    RequestOptions requestOptions,
  ) async {
    final accessToken = await _secureStorageService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const SessionExpiredException();
    }

    final retryHeaders = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $accessToken';

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: retryHeaders,
        extra: <String, dynamic>{...requestOptions.extra, _retryMarker: true},
      ),
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }

  Future<void> _refreshAccessTokenOnce() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await _secureStorageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          throw const SessionExpiredException();
        }

        final response = await _refreshDio.post<Map<String, dynamic>>(
          ApiConstants.authRefreshPath,
          data: <String, dynamic>{'refreshToken': refreshToken},
        );

        final responseData = response.data ?? <String, dynamic>{};
        final tokenData = responseData['data'];
        if (tokenData is! Map) {
          throw ApiException.fromMessage(
            statusCode: response.statusCode,
            message: 'Refresh response was missing token data',
          );
        }

        final tokenMap = tokenData.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final accessToken = tokenMap['accessToken']?.toString();
        final newRefreshToken = tokenMap['refreshToken']?.toString();
        if (accessToken == null ||
            accessToken.isEmpty ||
            newRefreshToken == null ||
            newRefreshToken.isEmpty) {
          throw ApiException.fromMessage(
            statusCode: response.statusCode,
            message: 'Refresh response did not include new tokens',
          );
        }

        await _secureStorageService.saveTokens(accessToken, newRefreshToken);
        completer.complete();
      } on DioException catch (error) {
        final apiException = _toApiException(error);
        if (apiException.statusCode == 401) {
          await _forceSessionLogout();
          completer.completeError(const SessionExpiredException());
          return;
        }

        completer.completeError(apiException);
      } on SessionExpiredException catch (sessionExpired) {
        await _forceSessionLogout();
        completer.completeError(sessionExpired);
      } on ApiException catch (apiException) {
        if (apiException.statusCode == 401) {
          await _forceSessionLogout();
          completer.completeError(const SessionExpiredException());
          return;
        }

        completer.completeError(apiException);
      } catch (error) {
        completer.completeError(
          ApiException.fromMessage(statusCode: null, message: error.toString()),
        );
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }

  Future<void> _forceSessionLogout() async {
    await _secureStorageService.clearTokens();
    _sessionExpiredController.add(null);
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;
    if (response != null) {
      return ApiException.fromResponse(
        statusCode: response.statusCode,
        responseData: response.data,
        fallbackMessage: error.message,
      );
    }

    return ApiException.fromMessage(
      statusCode: null,
      message: error.message ?? 'Request failed',
    );
  }

  DioException _wrapAsDioException(
    DioException original,
    ApiException apiException,
  ) {
    return DioException(
      requestOptions: original.requestOptions,
      response: original.response,
      type: DioExceptionType.badResponse,
      error: apiException,
      message: apiException.message,
    );
  }

  bool _shouldSkipAuthHeader(String path, Map<String, dynamic> extra) {
    if (extra['skipAuth'] == true) {
      return true;
    }

    return _isAuthPublicPath(path) || _isRefreshPath(path);
  }

  bool _isAuthPublicPath(String path) {
    return path == ApiConstants.authLoginPath ||
        path == ApiConstants.authRegisterPath;
  }

  bool _isRefreshPath(String path) {
    return path == ApiConstants.authRefreshPath;
  }
}
