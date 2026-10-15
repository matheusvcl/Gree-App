# Changelog

Mudanças do app — o que você vê e usa. Não inclui infraestrutura de build/CI.

Formato: cada versão tem uma seção `## vX.Y.Z — data`. As notas das releases do
GitHub são geradas automaticamente a partir daqui, e o app mostra estas seções
em Perfil → Atualizações.

## v1.0.3 — 15/10/2026

### Novo
- Tela de Atualizações em Perfil: versão instalada, verificação manual e o histórico de mudanças do app (este changelog), sem sair do app.
- Onboarding de primeira abertura: o app nasce limpo e te guia por perfil (nome + avatar), configuração do ar, localização, modo família e tema. Os campos vêm vazios para você preencher.
- Avatares iguais aos do app original: 41 avatares (pessoas, animais e símbolos) em qualquer lugar do app, com seletor agrupado por categoria.
- Energia de verdade: o app detecta sua cidade e calcula a tarifa pela distribuidora oficial (base TE+TUSD da ANEEL + bandeira do mês), sempre atualizado. Dá para escolher a cidade por busca ou localização e trocar a distribuidora.
- Clima em tempo real na home, pela sua localização: temperatura, condição, umidade e sensação. Sem local definido, um cartão leva você a configurar.
- Modo família com convite: código de 6 caracteres e QR code — cada pessoa baixa o app, cria o perfil local e entra na família pelo código. Membros, locais e aparelhos ficam sincronizados entre os celulares.
- Gerenciar ar (em Controle → Gerenciar este ar): configuração do aparelho, troca de rede Wi-Fi, redefinição de fábrica e exclusão — tudo individual por aparelho.
- Tela própria de "Novo dispositivo" (o + da home): nome, ambiente, rede Wi-Fi e padrões (modo e temperatura).
- Tema por modo: em Aquecer, o dial, a onda do card e os ícones viram laranja.
- No onboarding, escolha entre tema claro ou escuro (já vem o do seu celular pré-selecionado).

### Alterado
- Títulos centralizados em todas as telas, igual ao app original.
- Botões flutuantes (Voltar, Salvar, Concluir) no estilo ghost, sem barra atrás, nos dois temas.
- O + de adicionar (dispositivo e rotina) agora fica à direita do título da seção, não mais flutuando.
- Controle: nome do ar centralizado, modos compactos (Auto, Frio, Calor, Seco, Vento) e o relógio do agendamento colado nos dois lados do ":".
- Ícone de lixeira para excluir em Gerenciar locais e no Modo família (vermelho).

### Corrigido
- Swipe das rotinas: deslizar à direita edita e à esquerda exclui, com botões quadrados iguais nos dois lados — o card não voa mais para fora da tela nem perde a borda.
- Rotina sem dias mostra "Uma vez" e a hora fica alinhada com os demais cards.
- Ao minimizar e voltar, o app continua exatamente na tela que estava.
- Marca d'água amarela que aparecia nos avisos do app.

## v1.0.2 — 15/10/2026

### Corrigido
- Download da atualização não completava em instalações ligadas ao repositório privado; agora usa o caminho de download correto.
- Quando o download da atualização falha, o aviso explica o problema e deixa tentar de novo — antes sumia sem explicar.

### Alterado
- Aviso de "verificando atualizações" agora segue o design do app (superfície e borda do tema), no claro e no escuro.

## v1.0.1 — 15/10/2026

### Novo
- Escolha do ícone do app em Perfil → Ícones: variantes Escuro, Claro, Azul e Mono, aplicadas na tela inicial e na lista de aplicativos na hora. A escolha é lembrada entre sessões.

### Alterado
- Arquivo do APK passa a se chamar Gree-v[versão].apk.
- Apoio a partir do Android 9.

## v1.0.0 — 15/10/2026

### Novo
- Primeira versão.
- Início com os aparelhos por ambiente, contagem de ligados e destaque animado no card ligado.
- Controle do ar com dial de temperatura por arraste, modos, velocidade do vento e oscilação.
- Agenda com rotinas: deslizar para a direita edita, para a esquerda exclui (com confirmação), toque longo seleciona várias de uma vez, e as próximas 24 horas consideram os dias reais de cada rotina.
- Energia com consumo por dia e por aparelho.
- Perfil com gerenciar locais (reordenar arrastando, o primeiro vira o ativo), modo família com temperaturas por usuário, notificações, moeda e energia e integrações.
- Tema claro/escuro, °C/°F e o estado completo lembrado entre sessões (minimizar e reabrir volta à tela que estava).
- Atualização automática: o app avisa quando existe versão nova, baixa e instala direto.
