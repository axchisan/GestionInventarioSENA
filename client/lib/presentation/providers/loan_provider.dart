import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../data/models/loan_model.dart';
import 'auth_provider.dart';
import '../../core/services/notification_service.dart';

class LoanProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  
  List<LoanModel> _loans = [];
  LoanStatsModel? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalLoans = 0;
  final int _perPage = 10;

  LoanProvider(this._authProvider);

  // Getters
  List<LoanModel> get loans => _loans;
  LoanStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalLoans => _totalLoans;
  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Create loan request
  Future<bool> createLoan(CreateLoanRequest request) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl$loansEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        await _createLoanNotification(
          type: 'loan_pending',
          title: 'Solicitud de Préstamo Enviada',
          message: request.isRegisteredItem 
              ? 'Tu solicitud de préstamo ha sido enviada y está pendiente de aprobación'
              : 'Tu solicitud de préstamo para "${request.itemName}" ha sido enviada y está pendiente de aprobación',
          priority: 'medium',
        );
        
        await fetchLoans();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al crear préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLoans({
    int page = 1,
    String? statusFilter,
    String? environmentId,
    String? instructorId,
    String? priority,
    bool append = false,
  }) async {
    if (!append) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': _perPage.toString(),
      };

      if (statusFilter?.isNotEmpty == true) {
        queryParams['status_filter'] = statusFilter!;
      }
      if (environmentId?.isNotEmpty == true) {
        queryParams['environment_id'] = environmentId!;
      }
      if (instructorId?.isNotEmpty == true) {
        queryParams['instructor_id'] = instructorId!;
      }
      if (priority?.isNotEmpty == true) {
        queryParams['priority'] = priority!;
      }

      final uri = Uri.parse('$baseUrl$loansEndpoint').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loansList = (data['loans'] as List)
            .map((json) => LoanModel.fromJson(json))
            .toList();

        if (append) {
          _loans.addAll(loansList);
        } else {
          _loans = loansList;
        }

        _currentPage = data['page'];
        _totalPages = data['total_pages'];
        _totalLoans = data['total'];
      } else {
        _errorMessage = 'Error al cargar préstamos';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
    } finally {
      if (!append) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Load more loans (pagination)
  Future<void> loadMoreLoans({
    String? statusFilter,
    String? environmentId,
    String? instructorId,
    String? priority,
  }) async {
    if (hasNextPage && !_isLoading) {
      await fetchLoans(
        page: _currentPage + 1,
        statusFilter: statusFilter,
        environmentId: environmentId,
        instructorId: instructorId,
        priority: priority,
        append: true,
      );
    }
  }

  // Fetch loan statistics
  Future<void> fetchStats({String? environmentId}) async {
    try {
      final queryParams = <String, String>{};
      if (environmentId?.isNotEmpty == true) {
        queryParams['environment_id'] = environmentId!;
      }

      final uri = Uri.parse('$baseUrl${loansEndpoint}stats').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _stats = LoanStatsModel.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al cargar estadísticas: $e';
      notifyListeners();
    }
  }

  // Get specific loan
  Future<LoanModel?> getLoan(String loanId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$loansEndpoint$loanId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoanModel.fromJson(data);
      }
      return null;
    } catch (e) {
      _errorMessage = 'Error al cargar préstamo: $e';
      notifyListeners();
      return null;
    }
  }

  // Update loan (approve, reject, return, etc.)
  Future<bool> updateLoan(String loanId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl$loansEndpoint$loanId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        await fetchLoans(); // Refresh the list
        await fetchStats(); // Refresh stats
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al actualizar préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Approve loan
  Future<bool> approveLoan(String loanId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl$loansEndpoint$loanId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final loan = _loans.firstWhere((l) => l.id == loanId);
        
        await _createLoanNotificationForUser(
          userId: loan.instructorId,
          type: 'loan_approved',
          title: 'Préstamo Aprobado',
          message: loan.isRegisteredItem 
              ? 'Tu solicitud de préstamo para ${loan.itemDetails?['name'] ?? 'el equipo solicitado'} ha sido aprobada'
              : 'Tu solicitud de préstamo para "${loan.itemName}" ha sido aprobada',
          priority: 'high',
        );
        
        await fetchLoans();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al aprobar préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject loan
  Future<bool> rejectLoan(String loanId, String reason) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl$loansEndpoint$loanId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode({'rejection_reason': reason}),
      );

      if (response.statusCode == 200) {
        final loan = _loans.firstWhere((l) => l.id == loanId);
        
        await _createLoanNotificationForUser(
          userId: loan.instructorId,
          type: 'loan_rejected',
          title: 'Préstamo Rechazado',
          message: loan.isRegisteredItem 
              ? 'Tu solicitud de préstamo para ${loan.itemDetails?['name'] ?? 'el equipo solicitado'} ha sido rechazada. Motivo: $reason'
              : 'Tu solicitud de préstamo para "${loan.itemName}" ha sido rechazada. Motivo: $reason',
          priority: 'high',
        );
        
        await fetchLoans();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al rechazar préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark loan as active (item delivered)
  Future<bool> activateLoan(String loanId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl$loansEndpoint$loanId/activate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final loan = _loans.firstWhere((l) => l.id == loanId);
        
        await _createLoanNotificationForUser(
          userId: loan.instructorId,
          type: 'loan_active',
          title: 'Préstamo Activo',
          message: loan.isRegisteredItem 
              ? 'Tu préstamo de ${loan.itemDetails?['name'] ?? 'el equipo'} está ahora activo. Recuerda devolverlo el ${loan.endDate}'
              : 'Tu préstamo de "${loan.itemName}" está ahora activo. Recuerda devolverlo el ${loan.endDate}',
          priority: 'medium',
        );
        
        await fetchLoans();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al activar préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Return loan
  Future<bool> returnLoan(String loanId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.put(
        Uri.parse('$baseUrl$loansEndpoint$loanId/return'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final loan = _loans.firstWhere((l) => l.id == loanId);
        
        await _createLoanNotificationForUser(
          userId: loan.instructorId,
          type: 'loan_returned',
          title: 'Préstamo Devuelto',
          message: loan.isRegisteredItem 
              ? 'Tu préstamo de ${loan.itemDetails?['name'] ?? 'el equipo'} ha sido marcado como devuelto. ¡Gracias!'
              : 'Tu préstamo de "${loan.itemName}" ha sido marcado como devuelto. ¡Gracias!',
          priority: 'low',
        );
        
        await fetchLoans();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al devolver préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkOverdueLoans() async {
    try {
      final now = DateTime.now();
      final overdueLoans = _loans.where((loan) {
        if (loan.status != 'active') return false;
        final endDate = DateTime.tryParse(loan.endDate);
        return endDate != null && endDate.isBefore(now);
      }).toList();

      for (final loan in overdueLoans) {
        final daysPastDue = now.difference(DateTime.parse(loan.endDate)).inDays;
        
        await _createLoanNotificationForUser(
          userId: loan.instructorId,
          type: 'loan_overdue',
          title: 'Préstamo Vencido',
          message: loan.isRegisteredItem 
              ? 'Tu préstamo de ${loan.itemDetails?['name'] ?? 'el equipo'} está vencido desde hace $daysPastDue días. Por favor devuélvelo lo antes posible.'
              : 'Tu préstamo de "${loan.itemName}" está vencido desde hace $daysPastDue días. Por favor devuélvelo lo antes posible.',
          priority: 'high',
        );
      }
    } catch (e) {
      debugPrint('Error checking overdue loans: $e');
    }
  }

  Future<void> _createLoanNotification({
    required String type,
    required String title,
    required String message,
    required String priority,
  }) async {
    try {
      final userId = _authProvider.currentUser?.id;
      if (userId != null) {
        await NotificationService.createLoanNotification(
          userId: userId,
          type: type,
          title: title,
          message: message,
          priority: priority,
        );
      }
    } catch (e) {
      debugPrint('Error creating loan notification: $e');
    }
  }

  Future<void> _createLoanNotificationForUser({
    required String userId,
    required String type,
    required String title,
    required String message,
    required String priority,
  }) async {
    try {
      await NotificationService.createLoanNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        priority: priority,
      );
    } catch (e) {
      debugPrint('Error creating loan notification for user: $e');
    }
  }

  // Delete loan (only pending loans by instructor)
  Future<bool> deleteLoan(String loanId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$loansEndpoint$loanId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 204) {
        await fetchLoans(); // Refresh the list
        await fetchStats(); // Refresh stats
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Error al eliminar préstamo';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter loans by status
  List<LoanModel> getLoansByStatus(String status) {
    return _loans.where((loan) => loan.status == status).toList();
  }

  // Get loans for current user (instructor)
  List<LoanModel> getMyLoans() {
    final currentUserId = _authProvider.currentUser?.id;
    if (currentUserId == null) return [];
    return _loans.where((loan) => loan.instructorId == currentUserId).toList();
  }

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchLoans(),
      fetchStats(),
    ]);
  }
}
