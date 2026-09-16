# Turma C12AT

Aplicativo móvel coletivo para uma única turma escolar: conversa coletiva, materiais, estudo assistido por IA e administração.

## Stack

- Flutter + Dart
- Material 3
- Supabase Auth, PostgreSQL, Storage e Realtime
- RLS em todas as tabelas públicas
- Supabase Edge Functions para IA e processamento
- NVIDIA NIM como provedor de LLM no backend
- Arquitetura `AIService` para trocar o modelo sem reescrever a app

## Interface

A interface combina Liquid Glass e Neomorphism sem `BackdropFilter`, sem blur e sem camada branca sobre o conteúdo. As superfícies são construídas com cor, bordas e sombras físicas leves. Há tema claro/escuro, navegação inferior, estados vazios/carregando/erro e animações discretas.

## Funcionalidades implementadas

- Login por e-mail e palavra-passe
- Cadastro de conta com perfil
- Login Google via Supabase OAuth
- Criação de turma com código de convite
- Entrada por código com aprovação do administrador
- Início com métricas reais de mensagens, materiais e membros
- Uma conversa coletiva por turma
- Mensagens em tempo real via Supabase Realtime
- Apagar as próprias mensagens
- Upload de materiais para Storage privado
- Listagem de materiais por turma
- Estudo com IA
- Resumo, quiz e mapa mental por material
- Assistente de estudo contextual
- Perfil e encerramento de sessão

## IA

As Edge Functions ativas são:

- `ask-study-ai`
- `generate-summary`
- `generate-quiz`
- `generate-mindmap`
- `process-material`

O modelo configurável padrão é `nvidia/llama-3.3-nemotron-super-49b-v1.5`. O identificador pode ser alterado no backend sem alterar o APK.

A API é chamada pelo endpoint OpenAI-compatible da NVIDIA. A chave deve existir somente como secret `NVIDIA_API_KEY` nas Edge Functions; nunca coloque uma chave NVIDIA no Flutter.

## Supabase

Projeto: `fmqdyaoqttvubynmjbxt`.

Tabelas principais: `profiles`, `classes`, `class_members`, `messages`, `message_reactions`, `attachments`, `materials`, `ai_analyses`, `quizzes`, `quiz_questions`, `quiz_attempts`, `announcements`, `notifications` e `reports`.

Os buckets privados são `avatars`, `materials`, `chat-media`, `documents`, `audio` e `video`.

Todas as tabelas públicas atuais estão com RLS habilitado. O acesso é condicionado à autenticação e à pertença à turma.

## Segurança

- Chaves privilegiadas ficam no backend.
- O APK usa apenas a chave publicável do Supabase.
- Não são usados `user_metadata` para autorização.
- Arquivos ficam em buckets privados.
- Edge Functions exigem JWT.
- Uma turma não pode consultar dados de outra turma através das políticas RLS.

## Android

O repositório inclui workflow de CI para gerar o projeto Android, executar `flutter pub get`, `flutter analyze` e gerar `app-release.apk` como artefato. O Android é gerado pelo Flutter no CI porque o repositório inicial foi criado sem a pasta de plataforma.

## Configuração obrigatória da IA

No projeto Supabase, configure o secret backend:

`NVIDIA_API_KEY`

Opcionalmente, defina:

`NVIDIA_MODEL=nvidia/llama-3.3-nemotron-super-49b-v1.5`

A configuração de secrets não é gravada no GitHub.

## Regra de produto

Uma instalação pertence a uma turma autorizada e existe apenas uma conversa coletiva por turma. Não há mensagens privadas, grupos secundários, canais ou comunidades.
