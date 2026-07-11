import '../network/api_exception.dart';

enum RequestStatus { idle, loading, success, error }

class RequestState<T> {
  const RequestState({
    this.status = RequestStatus.idle,
    this.data,
    this.errorMessage,
    this.fieldErrors,
  });

  final RequestStatus status;
  final T? data;
  final String? errorMessage;
  final List<ApiFieldError>? fieldErrors;

  bool get isLoading => status == RequestStatus.loading;

  RequestState<T> copyWith({
    RequestStatus? status,
    Object? data = _unset,
    Object? errorMessage = _unset,
    Object? fieldErrors = _unset,
  }) {
    return RequestState<T>(
      status: status ?? this.status,
      data: identical(data, _unset) ? this.data : data as T?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      fieldErrors: identical(fieldErrors, _unset)
          ? this.fieldErrors
          : fieldErrors as List<ApiFieldError>?,
    );
  }
}

const Object _unset = Object();
