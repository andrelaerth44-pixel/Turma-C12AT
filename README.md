# Turma C12AT

Aplicativo móvel coletivo para uma única turma escolar: conversa da turma, materiais, estudo assistido por IA e administração.

## Stack

- Flutter + Dart
- Material 3
- Supabase Auth, PostgreSQL, Storage e Realtime
- Row Level Security (RLS)
- Edge Functions para operações privilegiadas e IA
- FCM para notificações push
- ML Kit para OCR no dispositivo quando apropriado

## Regras do produto

- Uma instalação pertence a uma turma autorizada.
- Uma única conversa coletiva por turma.
- Sem mensagens privadas, grupos secundários, canais ou comunidades.
- Segredos de IA e credenciais privilegiadas nunca ficam no aplicativo.
- Toda tabela exposta ao Data API terá RLS.
- O cliente não trata mensagens como enviadas antes da confirmação do servidor.

## Estrutura planejada

```text
lib/
  core/
  features/
    auth/
    onboarding/
    home/
    chat/
    messages/
    materials/
    ai_study/
    profile/
    notifications/
    administration/
  services/
  main.dart

supabase/
  migrations/
  functions/
  seed.sql
```

## Estado atual

A base Flutter inicial e a navegação principal foram criadas. A próxima etapa é substituir o shell por módulos reais e conectar um projeto Supabase novo, sem dependências do Product Hub.
