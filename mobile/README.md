# PermuteApp Mobile

App Flutter para a plataforma PermuteApp.

## Estrutura

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/          # Dio client + auth interceptor (refresh automático)
│   ├── config/       # baseUrl da API (configurável via --dart-define)
│   ├── router/       # go_router com redirect baseado em sessão
│   └── storage/      # tokens em flutter_secure_storage
└── features/
    ├── auth/         # login + cadastro de empresa
    ├── home/         # shell com bottom navigation
    ├── wallet/       # saldo, extrato, transferência P2P
    └── offers/       # marketplace + criação de oferta
```

## Rodar

```bash
flutter pub get
# Android emulator → API em 10.0.2.2
flutter run

# Apontar para outra API
flutter run --dart-define=API_BASE_URL=https://api.exemplo.com/api/v1
```

## State management

- **Riverpod** para DI/estado.
- **dio** com `AuthInterceptor` que injeta o access token e renova
  automaticamente quando recebe 401.
- **go_router** com redirect: usuário deslogado é mandado para `/login`,
  logado vai direto para `/wallet`.
