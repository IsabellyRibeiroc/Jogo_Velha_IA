# Jogo da Velha com IA - MIPS Assembly para MARS
# Interface grafica usando Tools > Bitmap Display.
#
# Configure o Bitmap Display assim:
#   Unit Width in Pixels:        16
#   Unit Height in Pixels:       16
#   Display Width in Pixels:     512
#   Display Height in Pixels:    512
#   Base address for display:    0x10010000 (static data)
#
# Depois clique em "Connect to MIPS".
#
# A entrada das jogadas usa dialogs do MARS, mas o tabuleiro e as pecas
# sao desenhados graficamente no Bitmap Display.

.eqv DISPLAY_W    64
.eqv EMPTY        32
.eqv HUMAN        88
.eqv CPU          79

.data
frameBuffer: .space 16384       # 32 * 32 palavras, usado pelo Bitmap Display
board:       .byte 32,32,32,32,32,32,32,32,32
difficulty:  .word 3

lines:       .byte 0,1,2, 3,4,5, 6,7,8, 0,3,6, 1,4,7, 2,5,8, 0,4,8, 2,4,6
corners:     .byte 0,2,6,8
sides:       .byte 1,3,5,7

msgStart:    .asciiz "Abra Tools > Bitmap Display e configure:\n\nUnit Width: 16\nUnit Height: 16\nDisplay Width: 512\nDisplay Height: 512\nBase address: 0x10010000 (static data)\n\nClique em Connect to MIPS e depois OK."
msgLevels:   .asciiz "Escolha a fase:\n\n1 - Facil\n2 - Medio\n3 - Dificil\n\nDigite 1, 2 ou 3:"
msgBadLevel: .asciiz "Fase invalida. Escolha 1, 2 ou 3."
msgMove:     .asciiz "Escolha uma posicao de 1 a 9 olhando o Bitmap Display:\n\n1 | 2 | 3\n4 | 5 | 6\n7 | 8 | 9"
msgBadMove:  .asciiz "Jogada invalida. Escolha uma casa livre entre 1 e 9."
msgHumanWin: .asciiz "Voce venceu!"
msgCpuWin:   .asciiz "CPU venceu!"
msgDraw:     .asciiz "Empate!"
msgAgain:    .asciiz "Jogar novamente?"
msgBye:      .asciiz "Fim de jogo."

.text
.globl main

main:
    li $v0, 55
    la $a0, msgStart
    li $a1, 1
    syscall

start_game:
    jal clear_board
    jal choose_difficulty
    jal draw_screen

game_loop:
ask_human_move:
    li $v0, 51                 # InputDialogInt
    la $a0, msgMove
    syscall

    move $t0, $a0              # valor digitado
    move $t1, $a1              # status do dialog
    bne $t1, $zero, invalid_move
    blt $t0, 1, invalid_move
    bgt $t0, 9, invalid_move

    addiu $t0, $t0, -1
    la $t2, board
    addu $t2, $t2, $t0
    lb $t3, 0($t2)
    li $t4, EMPTY
    bne $t3, $t4, invalid_move

    li $t5, HUMAN
    sb $t5, 0($t2)
    jal draw_screen

    li $a0, HUMAN
    jal check_winner
    beq $v0, 1, human_won

    jal is_draw
    beq $v0, 1, draw_game

    jal cpu_turn
    jal draw_screen

    li $a0, CPU
    jal check_winner
    beq $v0, 1, cpu_won

    jal is_draw
    beq $v0, 1, draw_game

    j game_loop

invalid_move:
    li $v0, 55
    la $a0, msgBadMove
    li $a1, 2
    syscall
    j game_loop

human_won:
    li $v0, 55
    la $a0, msgHumanWin
    li $a1, 1
    syscall
    j ask_again

cpu_won:
    li $v0, 55
    la $a0, msgCpuWin
    li $a1, 1
    syscall
    j ask_again

