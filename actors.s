level_enemies .byte 55, 4, 5, 6, 7, 8 ;# level starts counting from 1, so dummy zeroth level info
level_speed_l .byte 255, 200, 210, 220, 230, 240 ;# increment of fractional pixel per game frame
level_speed_h .byte 2, 2, 2, 2, 2, 2 ; increment of whole pixels

player_score_row .byte 2, 7, 12, 17
player_lives_row .byte 3, 8, 13, 18
player_score_l .byte 0, 0, 0, 0
player_score_m .byte 0, 0, 0, 0
player_score_h .byte 0, 0, 0, 0


PLAYER_TYPE = 0
ORBITER_TYPE = 1
AMIDAR_TYPE = 2
actor_type .byte PLAYER_TYPE, PLAYER_TYPE, PLAYER_TYPE, PLAYER_TYPE
    .byte ORBITER_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE
    .byte AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE
    .byte AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE
actor_init_func_l .byte <init_player, <init_orbiter, <init_amidar
actor_init_func_h .byte >init_player, >init_orbiter, >init_amidar

; Sprite data is interleaved so a simple indexed mode can be used. This is not
; convenient to set up but makes faster accessing because you don't have to 
; increment the index register. For example, all the info about sprite #2 can
; be indexed using Y = 2 on the indexed operators, e.g. "lda sprite_active,y",
; "lda sprite_x,y", etc.
;
; Number of sprites must be a power of 2

source_actor_active .byte 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0 , $ff ; 1 = active, 0 = skip

source_actor_l
    .byte <APPLE_SPRITE9X11
    .byte <APPLE_SPRITE9X11
    .byte <APPLE_SPRITE9X11
    .byte <APPLE_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11
    .byte <ATARI_SPRITE9X11

source_actor_h
    .byte >APPLE_SPRITE9X11
    .byte >APPLE_SPRITE9X11
    .byte >APPLE_SPRITE9X11
    .byte >APPLE_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11
    .byte >ATARI_SPRITE9X11

source_actor_x
    .byte 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0 , $ff

source_actor_y
    .byte 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0 , $ff

source_end .byte $ff

;
;# Scores
;
DOT_SCORE = $01
box_score .byte 0, $20, $40, $60, $80, $100, $120

add_score nop
    sed
    clc
    adc player_score_l,x
    sta player_score_l,x
    lda player_score_m,x
    adc #0
    sta player_score_m,x
    lda player_score_h,x
    adc #0
    sta player_score_h,x
    cld

    jsr update_score

    rts


init_actors_once nop
    ldx #0
?1  lda source_actor_active,x
    sta actor_active,x
    inx
    cpx #source_end-source_actor_active
    bcc ?1
    rts

init_players nop
    sta config_num_players


; 
init_level nop
    ldx level
    lda level_enemies,x
    tay
    lda #$ff
    sta actor_active+FIRST_AMIDAR,y
    lda #1
?1  sta actor_active+FIRST_AMIDAR-1,y
    dey
    bne ?1

    ; clear active players
    ldy #0
    lda #1
?2  cpy config_num_players
    bcs ?3
    sta actor_active,y
    iny
    bne ?2
?3  lda #0
    cpy #MAX_PLAYERS
    bcs ?4
    sta actor_active,y
    iny
    bne ?3
?4  rts


;
;##### Gameplay initialization
;
;def init_actor():
;    # Common initialization params for all actors
;    actor_col[zp.current_actor] = MAZE_LEFT_COL
;    actor_xpixel[zp.current_actor] = 3
;    actor_xfrac[zp.current_actor] = 0
;    actor_xspeed[zp.current_actor] = 0
;    actor_row[zp.current_actor] = MAZE_BOT_ROW
;    actor_ypixel[zp.current_actor] = 3
;    actor_yfrac[zp.current_actor] = 0
;    actor_yspeed[zp.current_actor] = 0
;    actor_input_dir[zp.current_actor] = 0
;    actor_updown[zp.current_actor] = TILE_UP
;    actor_dir[zp.current_actor] = TILE_UP
;    actor_status[zp.current_actor] = NOT_VISIBLE
;    actor_frame_counter[zp.current_actor] = 0
;    actor_target_col[zp.current_actor] = 0
;    actor_input_dir[zp.current_actor] = 0

; actor in X
init_common nop
    lda #MAZE_LEFT_COL
    sta actor_col,x
    lda #3
    sta actor_xpixel,x
    sta actor_ypixel,x
    lda #0
    sta actor_xfrac,x
    sta actor_xspeed_l,x
    sta actor_xspeed_h,x
    sta actor_yfrac,x
    sta actor_yspeed_l,x
    sta actor_yspeed_h,x
    sta actor_input_dir,x
    sta actor_turn_zone,x
    lda #MAZE_BOT_ROW
    sta actor_row,x
    lda #TILE_UP
    sta actor_updown,x
    sta actor_dir,x
    rts

