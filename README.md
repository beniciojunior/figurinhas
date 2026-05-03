# Figurinhas da Copa — Prompt Final Completo

Crie um app iOS em **SwiftUI**, orientação **portrait (mobile)**, com design caprichado usando componentes nativos do SwiftUI e visual iOS moderno (incluindo materiais/efeitos atuais no estilo Liquid Glass), com suporte a **Light Mode** e **Dark Mode**.

O app é um controle de figurinhas da Copa do Mundo, com persistência local da coleção do usuário e scanner por OCR.

## Objetivo
- Gerenciar quais figurinhas o usuário possui.
- Mostrar quais estão repetidas.
- Adicionar/remover rapidamente por toque ou scanner.
- Consultar no scanner de status se a figurinha já existe na coleção.

## Navegação
- Bottom bar com **3 abas**:
1. Coleção (grid completo)
2. Scanner de ação (Adicionar/Remover)
3. Scanner de status (Tenho/Não tenho)

## Modelo de dados (obrigatório)
Salvar cada figurinha com:
- `grupo` (ex.: `Grupo A`, `FWC`, `Coca-Cola`, `Página Inicial`)
- `pais` (quando aplicável)
- `sigla` (ex.: `BRA`, `PAN`, `FWC`, `CC`)
- `numero` (ex.: `1`, `19`, `00`, `14`)
- `codigo` derivado para identificação única (ex.: `PAN 19`, `CC14`, `FWC 10`, `FWC 00`)

Para coleção do usuário:
- Quantidade por `codigo` (`count`)
- Regras:
  - `count == 0`: não tenho
  - `count == 1`: tenho
  - `count >= 2`: repetida

## Tela 1 — Coleção (grid)
- Exibir todas as figurinhas possíveis, organizadas por grupo/seção.
- Cada card deve mostrar no mínimo:
  - sigla + número
  - quantidade atual
  - informação de país/grupo no contexto da seção
- Cores/estados visuais distintos para:
  - não tenho
  - tenho
  - repetida
- Interações:
  - toque no card: `+1`
  - press and hold no card: `-1` (mínimo 0)
- Layout:
  - evitar visual de “tabela pesada”; usar seções leves e modernas
- Filtro de repetidas:
  - ao tocar em “Repetidas” no topo, mostrar somente cards com `count >= 2`
  - ocultar todos os demais enquanto filtro estiver ativo

## Tela 2 — Scanner de ação
- Scanner com câmera + OCR de texto.
- Detectar padrões de figurinha no formato sigla+número, ex.:
  - `QAT 12`
  - `PAN 19`
  - `CC14`
  - `FWC 00`
- Segmented control:
  - `Adicionar`
  - `Remover`
- Comportamento:
  - **não usar modal de confirmação**
  - ao reconhecer figurinha válida, executar ação direta conforme modo
  - considerar novo scan apenas quando mudar a figurinha identificada
  - botão `Limpar` para permitir reprocessar a mesma figurinha
- Anti-spam/anti-loop:
  - enquanto o último resultado for o mesmo código, não reaplicar ação
- Parsing robusto (obrigatório):
  - evitar falso match por prefixo numérico
  - exemplo crítico: `PAN 19` **não pode** ser interpretado como `PAN 1`
  - usar matching por token completo ou regex com boundary
- Feedback:
  - som discreto para adicionar
  - som discreto para remover
  - vibração tátil leve em adicionar/remover
- UI:
  - remover moldura central do scanner
  - feedback visual não pode encavalar com a bottom bar

## Tela 3 — Scanner de status
- Também usa OCR para identificar figurinha.
- Não abre modal.
- Mostra apenas label com:
  - última figurinha escaneada
  - status: já tenho / ainda não tenho
- Só atualizar quando mudar o código detectado.
- Feedback:
  - se já tenho: som positivo, sem haptic
  - se não tenho: som negativo + vibração tátil de aviso
- Notificação/label deve respeitar área segura e não encavalar com bottom bar.

## Regras de OCR e normalização
- Normalizar entrada OCR:
  - uppercase
  - remover espaços duplicados
  - tratar variações com/sem espaço entre sigla e número (`PAN19`, `PAN 19`)
- Aceitar apenas códigos existentes no catálogo oficial.
- Ignorar leituras parciais/ambíguas.
- Estratégia recomendada:
  - tentar regex de maior especificidade primeiro (números com 2 dígitos antes de 1 dígito quando aplicável)
  - validar contra dicionário de códigos válidos

## Persistência
- Persistir catálogo e coleção localmente.
- Reabrir app mantendo contagens.
- Operações de scanner e grid atualizam estado em tempo real.

## Catálogo oficial de figurinhas

### FWC — Página Inicial
- Sigla base: `FWC`
- Números: `00`, `1` a `19`

### Grupo A
- México (`MEX`): 1–20
- África do Sul (`RSA`): 1–20
- Coréia do Sul (`KOR`): 1–20
- Rep. Tcheca (`CZE`): 1–20

### Grupo B
- Canadá (`CAN`): 1–20
- Bósnia (`BIH`): 1–20
- Catar (`QAT`): 1–20
- Suíça (`SUI`): 1–20

### Grupo C
- Brasil (`BRA`): 1–20
- Marrocos (`MAR`): 1–20
- Haiti (`HAI`): 1–20
- Escócia (`SCO`): 1–20

### Grupo D
- Estados Unidos (`USA`): 1–20
- Paraguai (`PAR`): 1–20
- Austrália (`AUS`): 1–20
- Turquia (`TUR`): 1–20

### Grupo E
- Alemanha (`GER`): 1–20
- Curaçao (`CUW`): 1–20
- Costa do Marfim (`CIV`): 1–20
- Equador (`ECU`): 1–20

### Grupo F
- Holanda (`NED`): 1–20
- Japão (`JPN`): 1–20
- Suécia (`SWE`): 1–20
- Tunísia (`TUN`): 1–20

### Grupo G
- Bélgica (`BEL`): 1–20
- Egito (`EGY`): 1–20
- Irã (`IRN`): 1–20
- Nova Zelândia (`NZL`): 1–20

### Grupo H
- Espanha (`ESP`): 1–20
- Cabo Verde (`CPV`): 1–20
- Arábia Saudita (`KSA`): 1–20
- Uruguai (`URU`): 1–20

### Grupo I
- França (`FRA`): 1–20
- Senegal (`SEN`): 1–20
- Iraque (`IRQ`): 1–20
- Noruega (`NOR`): 1–20

### Grupo J
- Argentina (`ARG`): 1–20
- Argélia (`ALG`): 1–20
- Áustria (`AUT`): 1–20
- Jordânia (`JOR`): 1–20

### Grupo K
- Portugal (`POR`): 1–20
- Congo (`COD`): 1–20
- Uzbequistão (`UZB`): 1–20
- Colômbia (`COL`): 1–20

### Grupo L
- Inglaterra (`ENG`): 1–20
- Croácia (`CRO`): 1–20
- Gana (`GHA`): 1–20
- Panamá (`PAN`): 1–20

### Seções Especiais
- FIFA World Cup History (`FWC`): 9, 10–19
- Figurinhas da Coca-Cola (`CC`): CC1 a CC14

## Resultado esperado
- App funcional nas 3 abas.
- Catálogo completo carregado com todos os metadados (`grupo`, `pais`, `sigla`, `numero`).
- Scanner confiável sem falso positivo de prefixo (`19` vs `1`).
- Feedback sonoro/tátil conforme regras.
- UI sem sobreposição com bottom bar.
