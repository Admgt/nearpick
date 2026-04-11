import 'app_user_profile.dart';
import 'product.dart';
import 'reservation.dart';

class AdminDashboardStats {
  final int userCount;
  final int merchantCount;
  final int customerCount;
  final int activeProductCount;
  final int reservationCount;
  final int completedReservationCount;

  const AdminDashboardStats({
    required this.userCount,
    required this.merchantCount,
    required this.customerCount,
    required this.activeProductCount,
    required this.reservationCount,
    required this.completedReservationCount,
  });

  factory AdminDashboardStats.fromCollections({
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
  }) {
    return AdminDashboardStats(
      userCount: users.length,
      merchantCount: users.where((user) => user.role == 'merchant').length,
      customerCount: users.where((user) => user.role == 'consumer').length,
      activeProductCount: products
          .where((product) => product.isEffectivelyActive)
          .length,
      reservationCount: reservations.length,
      completedReservationCount: reservations
          .where((reservation) => reservation.status == 'completed')
          .length,
    );
  }
}