init_actor nop
    jsr init_common
    lda #0
    sta actor_frame_counter,x
    sta actor_target_col,x
    lda #NOT_VISIBLE
    sta actor_status,x
    lda #1
    sta actor_active,x
    rts


;def init_orbiter():
;    init_actor()
;    actor_col[zp.current_actor] = ORBITER_START_COL
;    actor_row[zp.current_actor] = ORBITER_START_ROW
;    actor_dir[zp.current_actor] = TILE_UP
;    actor_status[zp.current_actor] = ORBITER_NORMAL
;    set_speed(TILE_UP)

; actor in X
init_orbiter nop
    jsr init_actor
    lda #ORBITER_START_COL
    sta actor_col,x
    lda #ORBITER_START_ROW
    sta actor_row,x
    lda #TILE_UP
    sta actor_updown,x
    sta actor_dir,x
    jsr set_speed
    lda #ORBITER_NORMAL
    sta actor_status,x
    rts



;def init_amidar():
;    init_actor()
;    amidar_index = zp.current_actor - FIRST_AMIDAR - 1  # orbiter always 1st enemy
;    actor_col[zp.current_actor] = amidar_start_col[amidar_index]
;    actor_row[zp.current_actor] = MAZE_TOP_ROW
;    actor_ypixel[zp.current_actor] = 4
;    actor_updown[zp.current_actor] = TILE_DOWN
;    actor_dir[zp.current_actor] = TILE_DOWN
;    actor_status[zp.current_actor] = AMIDAR_NORMAL
;    set_speed(TILE_DOWN)

; actor in X
init_amidar nop
    jsr init_actor
    txa
    sec
    sbc #FIRST_AMIDAR
    sbc #1
    tay
    lda amidar_start_col,y
    sta actor_col,x
    lda #MAZE_TOP_ROW
    sta actor_row,x
    lda #4
    sta actor_ypixel,x
    lda #TILE_DOWN
    sta actor_updown,x
    sta actor_dir,x
    jsr set_speed
    lda #AMIDAR_NORMAL
    sta actor_status,x
    rts


;def init_player():
;    init_actor()
;    addr = player_start_col[zp.num_players]
;    actor_col[zp.current_actor] = addr[zp.current_actor]
;    actor_row[zp.current_actor] = MAZE_BOT_ROW
;    actor_status[zp.current_actor] = PLAYER_ALIVE
init_player_common 
    lda config_num_players  ; 4 players max, 
    asl a
    asl a
    clc
    adc current_actor
    tay
    ;lda player_start_col,y
    lda #16
    sta actor_col,x
    lda #MAZE_BOT_ROW
    sta actor_row,x
    rts

init_player nop
    jsr init_actor
    jsr init_player_common
    lda #PLAYER_ALIVE
    sta actor_status,x
;                player_lives[zp.current_actor] = STARTING_LIVES
;                player_next_target_score[zp.current_actor] = BONUS_LIFE
    lda #STARTING_LIVES
    sta player_lives,x
    lda #BONUS_LIFE
    sta player_next_target_score,x
    lda #$99
    sta player_score_l
    sta player_score_m
    sta player_score_h
    rts

next_life jsr clear_input
    jsr init_common
    jsr init_player_common
    rts

;def init_actors():
init_actors nop
;    get_col_randomizer(amidar_start_col)
    lda #<amidar_start_col
    sta scratch_addr
    lda #>amidar_start_col
    sta scratch_addr+1
    jsr get_col_randomizer
;    get_col_randomizer(round_robin_up)
    lda #<round_robin_up
    sta scratch_addr
    lda #>round_robin_up
    sta scratch_addr+1
    jsr get_col_randomizer
;    get_col_randomizer(round_robin_down)
    lda #<round_robin_down
    sta scratch_addr
    lda #>round_robin_down
    sta scratch_addr+1
    jsr get_col_randomizer

    lda #0
    sta round_robin_index
    sta round_robin_index+1

;    zp.current_actor = 0
;    while zp.current_actor <= zp.last_enemy:
;        if zp.current_actor <= LAST_PLAYER:
;            if zp.current_actor < zp.num_players:
;                init_player()
;                player_lives[zp.current_actor] = STARTING_LIVES
;                player_next_target_score[zp.current_actor] = BONUS_LIFE
;        else:
;            if zp.current_actor == FIRST_AMIDAR:
;                init_orbiter()
;            else:
;                init_amidar()
;        zp.current_actor += 1
;    zp.round_robin_index[:] = [0, 0]
    lda #$ff
    sta current_actor
init_actors_loop  inc current_actor
    ldx current_actor
    lda actor_active,x
    bpl ?2 ; negative = end
    rts
?2  beq init_actors_loop ; zero = skip
    lda actor_type,x
    tay
    lda actor_init_func_l,y
    sta init_actors_smc+1
    lda actor_init_func_h,y
    sta init_actors_smc+2
init_actors_smc jsr $ffff
    jmp init_actors_loop
