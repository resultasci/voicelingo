import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/services/account_service.dart';

final accountServiceProvider =
    Provider<AccountService>((ref) => AccountService());
