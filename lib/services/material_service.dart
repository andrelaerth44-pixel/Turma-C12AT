import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialService {
  final SupabaseClient client;
  MaterialService(this.client);

  Future<List<Map<String, dynamic>>> list(String classId) async {
    final rows = await client.from('materials').select('*, profiles!materials_uploaded_by_fkey(id,full_name), attachments(*)').eq('class_id', classId).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> upload({required String classId, required String name, required String mime, required Uint8List bytes}) async {
    final u = client.auth.currentUser!;
    final path = '${u.id}/${DateTime.now().millisecondsSinceEpoch}_$name';
    final bucket = mime == 'application/pdf' ? 'documents' : 'materials';
    await client.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    final material = await client.from('materials').insert({'class_id': classId, 'uploaded_by': u.id, 'title': name, 'processing_status': 'PENDING'}).select().single();
    await client.from('attachments').insert({'message_id': null, 'file_name': name, 'file_url': path, 'file_type': 'material', 'file_size': bytes.length, 'mime_type': mime});
    return Map<String, dynamic>.from(material);
  }

  Future<String> signedUrl(String bucket, String path) async => client.storage.from(bucket).createSignedUrl(path, 3600);
}
