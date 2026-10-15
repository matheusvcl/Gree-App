# Changelog

Mudanças do app — o que você vê e usa. Não inclui infraestrutura de build/CI.

Formato: cada versão tem uma seção `## vX.Y.Z — data`. As notas das releases do
GitHub são geradas automaticamente a partir daqui, e o app mostra estas seções
em Perfil → Atualizações.

## v1.0.3 — 2026-10-15

### Novo
- Tela "Atualizações" em Perfil, com a versão instalada, verificação manual e o histórico de mudanças do app (este changelog), sem sair do app.

### Alterado
- O aviso de atualização mostra apenas a versão, sem número de build.
- As notas das releases agora são geradas a partir deste changelog.

## v1.0.2 — 2026-10-15

### Corrigido
- Download da atualização não completava em instalações ligadas ao repositório privado; agora usa o caminho de download correto.
- Quando o download da atualização falha, o aviso explica o problema e deixa tentar de novo — antes sumia sem explicar.

### Alterado
- Aviso de "verificando atualizações" agora segue o design do app (superfície e borda do tema), no claro e no escuro.

## v1.0.1 — 2026-10-15

### Novo
- Escolha do ícone do app em Perfil → Ícones: variantes Escuro, Claro, Azul e Mono, aplicadas na tela inicial e na lista de aplicativos na hora. A escolha é lembrada entre sessões.

### Alterado
- Arquivo do APK passa a se chamar Gree-v[versão].apk.
- Apoio a partir do Android 9.

## v1.0.0 — 2026-10-15

### Novo
- Primeira versão.
- Início com os aparelhos por ambiente, contagem de ligados e destaque animado no card ligado.
- Controle do ar com dial de temperatura por arraste, modos, velocidade do vento e oscilação.
- Agenda com rotinas: deslizar para a direita edita, para a esquerda exclui (com confirmação), toque longo seleciona várias de uma vez, e as próximas 24 horas consideram os dias reais de cada rotina.
- Energia com consumo por dia e por aparelho.
- Perfil com gerenciar locais (reordenar arrastando, o primeiro vira o ativo), modo família com temperaturas por usuário, notificações, moeda e energia e integrações.
- Tema claro/escuro, °C/°F e o estado completo lembrado entre sessões (minimizar e reabrir volta à tela que estava).
- Atualização automática: o app avisa quando existe versão nova, baixa e instala direto.