draw_game:
    li $v0, 55
    la $a0, msgDraw
    li $a1, 1
    syscall

ask_again:
    li $v0, 50                 # ConfirmDialog: sim=0, nao=1, cancelar=2
    la $a0, msgAgain
    syscall
    beq $a0, $zero, start_game

    li $v0, 55
    la $a0, msgBye
    li $a1, 1
    syscall

    li $v0, 10
    syscall

choose_difficulty:
choose_loop:
    li $v0, 51
    la $a0, msgLevels
    syscall

    move $t0, $a0
    move $t1, $a1
    bne $t1, $zero, bad_level
    blt $t0, 1, bad_level
    bgt $t0, 3, bad_level

    sw $t0, difficulty
    jr $ra

bad_level:
    li $v0, 55
    la $a0, msgBadLevel
    li $a1, 2
    syscall
    j choose_loop

clear_board:
    la $t0, board
    li $t1, 9
    li $t2, EMPTY
clear_board_loop:
    sb $t2, 0($t0)
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    bgtz $t1, clear_board_loop
    jr $ra

draw_screen:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    jal clear_bitmap
    jal draw_header
    jal draw_grid
    jal draw_all_marks

    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

clear_bitmap:
    la $t0, frameBuffer
    li $t1, 1024               
    li $t2, 0x00121418         
clear_bitmap_loop:
    sw $t2, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    bgtz $t1, clear_bitmap_loop
    jr $ra

draw_header:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, difficulty
    li $s7, 0x00000ff00         # facil: verde
    beq $t0, 1, header_color_ready
    li $s7, 0x00c8a2c8         # medio: lilas
    beq $t0, 2, header_color_ready
    li $s7, 0x00880808         # dificil: vermelho sangue

header_color_ready:
    li $a0, 0
    li $a1, 0
    li $a2, 32
    li $a3, 4
    jal draw_rect

    # Marcadores das fases no topo.
    li $s7, 0x00252932
    li $a0, 8
    li $a1, 1
    li $a2, 3
    li $a3, 2
    jal draw_rect
    li $a0, 15
    li $a1, 1
    li $a2, 3
    li $a3, 2
    jal draw_rect
    li $a0, 22
    li $a1, 1
    li $a2, 3
    li $a3, 2
    jal draw_rect

    lw $t0, difficulty
    li $s7, 0x00ffffff
    beq $t0, 1, active_one
    beq $t0, 2, active_two
    li $a0, 22
    j draw_active
active_one:
    li $a0, 8
    j draw_active
active_two:
    li $a0, 15
draw_active:
    li $a1, 1
    li $a2, 3
    li $a3, 2
    jal draw_rect

    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

draw_grid:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # Area do tabuleiro.
    li $s7, 0x00f4f0e8
    li $a0, 3
    li $a1, 5
    li $a2, 26
    li $a3, 26
    jal draw_rect

    # Linhas verticais e horizontais.
    li $s7, 0x00252932
    li $a0, 12
    li $a1, 6
    li $a2, 1
    li $a3, 24
    jal draw_rect

    li $a0, 20
    li $a1, 6
    li $a2, 1
    li $a3, 24
    jal draw_rect

    li $a0, 4
    li $a1, 14
    li $a2, 24
    li $a3, 1
    jal draw_rect

    li $a0, 4
    li $a1, 22
    li $a2, 24
    li $a3, 1
    jal draw_rect

    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

# Entrada: $a0=x, $a1=y, $a2=largura, $a3=altura, $s7=cor.
draw_rect:
    move $t0, $a1              # y atual
    addu $t1, $a1, $a3         # y final
    addu $t2, $a0, $a2         # x final
draw_rect_y:
    move $t3, $a0              # x atual
draw_rect_x:
    sll $t4, $t0, 5            # y * 32
    addu $t4, $t4, $t3
    sll $t4, $t4, 2
    la $t5, frameBuffer
    addu $t5, $t5, $t4
    sw $s7, 0($t5)

    addiu $t3, $t3, 1
    blt $t3, $t2, draw_rect_x

    addiu $t0, $t0, 1
    blt $t0, $t1, draw_rect_y
    jr $ra

