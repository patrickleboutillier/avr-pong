; Write your code in this file

#include <avr/io.h>

#define SPEED_MASK  0b00000011
#define DELAY       50


.section .data


buffer:
  .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ball_x:
  .byte 0
ball_y:
  .byte 0
ball_xdir:
  .byte 0
ball_ydir:
  .byte 0
display_ball:
  .byte 0 
game_over:
  .byte 0
button_up_state:
  .byte 0
button_down_state:
  .byte 0
nbloop:
  .byte 0


.section .text


.global main
main:
  call init_globals
  call setup
1:
  call loop
  rjmp 1b


init_globals:
  ldi r24, 7
  sts ball_x, r24
  ldi r24, 3
  sts ball_y, r24
  ldi r24, 1
  sts ball_xdir, r24
  ldi r24, 1
  sts ball_ydir, r24
  ldi r24, 255
  sts display_ball, r24
  ldi r24, 0
  sts game_over, r24
  ldi r24, 1
  sts button_up_state, r24
  ldi r24, 1
  sts button_down_state, r24
  ldi r24, 0
  sts nbloop, r24
  ret


setup:
  // SPI.begin()
  ldi r24, 0b00000100
  out _SFR_IO_ADDR(PORTB), r24
  ldi r24, 0b01010000
  out _SFR_IO_ADDR(SPCR), r24
  ldi r24, 0b00110100
  out _SFR_IO_ADDR(DDRB), r24
  ; pinMode([67], INPUT_PULLUP)
  ldi r24, 0b00111111
  out _SFR_IO_ADDR(DDRD), r24    ; DDRD (0x0A)
  ldi r24, 0b11000000
  out _SFR_IO_ADDR(PORTD), r24   ; PORTD (0x0B)
  ; buffer[0] = 0b00111100
  ldi r24, 0b00111100
  sts buffer, r24
  ; buffer[15] = 0b00111100
  ldi r24, 0b00111100
  sts buffer+15, r24
  ; buffer[ball_x] = shiftln(1, ball_y) ;
  ldi r24, 1
  lds r22, ball_y
  call shiftln          ; result in r24
  ldi r30, lo8(buffer)  ; load Z = address of my_array
  ldi r31, hi8(buffer)  ; ...high byte also
  lds r22, ball_x
  add r30, r22          ; result in r30 (Z)
  adc r31, r1
  st Z, r24
  ret


; void loop()
loop:
  call erase_ball

  lds r24, game_over
  cpi r24, 0
  breq 1f
    lds r24, display_ball
    com r24
    sts display_ball, r24
    rjmp 3f
1:
    call handle_moves
    cpi r24, 0
    brne 3f
      ldi r24, 1
      sts game_over, r24
      ret
3:  
  call draw_ball
  call refresh

  lds r24, nbloop
  inc r24
  sts nbloop, r24
 
  ldi r24, DELAY
  call delayms
  ret


