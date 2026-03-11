import 'package:supabase_flutter/supabase_flutter.dart';

/// رصيد المستخدم للهدايا.
class WalletBalance {
  const WalletBalance({
    required this.roses,
    required this.rings,
    required this.coffee,
  });

  final int roses;
  final int rings;
  final int coffee;

  int forGiftType(String giftType) {
    switch (giftType) {
      case 'rose_gift':
        return roses;
      case 'ring_gift':
        return rings;
      case 'coffee_gift':
        return coffee;
      default:
        return 0;
    }
  }

  bool canSend(String giftType) => forGiftType(giftType) > 0;
}

/// خدمة رصيد الهدايا.
/// الرصيد يُجلب ويُخصم عبر دوال آمنة في Supabase (get_or_create_wallet، deduct_gift).
/// إضافة الرصيد (بعد الشراء) تتم من السيرفر فقط (Edge Function مع service_role).
class WalletService {
  WalletService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// جلب رصيد المستخدم. يُنشئ المحفظة تلقائياً إن لم تكن موجودة (عبر RPC آمن).
  Future<WalletBalance> getBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const WalletBalance(roses: 0, rings: 0, coffee: 0);
    }

    try {
      final res = await _client.rpc('get_or_create_wallet');
      if (res is List && res.isNotEmpty) {
        final row = res.first as Map<String, dynamic>;
        return WalletBalance(
          roses: (row['roses_balance'] as num?)?.toInt() ?? 0,
          rings: (row['rings_balance'] as num?)?.toInt() ?? 0,
          coffee: (row['coffee_balance'] as num?)?.toInt() ?? 0,
        );
      }
      return const WalletBalance(roses: 0, rings: 0, coffee: 0);
    } catch (_) {
      return const WalletBalance(roses: 0, rings: 0, coffee: 0);
    }
  }

  /// خصم هدية من الرصيد عبر الدالة الآمنة deduct_gift. يُرجع true عند النجاح.
  Future<bool> deductGift(String giftType) async {
    if (_client.auth.currentUser == null) return false;
    if (!['rose_gift', 'ring_gift', 'coffee_gift'].contains(giftType)) {
      return false;
    }

    try {
      final balance = await getBalance();
      if (!balance.canSend(giftType)) return false;
      final res = await _client.rpc('deduct_gift', params: {'p_gift_type': giftType});
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// إضافة ورود للرصيد — تُنفَّذ من السيرفر فقط (Edge Function بعد التحقق من الدفع).
  /// من العميل تُرجع false؛ تحديث الرصيد محظور بـ RLS.
  Future<bool> addRoses(int count) async => _addBalanceServerOnly(count);

  /// إضافة خواتم — من السيرفر فقط (Edge Function).
  Future<bool> addRings(int count) async => _addBalanceServerOnly(count);

  /// إضافة قهوة — من السيرفر فقط (Edge Function).
  Future<bool> addCoffee(int count) async => _addBalanceServerOnly(count);

  /// إضافة رصيد من العميل غير مسموحة (RLS). الاستدعاء من Edge Function مع service_role.
  Future<bool> _addBalanceServerOnly(int count) async {
    if (count <= 0) return false;
    return false;
  }
}
