import 'package:flutter/foundation.dart';
import '../../../models/user_model.dart';
import '../../../services/mock_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = MockAuthService.instance;

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user      => _user;
  bool       get isLoading => _loading;
  String?    get error     => _error;

  // Returns true on success
  Future<bool> login(String phone, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _auth.signInWithPhone(phone: phone, password: password);
      _loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}