import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
