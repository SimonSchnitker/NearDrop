import 'package:near_drop/auth/domain/model/Consent.dart';
import 'package:near_drop/auth/domain/model/UserSession.dart';

class UserData
{
    String userId;
    DateTime createdAt;
    DateTime? updatedAt;
    DateTime? lastSignInAt;
    List<UserSession> sessions;
    List<Consent> privacyPolicyConsents;
    List<Consent> termsOfUseConsents;

    UserData({
        required this.userId,
        required this.createdAt,
        required this.updatedAt,
        required this.lastSignInAt,
        required this.sessions,
        required this.privacyPolicyConsents,
        required this.termsOfUseConsents,
    });
}