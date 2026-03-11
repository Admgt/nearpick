import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  ReservationService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _auth = auth ?? FirebaseAuth.instance;

  Future<String> reserveProduct({required String productId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    try {
      final callable = _functions.httpsCallable('reserveProduct');
      final response = await callable.call(<String, dynamic>{
        'productId': productId,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      final reservationId = data['reservationId'] as String?;
      if (reservationId == null || reservationId.isEmpty) {
        throw Exception('A foglalas letrejott, de nincs reservationId.');
      }
      return reservationId;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'A foglalas nem sikerult.');
    }
  }

  Future<void> completeReservation({required String reservationId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    try {
      final callable = _functions.httpsCallable('completeReservation');
      await callable.call(<String, dynamic>{
        'reservationId': reservationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'A foglalas nem teljesitheto.');
    }
  }
}
