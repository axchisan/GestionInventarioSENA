import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();
  final AuthProvider? _authProvider;

  ApiService({AuthProvider? authProvider}) : _authProvider = authProvider;

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      throw _handleNetworkError(e, 'POST', endpoint);
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    Map<String, String> finalQueryParams = queryParams ?? {};
    
    // For admin_general role, add system-wide access parameter
    if (_authProvider?.currentUser?.role == 'admin_general') {
      finalQueryParams['system_wide'] = 'true';
      finalQueryParams['admin_access'] = 'true';
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: finalQueryParams.isNotEmpty ? finalQueryParams : null);
    
    try {
      final response = await _client.get(
        uri,
        headers: headers,
      );

      return _handleGetResponse(response, endpoint);
    } catch (e) {
      throw _handleNetworkError(e, 'GET', endpoint);
    }
  }

  Future<Map<String, dynamic>> getSingle(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    Map<String, String> queryParams = {};
    if (_authProvider?.currentUser?.role == 'admin_general') {
      queryParams['system_wide'] = 'true';
      queryParams['admin_access'] = 'true';
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null
    );
    
    try {
      final response = await _client.get(
        uri,
        headers: headers,
      );

      return _handleSingleResponse(response, endpoint);
    } catch (e) {
      throw _handleNetworkError(e, 'GET', endpoint);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await _client.delete(
        uri,
        headers: headers,
      );

      return _handleResponse(response, 'DELETE', endpoint);
    } catch (e) {
      throw _handleNetworkError(e, 'DELETE', endpoint);
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return _handleResponse(response, 'PUT', endpoint);
    } catch (e) {
      throw _handleNetworkError(e, 'PUT', endpoint);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response, String method, String endpoint) {
    // Handle redirects
    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        // For now, throw an error as we can't easily handle redirects in this context
        throw ApiException(
          'Redirección detectada a: $redirectUrl',
          statusCode: response.statusCode,
          endpoint: endpoint,
          method: method,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {'status': 'success'};
        }
        return json.decode(response.body);
      } catch (e) {
        throw ApiException(
          'Error decodificando respuesta JSON',
          statusCode: response.statusCode,
          endpoint: endpoint,
          method: method,
          originalError: e,
        );
      }
    } else {
      throw _createApiException(response, method, endpoint);
    }
  }

  dynamic _handleGetResponse(http.Response response, String endpoint) {
    // Handle redirects
    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        throw ApiException(
          'Redirección detectada a: $redirectUrl',
          statusCode: response.statusCode,
          endpoint: endpoint,
          method: 'GET',
        );
      }
    }

    if (response.statusCode == 200) {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        return [];
      }
      
      try {
        final decoded = json.decode(responseBody);
        return decoded;
      } catch (e) {
        print('Error decoding JSON response from $endpoint: $e');
        return [];
      }
    } else if (response.statusCode == 404) {
      final userRole = _authProvider?.currentUser?.role;
      
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'detail': 'Recurso no encontrado'};
      }
      
      // For admin_general accessing missing endpoints, return empty data instead of throwing
      if (userRole == 'admin_general') {
        print('Admin general accessing missing endpoint $endpoint, returning empty data');
        return [];
      }
      
      throw ApiException(
        errorData['detail'] ?? 'Recurso no encontrado',
        statusCode: 404,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.notFound,
      );
    } else if (response.statusCode == 403) {
      final userRole = _authProvider?.currentUser?.role;
      
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'detail': 'Acceso no autorizado'};
      }
      
      // For admin_general, try to return empty data instead of throwing
      if (userRole == 'admin_general') {
        print('Admin general access denied for $endpoint, returning empty data');
        return [];
      }
      
      throw ApiException(
        errorData['detail'] ?? 'No tienes permisos para acceder a este recurso',
        statusCode: 403,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.authorization,
      );
    } else if (response.statusCode == 400) {
      // Handle bad request errors
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'detail': 'Solicitud inválida'};
      }
      
      final userRole = _authProvider?.currentUser?.role;
      final errorDetail = errorData['detail'] ?? '';
      
      // For admin_general with environment binding issues, return empty data
      if (userRole == 'admin_general' && errorDetail.contains('ambiente')) {
        print('Admin general environment binding issue for $endpoint, returning empty data');
        return [];
      }
      
      throw ApiException(
        errorData['detail'] ?? 'Error en la solicitud',
        statusCode: 400,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.badRequest,
        details: errorData,
      );
    } else {
      throw _createApiException(response, 'GET', endpoint);
    }
  }

  Map<String, dynamic> _handleSingleResponse(http.Response response, String endpoint) {
    // Handle redirects
    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        throw ApiException(
          'Redirección detectada a: $redirectUrl',
          statusCode: response.statusCode,
          endpoint: endpoint,
          method: 'GET',
        );
      }
    }

    if (response.statusCode == 200) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw ApiException(
          'Error decodificando respuesta JSON',
          statusCode: response.statusCode,
          endpoint: endpoint,
          method: 'GET',
          originalError: e,
        );
      }
    } else if (response.statusCode == 404) {
      final userRole = _authProvider?.currentUser?.role;
      
      if (userRole == 'admin_general') {
        print('Admin general accessing missing single resource $endpoint, returning empty object');
        return {};
      }
      
      throw ApiException(
        'Recurso no encontrado',
        statusCode: 404,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.notFound,
      );
    } else if (response.statusCode == 403) {
      final userRole = _authProvider?.currentUser?.role;
      
      if (userRole == 'admin_general') {
        print('Admin general access denied for $endpoint, returning empty object');
        return {};
      }
      
      throw ApiException(
        'No tienes permisos para acceder a este recurso',
        statusCode: 403,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.authorization,
      );
    } else if (response.statusCode == 400) {
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (e) {
        errorData = {'detail': 'Error en la solicitud'};
      }
      
      final userRole = _authProvider?.currentUser?.role;
      final errorDetail = errorData['detail'] ?? '';
      
      if (userRole == 'admin_general' && errorDetail.contains('ambiente')) {
        print('Admin general environment binding issue for $endpoint, returning empty object');
        return {};
      }
      
      throw ApiException(
        errorData['detail'] ?? 'Error en la solicitud',
        statusCode: 400,
        endpoint: endpoint,
        method: 'GET',
        errorType: ApiErrorType.badRequest,
        details: errorData,
      );
    } else {
      throw _createApiException(response, 'GET', endpoint);
    }
  }

  ApiException _createApiException(http.Response response, String method, String endpoint) {
    Map<String, dynamic> errorData = {};
    String errorMessage = 'Error desconocido';
    ApiErrorType errorType = ApiErrorType.unknown;
    
    try {
      if (response.body.isNotEmpty) {
        errorData = json.decode(response.body);
        errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
      }
    } catch (e) {
      // If we can't parse the error body, use the status code
      errorMessage = _getDefaultErrorMessage(response.statusCode);
    }

    // Categorize error types
    switch (response.statusCode) {
      case 400:
        errorType = ApiErrorType.badRequest;
        break;
      case 401:
        errorType = ApiErrorType.unauthorized;
        errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
        break;
      case 403:
        errorType = ApiErrorType.authorization;
        errorMessage = errorMessage.isEmpty ? 'No tienes permisos para realizar esta acción' : errorMessage;
        break;
      case 404:
        errorType = ApiErrorType.notFound;
        errorMessage = 'Recurso no encontrado';
        break;
      case 422:
        errorType = ApiErrorType.validation;
        errorMessage = errorMessage.isEmpty ? 'Datos de entrada inválidos' : errorMessage;
        break;
      case 429:
        errorType = ApiErrorType.rateLimited;
        errorMessage = 'Demasiadas solicitudes. Intenta nuevamente más tarde.';
        break;
      case 500:
        errorType = ApiErrorType.serverError;
        errorMessage = 'Error interno del servidor. Intenta nuevamente más tarde.';
        break;
      case 502:
      case 503:
      case 504:
        errorType = ApiErrorType.serviceUnavailable;
        errorMessage = 'Servicio temporalmente no disponible. Intenta nuevamente más tarde.';
        break;
      default:
        errorType = ApiErrorType.unknown;
        errorMessage = 'Error inesperado (${response.statusCode})';
    }

    return ApiException(
      errorMessage,
      statusCode: response.statusCode,
      endpoint: endpoint,
      method: method,
      errorType: errorType,
      details: errorData,
    );
  }

  ApiException _handleNetworkError(dynamic error, String method, String endpoint) {
    String errorMessage = 'Error de conexión';
    ApiErrorType errorType = ApiErrorType.network;
    
    if (error.toString().contains('SocketException')) {
      errorMessage = 'Sin conexión a internet. Verifica tu conexión y vuelve a intentar.';
    } else if (error.toString().contains('TimeoutException')) {
      errorMessage = 'La solicitud tardó demasiado tiempo. Verifica tu conexión.';
      errorType = ApiErrorType.timeout;
    } else if (error.toString().contains('HandshakeException')) {
      errorMessage = 'Error de seguridad en la conexión. Verifica la configuración del servidor.';
      errorType = ApiErrorType.security;
    } else {
      errorMessage = 'Error de red: ${error.toString()}';
    }

    return ApiException(
      errorMessage,
      statusCode: 0,
      endpoint: endpoint,
      method: method,
      errorType: errorType,
      originalError: error,
    );
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado';
      case 403:
        return 'Acceso prohibido';
      case 404:
        return 'Recurso no encontrado';
      case 422:
        return 'Datos inválidos';
      case 429:
        return 'Demasiadas solicitudes';
      case 500:
        return 'Error interno del servidor';
      case 502:
        return 'Error de gateway';
      case 503:
        return 'Servicio no disponible';
      case 504:
        return 'Timeout del gateway';
      default:
        return 'Error HTTP $statusCode';
    }
  }

  Future<dynamic> getSystemWide(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    Map<String, String> finalQueryParams = queryParams ?? {};
    finalQueryParams['system_wide'] = 'true';
    finalQueryParams['all_environments'] = 'true';

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: finalQueryParams);
    
    try {
      final response = await _client.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          return [];
        }
        
        try {
          final decoded = json.decode(responseBody);
          return decoded;
        } catch (e) {
          print('Error decoding JSON response: $e');
          return [];
        }
      } else {
        // For system-wide requests, return empty data instead of throwing
        print('System-wide request failed for $endpoint: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network error in system-wide request for $endpoint: $e');
      return [];
    }
  }

  bool hasPermissionForEndpoint(String endpoint) {
    final userRole = _authProvider?.currentUser?.role;
    
    if (userRole == null) return false;
    
    // Admin general has access to all endpoints
    if (userRole == 'admin_general') return true;
    
    // Define role-based endpoint permissions
    final rolePermissions = {
      'supervisor': [
        inventoryChecksEndpoint,
        maintenanceRequestsEndpoint,
        environmentsEndpoint,
        reportsEndpoint,
      ],
      'admin': [
        loansEndpoint,
        loansWarehousesEndpoint,
        inventoryEndpoint,
        systemAlertsEndpoint,
        maintenanceRequestsEndpoint,
        reportsEndpoint,
      ],
      'instructor': [
        loansEndpoint,
        inventoryChecksEndpoint,
        inventoryEndpoint,
        notificationsEndpoint,
      ],
      'student': [
        inventoryChecksEndpoint,
        inventoryEndpoint,
        notificationsEndpoint,
      ],
    };
    
    final allowedEndpoints = rolePermissions[userRole] ?? [];
    return allowedEndpoints.any((allowed) => endpoint.startsWith(allowed));
  }

  Future<bool> checkEndpointExists(String endpoint) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (_authProvider?.token != null) {
        headers['Authorization'] = 'Bearer ${_authProvider!.token}';
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.head(uri, headers: headers);
      
      return response.statusCode != 404;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> safeGet(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      return await get(endpoint, queryParams: queryParams);
    } on ApiException catch (e) {
      final userRole = _authProvider?.currentUser?.role;
      
      // For admin_general, return empty data on certain errors instead of throwing
      if (userRole == 'admin_general' && 
          (e.statusCode == 404 || e.statusCode == 403 || e.statusCode == 400)) {
        print('Safe get for admin_general failed on $endpoint: ${e.message}');
        return [];
      }
      
      rethrow;
    } catch (e) {
      final userRole = _authProvider?.currentUser?.role;
      
      if (userRole == 'admin_general') {
        print('Safe get network error for admin_general on $endpoint: $e');
        return [];
      }
      
      rethrow;
    }
  }

  String getUserFriendlyErrorMessage(ApiException exception) {
    switch (exception.errorType) {
      case ApiErrorType.network:
        return 'Problema de conexión. Verifica tu internet y vuelve a intentar.';
      case ApiErrorType.timeout:
        return 'La operación tardó demasiado tiempo. Intenta nuevamente.';
      case ApiErrorType.unauthorized:
        return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      case ApiErrorType.authorization:
        return 'No tienes permisos para realizar esta acción.';
      case ApiErrorType.validation:
        return 'Los datos ingresados no son válidos. Revisa la información.';
      case ApiErrorType.notFound:
        return 'El recurso solicitado no fue encontrado.';
      case ApiErrorType.serverError:
        return 'Error en el servidor. Intenta nuevamente más tarde.';
      case ApiErrorType.serviceUnavailable:
        return 'El servicio no está disponible temporalmente.';
      case ApiErrorType.rateLimited:
        return 'Has realizado demasiadas solicitudes. Espera un momento.';
      case ApiErrorType.security:
        return 'Error de seguridad en la conexión.';
      default:
        return exception.message;
    }
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String endpoint;
  final String method;
  final ApiErrorType errorType;
  final Map<String, dynamic>? details;
  final dynamic originalError;

  ApiException(
    this.message, {
    required this.statusCode,
    required this.endpoint,
    required this.method,
    this.errorType = ApiErrorType.unknown,
    this.details,
    this.originalError,
  });

  @override
  String toString() {
    return 'ApiException: $message (${statusCode}) - $method $endpoint';
  }

  bool get isRecoverable {
    switch (errorType) {
      case ApiErrorType.network:
      case ApiErrorType.timeout:
      case ApiErrorType.serviceUnavailable:
      case ApiErrorType.rateLimited:
        return true;
      case ApiErrorType.unauthorized:
      case ApiErrorType.authorization:
      case ApiErrorType.validation:
      case ApiErrorType.notFound:
      case ApiErrorType.badRequest:
      case ApiErrorType.serverError:
      case ApiErrorType.security:
      case ApiErrorType.unknown:
        return false;
    }
  }

  Duration get retryDelay {
    switch (errorType) {
      case ApiErrorType.network:
      case ApiErrorType.timeout:
        return const Duration(seconds: 2);
      case ApiErrorType.serviceUnavailable:
        return const Duration(seconds: 5);
      case ApiErrorType.rateLimited:
        return const Duration(seconds: 10);
      default:
        return const Duration(seconds: 1);
    }
  }
}

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  authorization,
  validation,
  badRequest,
  notFound,
  serverError,
  serviceUnavailable,
  rateLimited,
  security,
  unknown,
}
