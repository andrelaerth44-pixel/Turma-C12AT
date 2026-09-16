import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AIService {
  Future<Map<String, dynamic>> ask({required String prompt, String? materialId, String? context});
  Future<Map<String, dynamic>> summarize(String materialId, {bool simple = false});
  Future<Map<String, dynamic>> quiz(String materialId, {int count = 10});
  Future<Map<String, dynamic>> mindMap(String materialId);
}

class SupabaseAIService implements AIService {
  final SupabaseClient client;
  SupabaseAIService(this.client);

  Future<Map<String, dynamic>> _invoke(String function, Map<String, dynamic> body) async {
    final response = await client.functions.invoke(function, body: body);
    if (response.status < 200 || response.status >= 300) throw Exception('Serviço de estudo indisponível.');
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : {'result': data};
  }

  @override
  Future<Map<String, dynamic>> ask({required String prompt, String? materialId, String? context}) => _invoke('ask-study-ai', {'prompt': prompt, 'material_id': materialId, 'context': context});
  @override
  Future<Map<String, dynamic>> summarize(String materialId, {bool simple = false}) => _invoke('generate-summary', {'material_id': materialId, 'simple': simple});
  @override
  Future<Map<String, dynamic>> quiz(String materialId, {int count = 10}) => _invoke('generate-quiz', {'material_id': materialId, 'count': count});
  @override
  Future<Map<String, dynamic>> mindMap(String materialId) => _invoke('generate-mindmap', {'material_id': materialId});
}
