class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  final String field;
  final String message;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'field': field,
      'message': message,
    };
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int? statusCode;
  final String message;
  final List<ApiFieldError>? errors;

  bool get hasFieldErrors => errors != null && errors!.isNotEmpty;

  factory ApiException.fromResponse({
    required int? statusCode,
    required Object? responseData,
    String? fallbackMessage,
  }) {
    final parsed = _parseResponsePayload(responseData, fallbackMessage: fallbackMessage);
    return ApiException(
      statusCode: statusCode,
      message: parsed.message,
      errors: parsed.errors,
    );
  }

  factory ApiException.fromMessage({
    required String message,
    int? statusCode,
    List<ApiFieldError>? errors,
  }) {
    return ApiException(statusCode: statusCode, message: message, errors: errors);
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, errors: $errors)';
  }

  static _ParsedApiError _parseResponsePayload(
    Object? payload, {
    String? fallbackMessage,
  }) {
    if (payload is Map<String, dynamic>) {
      return _ParsedApiError.fromMap(payload, fallbackMessage: fallbackMessage);
    }

    if (payload is Map) {
      return _ParsedApiError.fromMap(
        payload.map((key, value) => MapEntry(key.toString(), value)),
        fallbackMessage: fallbackMessage,
      );
    }

    if (payload is String && payload.trim().isNotEmpty) {
      return _ParsedApiError(
        message: payload,
        errors: null,
      );
    }

    return _ParsedApiError(
      message: fallbackMessage ?? 'Request failed',
      errors: null,
    );
  }
}

class SessionExpiredException extends ApiException {
  const SessionExpiredException({super.message = 'Session expired, please log in again'})
      : super(statusCode: 401, errors: null);
}

class _ParsedApiError {
  const _ParsedApiError({required this.message, required this.errors});

  final String message;
  final List<ApiFieldError>? errors;

  factory _ParsedApiError.fromMap(
    Map<String, dynamic> map, {
    String? fallbackMessage,
  }) {
    final errorsValue = map['errors'];
    return _ParsedApiError(
      message: map['message']?.toString() ?? fallbackMessage ?? 'Request failed',
      errors: _parseErrors(errorsValue),
    );
  }

  static List<ApiFieldError>? _parseErrors(Object? errorsValue) {
    if (errorsValue is! List) {
      return null;
    }

    final parsedErrors = errorsValue
        .whereType<Map>()
        .map(
          (error) => ApiFieldError.fromJson(
            error.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);

    return parsedErrors.isEmpty ? null : parsedErrors;
  }
}