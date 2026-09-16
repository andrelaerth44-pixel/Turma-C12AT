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

## Base Supabase reutilizada

O projeto vai reaproveitar a infraestrutura de autenticação do Supabase usada anteriormente no Product Hub, mantendo:

- login por e-mail e senha;
- login com Google;
- projeto Supabase e configuração de Auth já existentes;
- credenciais públicas necessárias para o cliente Flutter.

Os recursos específicos do Product Hub (organizações, vitrines, produtos, categorias, analytics e imagens de produtos) não fazem parte do Turma C12AT e serão removidos do banco. Os usuários do Supabase Auth não são apagados, para preservar o login existente.

## IA

A IA é acessada exclusivamente pelo backend/Edge Functions. A chave NVIDIA nunca é colocada no APK.

O aplicativo usa uma camada `AIService`, permitindo trocar o modelo sem alterar o restante da aplicação. O alvo atual é um modelo Llama servido pela NVIDIA, priorizando velocidade e capacidade de raciocínio; o identificador fica em configuração de backend para permitir atualização sem publicar um novo APK.

## Regras do produto

- Uma instalação pertence a uma turma autorizada.
- Uma única conversa coletiva por turma.
- Sem mensagens privadas, grupos secundários, canais ou comunidades.
- Segredos de IA e credenciais privilegiadas nunca ficam no aplicativo.
- Toda tabela exposta ao Data API terá RLS.
- O cliente não trata mensagens como enviadas antes da confirmação do servidor.

## Estrutura

```text
lib/
  core/
    config/
    constants/
    errors/
    network/
    theme/
    utils/
    widgets/
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

A base Flutter inicial e a navegação principal já foram criadas. A próxima implementação transforma o shell em módulos reais, reaproveita o Auth do Supabase do Product Hub e substitui todo o modelo de dados de loja pelo modelo escolar do Turma C12AT.
