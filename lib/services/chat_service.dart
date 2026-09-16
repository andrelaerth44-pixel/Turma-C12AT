import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient client;
  ChatService(this.client);

  Future<List<Map<String, dynamic>>> messages(String classId, {int limit = 40, int offset = 0}) async {
    final rows = await client.from('messages').select('*, profiles!messages_sender_id_fkey(id,full_name,avatar_url), attachments(*)').eq('class_id', classId).isFilter('deleted_at', null).order('created_at', ascending: false).range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(rows.reversed);
  }

  Future<Map<String, dynamic>> send(String classId, String content, {String type = 'text', String? replyTo}) async {
    final u = client.auth.currentUser!;
    return await client.from('messages').insert({'class_id': classId, 'sender_id': u.id, 'content': content.trim(), 'message_type': type, 'reply_to_id': replyTo}).select('*, profiles!messages_sender_id_fkey(id,full_name,avatar_url)').single();
  }

  Future<void> edit(String id, String content) async => client.from('messages').update({'content': content.trim(), 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).eq('sender_id', client.auth.currentUser!.id);
  Future<void> delete(String id) async => client.from('messages').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id).eq('sender_id', client.auth.currentUser!.id);

  Future<void> react(String messageId, String reaction) async {
    final u = client.auth.currentUser!;
    await client.from('message_reactions').upsert({'message_id': messageId, 'user_id': u.id, 'reaction': reaction}, onConflict: 'message_id,user_id,reaction');
  }

  Stream<List<Map<String, dynamic>>> realtime(String classId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final channel = client.channel('class-chat-$classId').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'class_id', value: classId),
      callback: (_) async { controller.add(await messages(classId)); },
    ).subscribe();
    controller.onCancel = () async { await client.removeChannel(channel); await controller.close(); };
    return controller.stream;
  }
}
