# Figurinhas da Copa — Prompt Final

Crie um projeto iOS em SwiftUI, orientação portrait (mobile), com design caprichado usando elementos padrão do SwiftUI, com suporte a Light e Dark Mode, para controle de figurinhas da Copa do Mundo.

## Estrutura do app
- 3 telas acessadas por bottom bar, usando visual moderno do iOS (incluindo Liquid Glass, ícones e componentes atuais).

## Tela 1 — Coleção (grid)
- Exibir todas as figurinhas possíveis, organizadas por grupos de países/seções.
- Cada card deve mostrar sigla + número da figurinha e quantidade que o usuário possui.
- Estados visuais:
  - Não tenho.
  - Tenho (cor diferente).
  - Repetida (outra cor).
- Interação:
  - Toque no card: adiciona 1 unidade.
  - Press and hold no card: remove 1 unidade.
- Ajustes de layout/comportamento:
  - Melhorar layout das sections (evitar visual pesado com fundo de tabela tradicional).
  - Ao tocar em “repetidas” no topo, filtrar e exibir somente cards repetidos (ocultando os demais).

## Tela 2 — Scanner para adicionar/remover
- Usar câmera + OCR para identificar texto de figurinha no formato `SIGLA + número` (ex.: `QAT 12`).
- Ter segmented control com opções `Adicionar` e `Remover`.
- Não abrir modal de confirmação.
- Ao reconhecer uma figurinha válida:
  - Executar ação diretamente conforme modo selecionado (adiciona/remove).
  - Só considerar novo scan quando a figurinha detectada mudar.
  - Disponibilizar botão `Limpar` para permitir escanear novamente a mesma figurinha.
- Feedback:
  - Som discreto específico para adicionar.
  - Som discreto específico para remover.
  - Leve vibração tátil ao adicionar/remover.
- Ajustes importantes:
  - Corrigir notificação/feedback para não encavalar com a bottom bar.
  - Corrigir falso match parcial (ex.: `PAN 19` não pode alternar com `PAN 1`); tratar parsing para evitar detecção errada por prefixo.
  - Remover a moldura central da tela de scanner.

## Tela 3 — Scanner de status (tenho/não tenho)
- Também usa OCR para `SIGLA + número`.
- Não abre modal.
- Exibe apenas uma label com a última figurinha escaneada e seu status.
- Só atualiza status quando a figurinha encontrada mudar.
- Feedback ao reconhecer:
  - Se já tenho: som positivo, sem haptic.
  - Se não tenho: som negativo + vibração tátil de aviso.

## Base de figurinhas
- FWC — Página inicial: `00`, `1 a 19`.
- Grupos A a L: 48 seleções, cada uma com 20 figurinhas (`1–20`).
- Seções especiais:
  - FIFA World Cup History (FWC): `9`, `10–19`.
  - Coca-Cola: `CC1` a `CC14`.
- Total esperado: **994 figurinhas**.

