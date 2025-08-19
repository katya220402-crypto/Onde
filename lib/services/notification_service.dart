import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  Future<void> initAndSyncToken() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final t = await fcm.getToken();
    if (t != null) {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': t}).eq('id', u.id);
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((nt) async {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': nt}).eq('id', u.id);
    });
  }
}