; void refresh(){
refresh:
  ldi r20, 0 
1:
  cpi r20, 8 
  brge 2f
    // digitalWrite(CS_PIN, 0) ;
    in r24, _SFR_IO_ADDR(PORTB)
    andi r24, 0b11111011
    out _SFR_IO_ADDR(PORTB), r24
    mov r24, r20
    ldi r22, 0
    push r20
    call send_row
    pop r20
    mov r24, r20
    ldi r22, 8
    push r20
    call send_row
    pop r20
    // digitalWrite(CS_PIN, 1) ;
    in r24, _SFR_IO_ADDR(PORTB)
    ori r24, 0b00000100
    out _SFR_IO_ADDR(PORTB), r24
    inc r20 
    rjmp 1b
2:
  ret



; void send_row(byte r24, byte r22)
send_row:
  mov r26, r24
  mov r27, r22
  ldi r18, 0
  ldi r20, 0
1:
  cpi r20, 8 
  brge 2f
    mov r24, r20
    add r24, r27

    ; r22 = buffer[r24] 
    ldi r30, lo8(buffer)  ; load Z = address of my_array
    ldi r31, hi8(buffer)  ; ...high byte also
    add r30, r24          ; result in r30 (Z)
    adc r31, r1
    ld r22, Z

    mov r24, r22
    mov r22, r26
    call shiftrn
    andi r24, 1
    mov r22, r20 
    call shiftln
    or r18, r24 
    inc r20
    rjmp 1b
2:
  mov r24, r26
  inc r24
  call spi_transfer
  mov r24, r18
  call spi_transfer
  ret


; void spi_transfer(byte r24){
spi_transfer:
  out _SFR_IO_ADDR(SPDR), r24
  nop
1:
  in r22, _SFR_IO_ADDR(SPSR)
  andi r22, 0b10000000 ;
  breq 1b
  ret


; byte handle_moves(){
handle_moves:
  call handle_player_move
  lds r18, ball_x 
  lds r20, ball_y 

  lds r26, nbloop 
  andi r26, SPEED_MASK
  ldi r22, 0
  cpi r26, 0
  brne 1f
    ldi r22, 1
1:

  cpi r22, 0
  breq 3f
    push r20
    call handle_ball_x_move
    mov r18, r24
    pop r20
    cpi r18, 255
    brne 2f
      // The game is over.
      ldi r24, 0 
      ret 
2:
    push r18
    call handle_ball_y_move
    mov r20, r24
    pop r18
    mov r24, r18
    mov r22, r20
    push r20
    call handle_paddle_contact
    mov r18, r24
    pop r20
3:
  push r18
  push r20
  mov r24, r20 
  call handle_computer_move
  pop r20
  pop r18

  sts ball_x, r18 
  sts ball_y, r20 

  ldi r24, 1
  ret


; void handle_player_move()
handle_player_move:
  call button_up_pushed
  cpi r24, 0
  breq 1f
    ldi r24, 0 
    call paddle_up
    ret
1:
  call button_down_pushed
  cpi r24, 0
  breq 1f
    ldi r24, 0 
    call paddle_down
2:
  ret


; void handle_computer_move(byte r24)
handle_computer_move:
  lds r22, ball_y 
  ; if (r22 < r24){
  cp r22, r24
  brge 1f
    ldi r24, 15
    call paddle_down
    ret 
1:
  ; if (r24 < r22){
  cp r24, r22
  brge 2f
    ldi r24, 15
    call paddle_up 
2:
  ret


; byte handle_ball_x_move
handle_ball_x_move:
  lds r24, ball_x
  lds r22, ball_xdir
  add r24, r22
  ; Is the new current position valid?
  ; The ball would leave the buffer by the side. The game is over.
  ; if (r24 >= 16){
  cpi r24, 16
  brlo 1f
    ; The ball would leave the buffer by the side. The game is over.
    ldi r24, 255
    ret
1:
  ret


; byte handle_ball_y_move
handle_ball_y_move:
  lds r24, ball_y
  lds r22, ball_ydir
  add r24, r22 
  ; if (r24 >= 8){   // brlt 1f
  cpi r24, 8
  brlo 1f
    ; The ball would leave the buffer by the top. We must reverse direction.
    ; ball_ydir = -ball_ydir ;
    lds r22, ball_ydir
    neg r22
    sts ball_ydir, r22
    ; r24 = ball_y + ball_ydir ;
    lds r24, ball_y
    add r24, r22
1:
  ret


; byte handle_paddle_contact(byte r24, byte r22)
handle_paddle_contact:
  push r24
  push r22
  ; byte r20 = paddle_contact(r24, r22) ;
  call paddle_contact
  mov r20, r24
  pop r22
  pop r24
  ; if (r20 != 0){  // breq 1f
  cpi r20, 0
  breq 1f
    ; The ball would touch the player or computer paddle. We must reverse direction.
    ; ball_xdir = -ball_xdir ;
    lds r22, ball_xdir
    neg r22
    sts ball_xdir, r22
    ; r24 = ball_x + ball_xdir ;
    lds r24, ball_x
    add r24, r22
1:
  ret ;


; byte paddle_contact(byte r24, byte r22)
paddle_contact:
  cpi r24, 0
  brne 1f
    cpi r24, 15
  brne 1f
    ldi r24, 0
    ret
1:
  push r24
  push r22
  ldi r24, 1
  call shiftln
  mov r20, r24
  pop r22
  pop r24
  ldi r30, lo8(buffer)  ; load Z = address of my_array
  ldi r31, hi8(buffer)  ; ...high byte also
  add r30, r24          ; result in r30 (Z)
  adc r31, r1
  ld r18, Z
  and r18, r20
  breq 2f
    ldi r24, 1
    ret
2:
  ldi r24, 0
  ret


; byte button_up_pushed()
button_up_pushed:
  ; if (digitalRead(7) == 0){
  in r24, 0x09           ; PIND
  andi r24, 0b10000000   ; eq if pin is off
  brne 2f
    ldi r24, 0
    sts button_up_state, r24
    ret
2:
  ; if (button_up_state == 0){
  lds r24, button_up_state
  and r24, r24
  brne 1f             ; eq if button_up_state == 0
    ldi r24, 1
    sts button_up_state, r24
    ret
1:
  ldi r24, 0
  ret


; byte button_down_pushed()
; ret: r24
button_down_pushed:
  ; if (digitalRead(6) == 0){
  in r24, 0x09           ; PIND
  andi r24, 0b01000000   ; eq if pin is off
  brne 2f
    ldi r24, 0
    sts button_down_state, r24
    ret
2:
  ; if (button_down_state == 0){
  lds r24, button_down_state
  and r24, r24
  brne 1f             ; eq if button_down_state == 0
    ldi r24, 1
    sts button_down_state, r24
    ret
1:
  ldi r24, 0
  ret


; void paddle_up(byte x)
; x: r24
paddle_up:
  ldi r30, lo8(buffer)  ; load Z = address of buffer
  ldi r31, hi8(buffer)  ; ...high byte also
  add r30, r24          ; result in r30 (Z)
  adc r31, r1 
  ld r22, Z             ; buffer[x] is in r22
  ldi r20, 0b00001111
  cp r20, r22
  brsh 1f
  lsr r22
  st Z, r22
1:
  ret


; void paddle_down(byte x)
; x: r24
paddle_down:
  ldi r30, lo8(buffer)  ; load Z = address of buffer
  ldi r31, hi8(buffer)  ; ...high byte also
  add r30, r24          ; result in r30 (Z)
  adc r31, r1 
  ld r22, Z             ; buffer[x] is in r22
  ldi r20, 0b11110000
  cp r22, r20
  brsh 1f
  lsl r22
  st Z, r22
1:
  ret


; void erase_ball()
erase_ball:
  ldi r24, 1
  lds r22, ball_y
  call shiftln          ; result in r24
  com r24
  clr 31
  ldi r30, lo8(buffer)  ; load Z = address of my_array
  ldi r31, hi8(buffer)  ; ...high byte also
  lds r22, ball_x
  add r30, r22          ; result in r30 (Z)
  adc r31, r1 
  ld r22, Z 
  and r22, r24
  st Z, r22
  ret


; void draw_ball()
draw_ball:
  lds r24, display_ball
  tst r24
  breq 1f
    ldi r24, 1
    lds r22, ball_y
    call shiftln          ; result in r24
    clr 31
    ldi r30, lo8(buffer)  ; load Z = address of my_array
    ldi r31, hi8(buffer)  ; ...high byte also
    lds r22, ball_x
    add r30, r22          ; result in r30 (Z)
    adc r31, r1 
    ld r22, Z
    or r22, r24
    st Z, r22
1:
  ret


; byte shiftln(byte v, byte n)
; v: r24, n: r22, ret: r24 
shiftln:
  and r22, r22
  breq 1f
    lsl r24
    subi r22, 1
    rjmp shiftln
1:
  ret


; byte shiftrn(byte v, byte n)
; v: r24, n: r22, ret: r24
shiftrn:
  and r22, r22
  breq 1f
    lsr r24
    subi r22, 1
    rjmp shiftrn
1:
  ret


delay1ms:
  ldi r30, lo8(4000)
  ldi r31, hi8(4000)
1:
  sbiw r30, 1
  brne 1b
  ret


  .global delayms
delayms:
  call delay1ms
  sbiw r24, 1
  brne delayms
  ret
