import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Public URL of the FastAPI service on Render (Swagger UI: $baseUrl/docs).
const String baseUrl = 'https://linear-regression-model-ftfw.onrender.com';

/// Result of a successful call to POST /predict.
class Prediction {
  final int recordsExposed;
  final double log10Records;
  final String severity;

  Prediction({required this.recordsExposed, required this.log10Records, required this.severity});

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        recordsExposed: (json['predicted_records_exposed'] as num).toInt(),
        log10Records: (json['predicted_log10_records'] as num).toDouble(),
        severity: json['severity'] as String,
      );
}

/// Error with a message that can be shown to the user as-is.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Sends the 12 incident inputs to POST /predict and returns the prediction.
Future<Prediction> fetchPrediction(Map<String, dynamic> inputs) async {
  final uri = Uri.parse('$baseUrl/predict');
  final http.Response response;
  try {
    response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(inputs),
        )
        // A free Render service can take up to a minute to wake up.
        .timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw ApiException('The server took too long to respond. It may be waking up, so please try again.');
  } on SocketException {
    throw ApiException('No internet connection, or the server could not be reached.');
  } on http.ClientException {
    throw ApiException('Could not connect to the prediction server.');
  }

  if (response.statusCode == 200) {
    return Prediction.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  if (response.statusCode == 422) {
    throw ApiException(_readableValidationError(response.body));
  }
  throw ApiException('Server error (${response.statusCode}). Please try again later.');
}

/// Turns FastAPI/Pydantic 422 details into short sentences such as
/// "Incident year: Input should be less than or equal to 2030".
String _readableValidationError(String body) {
  try {
    final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
    if (detail is List) {
      return detail.map((e) {
        final loc = (e['loc'] as List).last.toString().replaceAll('_', ' ');
        final field = loc.isEmpty ? loc : loc[0].toUpperCase() + loc.substring(1);
        return '$field: ${e['msg']}';
      }).join('\n');
    }
    return detail.toString();
  } catch (_) {
    return 'The server rejected the input. Please check the values.';
  }
}
