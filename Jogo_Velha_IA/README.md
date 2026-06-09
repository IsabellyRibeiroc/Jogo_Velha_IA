# Jogo da Velha com IA em Assembly

## Grupo e Professor 
Professor: Fernando Ferreira de Carvalho
Alunos: Pedro Gabriel Paes
        Isabelly Ribeiro
        Rubens Sousa
        João Monte


## O que a IA faz

A CPU joga com `O`. Na fase dificil, ela segue esta prioridade:

1. Ganha se houver duas pecas `O` alinhadas e uma casa vazia.
2. Bloqueia o jogador se houver duas pecas `X` alinhadas e uma casa vazia.
3. Joga no centro.
4. Joga nos cantos.
5. Usa as laterais apenas como fallback quando nao houver centro/canto livre.

## Fases

- Fase 1 - Facil: centro, cantos e laterais.
- Fase 2 - Medio: bloqueia o jogador, depois centro, cantos e laterais.
- Fase 3 - Dificil: tenta vencer, bloqueia, joga no centro, depois cantos.

## Arquivos
- `jogo_velha_ia_mars_bitmap.asm`: versao em MIPS Assembly para MARS com interface grafica no Bitmap Display.

## Entrega no MARS
Como executar:

1. Abra o MARS.
2. Clique em `File > Open`.
3. Selecione `jogo_velha_ia_mars_bitmap.asm`.
4. Clique em `Tools > Bitmap Display`.
5. Configure:

```text
Unit Width in Pixels:        16
Unit Height in Pixels:       16
Display Width in Pixels:     512
Display Height in Pixels:    512
Base address for display:    0x10010000 (static data)
```

6. Clique em `Connect to MIPS`.
7. Volte na janela principal do MARS.
8. Clique em `Assemble`.
9. Clique em `Run`.

O tabuleiro e as pecas aparecem no Bitmap Display. As entradas de fase e jogada aparecem em janelas do proprio MARS.

## Ver a interface bonita

Abra o arquivo:

```text
interface/index.html
```

Essa versao visual usa a mesma regra de IA das fases, mas o codigo principal do trabalho em Assembly continua em `jogo_velha_ia.asm`.
```

## Conceitos usados

- Matriz 3x3 representada por vetor linear de 9 posicoes.
- Verificacao de vitoria por loop em uma tabela com as 8 combinacoes vencedoras.
- IA por varredura das linhas, contando pecas e casas vazias.
