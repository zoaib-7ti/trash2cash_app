class PaginationModel {
  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

class PaginatedResponseModel<T> {
  const PaginatedResponseModel({required this.data, required this.pagination});

  final List<T> data;
  final PaginationModel pagination;

  factory PaginatedResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final dataList = (json['data'] as List<dynamic>? ?? const <dynamic>[])
        .map(fromJsonT)
        .toList(growable: false);

    return PaginatedResponseModel<T>(
      data: dataList,
      pagination: PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson([Object Function(T value)? toJsonT]) {
    return <String, dynamic>{
      'data': data.map((item) => toJsonT == null ? item : toJsonT(item)).toList(growable: false),
      'pagination': pagination.toJson(),
    };
  }
}