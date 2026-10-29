/// Normalised error raised by [ApiClient] so UI code can show one message.
///
/// The backend returns several error shapes (see GlobuleExceptionHandler):
/// - `{status, message}` for ApiException
/// - `{field: message, ...}` for bean validation errors (400)
/// - `{timestamp, message, status}` for duplicates (409)
/// - `{message, detail}` for unreadable JSON
/// - plain Spring error bodies for unhandled exceptions
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
