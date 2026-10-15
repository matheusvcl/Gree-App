# Gree-App

Refazer o app da Gree (ar-condicionado) para uso pessoal, nativo no Android.

## Estado atual

- `mockup/app.html` — mockup interativo do app redesenhado (Início, Controle com dial de temperatura, Agenda, Energia, Perfil). Escuro/claro, 3 aparelhos de exemplo, interativo de verdade.
- Teste de resoluções/molduras feito no **Mobile Mockup** (`D:\GitHub\Mobile-Mockup`) — laboratório genérico de dispositivos (Android/iOS/Pixel, vários modelos e resoluções). O mockup está em `Mobile-Mockup/examples/gree.html` e também pode ser carregado por caminho relativo.

## Engenharia reversa do GREE+ oficial

- `re/analise-gree-plus.md` — análise do GREE+ 1.27.0.14 (APKPure): arquitetura (Flutter plugin + container empacotado), pareamento via Broadlink BLEasyConfig, nuvem GRIH, MQTT, storage. Artefatos em `re/strings/` e `re/stub-sources/`.

## Próximo

App nativo Android (pessoal) consumindo a API local dos aparelhos Gree.