# Entrada: $a0=x, $a1=y, $a2=cor.
put_pixel:
    blt $a0, $zero, put_pixel_done
    blt $a1, $zero, put_pixel_done
    bge $a0, 32, put_pixel_done
    bge $a1, 32, put_pixel_done

    sll $t0, $a1, 5
    addu $t0, $t0, $a0
    sll $t0, $t0, 2
    la $t1, frameBuffer
    addu $t1, $t1, $t0
    sw $a2, 0($t1)
put_pixel_done:
    jr $ra

draw_all_marks:
    addiu $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    li $s0, 0
draw_marks_loop:
    la $t0, board
    addu $t0, $t0, $s0
    lb $t1, 0($t0)

    li $t2, HUMAN
    beq $t1, $t2, draw_this_x

    li $t2, CPU
    beq $t1, $t2, draw_this_o
    j next_mark

draw_this_x:
    move $a0, $s0
    jal draw_x_at_index
    j next_mark

draw_this_o:
    move $a0, $s0
    jal draw_o_at_index

next_mark:
    addiu $s0, $s0, 1
    blt $s0, 9, draw_marks_loop

    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addiu $sp, $sp, 8
    jr $ra

# Entrada: $a0 = indice 0..8
# Saida: $v0=x base, $v1=y base.
cell_base:
    li $t0, 3
    div $a0, $t0
    mflo $t1                    # linha
    mfhi $t2                    # coluna

    sll $t3, $t2, 3             # coluna * 8
    addiu $v0, $t3, 4
    sll $t4, $t1, 3             # linha * 8
    addiu $v1, $t4, 6
    jr $ra

draw_x_at_index:
    addiu $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)

    jal cell_base
    move $s0, $v0
    move $s1, $v1
    li $s2, 1
    li $s3, 0x00e34d3f

draw_x_loop:
    addu $a0, $s0, $s2
    addu $a1, $s1, $s2
    move $a2, $s3
    jal put_pixel

    addiu $t0, $s2, 1
    addu $a0, $s0, $s2
    addu $a1, $s1, $t0
    move $a2, $s3
    jal put_pixel

    li $t1, 7
    subu $t1, $t1, $s2
    addu $a0, $s0, $t1
    addu $a1, $s1, $s2
    move $a2, $s3
    jal put_pixel

    addiu $t0, $s2, 1
    addu $a0, $s0, $t1
    addu $a1, $s1, $t0
    move $a2, $s3
    jal put_pixel

    addiu $s2, $s2, 1
    ble $s2, 6, draw_x_loop

    lw $s3, 16($sp)
    lw $s2, 12($sp)
    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addiu $sp, $sp, 20
    jr $ra

draw_o_at_index:
    addiu $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)

    jal cell_base
    move $s0, $v0
    move $s1, $v1
    li $s7, 0x000f9c8e

    addiu $a0, $s0, 2
    addiu $a1, $s1, 1
    li $a2, 4
    li $a3, 1
    jal draw_rect

    addiu $a0, $s0, 2
    addiu $a1, $s1, 6
    li $a2, 4
    li $a3, 1
    jal draw_rect

    addiu $a0, $s0, 1
    addiu $a1, $s1, 2
    li $a2, 1
    li $a3, 4
    jal draw_rect

    addiu $a0, $s0, 6
    addiu $a1, $s1, 2
    li $a2, 1
    li $a3, 4
    jal draw_rect

    lw $s1, 8($sp)
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addiu $sp, $sp, 12
    jr $ra

# =========================
# IA E REGRAS DO JOGO
# =========================

cpu_turn:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, difficulty
    beq $t0, 1, cpu_easy
    beq $t0, 2, cpu_medium

