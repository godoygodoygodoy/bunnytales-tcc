# Bunny Tales - Requisitos do Jogo

Este documento registra os requisitos funcionais e de arquitetura para o projeto.

## Visao geral

O jogo e um 2D action platformer com progressao por fases, combate, escolhas e multiplos finais.

## 1. Estrutura geral do jogo

O jogo possui:

- Personagem controlavel (coelho)
- Inimigos com IA
- Sistema de habilidades
- Sistema de progressao
- Economia (XP usada como moeda)
- Checkpoints com lojas
- Fases com escolhas
- Multiplos finais

Engine utilizada:

- Godot (GDScript)

## 2. Sistema do Player

O player deve possuir:

- Movimentacao
- Movimento lateral
- Pulo
- Pulo duplo
- Dash com cooldown
- Progressao

Durante as fases o jogador pode:

- Desbloquear novos ataques
- Desbloquear novos movimentos
- Ter sistema de vida
- Ter vida maxima
- Receber dano
- Morrer e fazer respawn em checkpoint

## 3. Sistema de combate

O jogador possui tres tipos de ataques base:

1. Ataque corpo a corpo
- Curto alcance
- Dano rapido
- Cooldown pequeno

2. Projetil
- Longo alcance
- Dano medio
- Cooldown medio

3. Habilidades especiais
- Efeitos unicos
- Dano alto
- Custo ou penalidade

Exemplo de mecanica:

- Perder 10% de vida para ganhar 10% de forca

## 4. Sistema de inimigos

Inimigos possuem:

- Spawn automatico
- Spawn controlado pelo sistema da fase
- Dificuldade baseada na fase atual
- IA basica

Dois comportamentos:

1. Inimigos melee
- Patrulha
- Perseguem player quando proximos
- Dano por contato

2. Inimigos ranged
- Mantem distancia
- Atacam com projetis

## 5. Sistema de XP e economia

Quando inimigos morrem:

- Dropam XP

XP serve para:

- Pontuacao
- Moeda dentro do jogo

XP pode ser usada em lojas nos checkpoints.

## 6. Checkpoints

Checkpoints servem para:

- Respawn
- Acessar loja
- Salvar progresso da fase

## 7. Sistema de fases

O jogo possui 3 fases principais.

Cada fase possui 3 caminhos diferentes.

Total de combinacoes de caminho:

- 3 x 3 x 3 = 27 combinacoes possiveis

## 8. Sistema de finais

Apesar das 27 combinacoes, o jogo possui apenas 3 finais.

O final depende das escolhas feitas nas fases.

A logica de final deve registrar:

- Caminho escolhido em cada fase
- Combinacao final

## 9. Mundo do jogo

O cenario possui:

- Sensacao de mundo continuo
- Geracao dinamica de elementos visuais
- Reposicionamento de chao conforme o player avanca

## 10. Requisitos do codigo

O codigo gerado deve:

- Ser organizado em scripts separados
- Usar boas praticas de GDScript
- Comentar funcoes importantes
- Ser modular

Principais scripts esperados:

- Player.gd
- Enemy.gd
- EnemySpawner.gd
- AbilitySystem.gd
- XPSystem.gd
- Checkpoint.gd
- ShopSystem.gd
- LevelManager.gd
- EndingManager.gd

## 11. Prioridade

Caso o sistema ja exista, adaptar o codigo atual e nao recriar tudo.
