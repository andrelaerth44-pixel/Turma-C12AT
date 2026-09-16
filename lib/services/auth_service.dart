import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client;
  AuthService(this.client);

  User? get user => client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) => client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await client.auth.signUp(email: email.trim(), password: password, data: {'full_name': name.trim()});
    if (response.user != null) {
      await client.from('profiles').upsert({'id': response.user!.id, 'full_name': name.trim()});
    }
    return response;
  }

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'turmac12at://login-callback');
  }

  Future<void> signOut() => client.auth.signOut();

  Future<Map<String, dynamic>?> profile() async {
    final u = user;
    if (u == null) return null;
    return await client.from('profiles').select().eq('id', u.id).maybeSingle();
  }

  Future<List<Map<String, dynamic>>> memberships() async {
    final u = user;
    if (u == null) return [];
    final rows = await client.from('class_members').select('*, classes(*)').eq('user_id', u.id).eq('status', 'approved').order('joined_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> createClass({required String name, String description = '', String institution = '', String schoolYear = ''}) async {
    final u = user!;
    final code = '${name.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase().substring(0, name.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').length.clamp(0, 4))}-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(3, 7)}';
    final cls = await client.from('classes').insert({'name': name.trim(), 'description': description.trim(), 'institution': institution.trim(), 'school_year': schoolYear.trim(), 'invite_code': code, 'created_by': u.id}).select().single();
    await client.from('class_members').insert({'class_id': cls['id'], 'user_id': u.id, 'role': 'admin', 'status': 'approved'});
    return Map<String, dynamic>.from(cls);
  }

  Future<void> requestJoin(String code) async {
    final u = user!;
    final cls = await client.from('classes').select('id').eq('invite_code', code.trim().toUpperCase()).eq('status', 'active').maybeSingle();
    if (cls == null) throw Exception('Código da turma inválido.');
    await client.from('class_members').upsert({'class_id': cls['id'], 'user_id': u.id, 'role': 'student', 'status': 'pending'}, onConflict: 'class_id,user_id');
  }
}
