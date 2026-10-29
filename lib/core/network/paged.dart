/// Mirrors the backend `PageDTO` / `PaginationDTO` (dto/PageDTO.java).
class Paged<T> {
  const Paged({
    required this.data,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.isLast,
  });

  final List<T> data;

  /// 1-based page number (the backend adds 1 to Spring's 0-based index).
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool isLast;

  bool get hasMore => !isLast;

  static Paged<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawList = (json['data'] as List<dynamic>? ?? const []);
    final pagination =
        (json['pagination'] as Map<String, dynamic>?) ?? const {};
    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map(fromItem)
        .toList(growable: false);
    return Paged<T>(
      data: list,
      pageNumber: (pagination['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (pagination['pageSize'] as num?)?.toInt() ?? list.length,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      totalElements:
          (pagination['totalElements'] as num?)?.toInt() ?? list.length,
      isLast: pagination['last'] as bool? ?? true,
    );
  }

  static Paged<T> empty<T>() => Paged<T>(
        data: const [],
        pageNumber: 1,
        pageSize: 0,
        totalPages: 0,
        totalElements: 0,
        isLast: true,
      );
}
