# 🎲 DungeonMath

> Um jogo de cartas onde matemática e fantasia se encontram. Construa equações, calcule dano e vença o dungeon.

DungeonMath é um projeto desenvolvido como atividade extensionista universitária — um card game de batalha onde as cartas representam números e operadores matemáticos. O jogador monta equações nos slots de ataque e defesa para causar e absorver dano. Atualmente em desenvolvimento ativo.

---

## 🧩 Sobre o Projeto

- **Gênero:** Card game de batalha por turnos
- **Engine:** Godot 4
- **Linguagem:** GDScript
- **Status:** Em desenvolvimento — funcionalidades base implementadas, desenvolvimento pausado temporariamente para produção do trailer de apresentação

---

## ⚙️ Tecnologias

| Ferramenta | Uso |
|---|---|
| [Godot 4](https://godotengine.org/) | Engine principal |
| GDScript | Lógica do jogo |
| Git + GitHub | Versionamento e colaboração |

---

## 🗺️ Cronograma de Desenvolvimento

O projeto está tecnicamente **adiantado** — o cronograma original previa início em julho (próximo semestre), mas várias etapas já estão funcionando.

### ✅ Etapa 1 — Correções e organização *(concluída)*
- Cartas dinâmicas, slots, deck e player hand funcionando
- Drag & drop e encaixe nos slots implementados
- CardDatabase com autoload configurado
- Valores aparecendo nas cartas

### ✅ Etapa 2 — Campo de batalha *(concluída)*
- `AttackZone` e `DefenseZone` com até 5 slots cada
- Zonas espelhadas para o NPC
- `CardSlot.gd` com referência à zona correspondente

### 🔲 Etapa 3 — Sistema de turnos
- `BattleManager.gd` com estados de turno
- Botão "Confirmar Jogada"
- Bloqueio de drag & drop fora do turno do jogador

### 🔲 Etapa 4 — EquationEngine
- Leitura das cartas nos slots de ataque
- Cálculo do resultado (`+`, `-`, `×`)
- Exibição do resultado na tela

### 🔲 Etapa 5 — DamageSystem
- Aplicação de dano na ordem Defesa → Vida
- Atualização visual de vida e defesa

### 🔲 Etapa 6 — NPC
- `NPCController.gd` com lógica básica por regras
- Aleatoriedade de 15%

### 🔲 Etapa 7 — Vitória e derrota
- Checagem de vida zerada ao fim do turno
- Telas de vitória e derrota
- Botão de jogar de novo / voltar ao menu

### 🔲 Etapa 8 — Menu
- Cena `Menu.tscn` com botões Jogar, Sair e Créditos
- Transição animada para a batalha

### 🔲 Etapa 9 — Exploração e diálogo
- `DungeonCorridor.tscn`
- Troca de imagens com seta ↑
- Sistema de diálogo com efeito typewriter
- Transição para batalha

### 🔲 Etapa 10 — Polish
- Efeitos sonoros
- Ajustes visuais finais
- Testes e correções gerais

---

## 🤝 Como Colaborar

### Antes de fazer qualquer commit

> ⚠️ **Antes de commitar qualquer coisa, me avisa primeiro.**

O fluxo é simples:

1. **Me fala o que você vai mexer** - importante para evitar conflito de versão.
2. **Crie uma branch** com um nome descritivo: `feature/nome-da-feature` ou `fix/nome-do-bug`
3. **Abra um Pull Request** quando terminar — não mergeia por conta própria
4. Aguarda revisão antes de qualquer merge

---

## 🚀 Como Rodar Localmente

1. Instale o [Godot 4](https://godotengine.org/download)
2. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/dungeonmath.git
   ```
3. Abra o Godot, clique em **Import** e selecione a pasta do projeto
4. Rode com **F5** ou pelo botão de play

---

## 📌 Observações

- O desenvolvimento está temporariamente focado na **produção do trailer** do jogo para apresentação da atividade extensionista
- O código ainda está passando por revisão de organização — se algo parecer estranho, provavelmente já é conhecido
- Issues e sugestões são bem-vindos!

---

*Projeto universitário — Centro Universitário Católica de Santa Catarina*