cpu_hard:
    li $a0, CPU
    jal find_best_line
    li $t9, -1
    bne $v0, $t9, cpu_play

    li $a0, HUMAN
    jal find_best_line
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_center
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_corner
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_side
    j cpu_play

cpu_medium:
    li $a0, HUMAN
    jal find_best_line
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_center
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_corner
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_side
    j cpu_play

cpu_easy:
    jal find_center
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_corner
    li $t9, -1
    bne $v0, $t9, cpu_play

    jal find_side

cpu_play:
    blt $v0, $zero, cpu_done
    la $t1, board
    addu $t1, $t1, $v0
    li $t2, CPU
    sb $t2, 0($t1)
cpu_done:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra

find_center:
    la $t0, board
    lb $t1, 4($t0)
    li $t2, EMPTY
    bne $t1, $t2, no_center
    li $v0, 4
    jr $ra
no_center:
    li $v0, -1
    jr $ra

# Entrada: $a0 = marca procurada
# Saida: $v0 = casa vazia para completar/bloquear, ou -1.
find_best_line:
    la $t0, lines
    li $t1, 8

scan_line:
    li $t2, 0                  # quantidade da marca
    li $t3, 0                  # quantidade de vazias
    li $t4, -1                 # indice vazio
    li $t5, 3

scan_cell:
    lb $t6, 0($t0)
    addiu $t0, $t0, 1

    la $t7, board
    addu $t7, $t7, $t6
    lb $t8, 0($t7)

    beq $t8, $a0, count_mark
    li $t9, EMPTY
    beq $t8, $t9, count_empty
    j after_count

count_mark:
    addiu $t2, $t2, 1
    j after_count

count_empty:
    addiu $t3, $t3, 1
    move $t4, $t6

after_count:
    addiu $t5, $t5, -1
    bgtz $t5, scan_cell

    bne $t2, 2, next_line
    bne $t3, 1, next_line
    move $v0, $t4
    jr $ra

next_line:
    addiu $t1, $t1, -1
    bgtz $t1, scan_line
    li $v0, -1
    jr $ra

find_corner:
    la $t0, corners
    li $t1, 4
    j find_from_list

find_side:
    la $t0, sides
    li $t1, 4

find_from_list:
    lb $t2, 0($t0)
    la $t3, board
    addu $t3, $t3, $t2
    lb $t4, 0($t3)
    li $t5, EMPTY
    beq $t4, $t5, found_from_list
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    bgtz $t1, find_from_list
    li $v0, -1
    jr $ra

found_from_list:
    move $v0, $t2
    jr $ra

# Entrada: $a0 = marca
# Saida: $v0 = 1 se venceu, 0 caso contrario.
check_winner:
    la $t0, lines
    li $t1, 8

winner_loop:
    lb $t2, 0($t0)
    lb $t3, 1($t0)
    lb $t4, 2($t0)

    la $t5, board
    addu $t6, $t5, $t2
    lb $t6, 0($t6)
    bne $t6, $a0, not_this_line

    addu $t7, $t5, $t3
    lb $t7, 0($t7)
    bne $t7, $a0, not_this_line

    addu $t8, $t5, $t4
    lb $t8, 0($t8)
    bne $t8, $a0, not_this_line

    li $v0, 1
    jr $ra

not_this_line:
    addiu $t0, $t0, 3
    addiu $t1, $t1, -1
    bgtz $t1, winner_loop

    li $v0, 0
    jr $ra

# Saida: $v0 = 1 se empatou, 0 se ainda existe casa vazia.
is_draw:
    la $t0, board
    li $t1, 9
    li $t2, EMPTY

draw_loop:
    lb $t3, 0($t0)
    beq $t3, $t2, draw_false
    addiu $t0, $t0, 1
    addiu $t1, $t1, -1
    bgtz $t1, draw_loop

    li $v0, 1
    jr $ra

draw_false:
    li $v0, 0
    jr $ra
