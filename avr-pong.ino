/*


// Not sure why this is required...
// volatile uint8_t xxx = 15 ;


void setup(){
  Serial.begin(9600) ;
  _setup() ;
}


void loop(){
  _loop() ;

  // delayms(50) ;
}


void refresh(){
  byte r24, r22 ;
  byte r20 = 0 ;
loop:
  if (r20 < 8){
    // digitalWrite(CS_PIN, 0) ;
    r24 = PORTB ;
    r24 = r24 & 0b11111011 ;
    PORTB = r24 ;
    r24 = r20 ;
    r22 = 0 ;
    send_row(r24, r22) ;
    r24 = r20 ;
    r22 = 8 ;
    send_row(r24, r22) ;
    digitalWrite(CS_PIN, 1) ;
    r24 = PORTB ;
    r24 = r24 | 0b00000100 ;
    PORTB = r24 ;
    r20 = r20 + 1 ;
    goto loop ;
  }
}


void send_row(byte r24, byte r22){
  byte r26 = r24 ;
  byte r27 = r22 ;
  byte r18 = 0 ;
  byte r20 = 0 ;
loop:
  if (r20 < 8){
    r24 = r20 + r27 ;
    r22 = buffer[r24] ;
    r24 = r22 ;
    r22 = r26 ;
    r24 = shiftrn(r24, r22) ;
    r24 = r24 & 1 ;
    r22 = r20 ;
    r24 = shiftln(r24, r22) ;
    r18 = r18 | r24 ;
    r20 = r20 + 1 ;
    goto loop ;
  }
  r24 = r26 ;
  r24 = r24 + 1 ;
  spi_transfer(r24) ;
  r24 = r18 ;
  spi_transfer(r24) ;
}


void _loop(){
  // Erase the old ball
  erase_ball() ;

  if (game_over){
    display_ball = ~display_ball ;
  }
  else {
    byte r24 = handle_moves() ;
    if (! r24){
      game_over = 1 ;
      return ;
    }
  }
  
  // Draw ball
  draw_ball() ;

  refresh() ;

  nbloop++ ;
}


byte handle_moves(){
  // Player move
  handle_player_move() ; 

  byte r18 = ball_x ;
  byte r20 = ball_y ;

  byte r26 = nbloop ;
  r26 = r26 & SPEED_X_MASK ;
  byte r22 = 0 ;
  if (r26 == 0)
    r22 = 1 ;

  // cp r22, 0
  // breq 1f
  byte r24 ;
  if (r22){
    r18 = handle_ball_x_move() ;
    if (r18 == 255){
      // The game is over.
      r24 = 0 ;
      return r24 ;
    }
    r20 = handle_ball_y_move() ;
    r24 = r18 ;
    r22 = r20 ;
    r18 = handle_paddle_contact(r18, r20) ;
  }

l3:
  r24 = r20 ;
  handle_computer_move(r20) ;

  ball_x = r18 ;
  ball_y = r20 ;

  r24 = 1 ;
  return r24 ;
}


void handle_player_move(){
    if (button_up_pushed()){
      paddle_up(0) ;
      return ;
    } 
    if (button_down_pushed()){
      paddle_down(0) ;
      return ;
    }
}


void handle_computer_move(byte r24){
    // Computer move
    byte r22 = ball_y ; 
    if (r22 < r24){
      r24 = 15 ;
      paddle_down(15) ;
      return ;
    }
    if (r24 < r22){
      r24 = 15 ;
      paddle_up(15) ;
      return ;
    }
}


byte handle_ball_x_move(){
    byte r24 = ball_x ;
    byte r22 =  ball_xdir ;
    r24 = r24 + r22 ;
    // The ball would leave the buffer by the side. The game is over.
    if (r24 >= 16){
      // cpi r24, 16
      // brlo 1f
      // Is the new current position valid?

      // The ball would leave the buffer by the side. The game is over.
      r24 = 255 ;
      return r24 ;
    }
1:
    return r24 ;
}


byte handle_ball_y_move(){
  byte r24 = ball_y ;
  byte r22 = ball_ydir ;
  r24 = r24 + r22 ;
  if (r24 > 7){
    // The ball would leave the buffer by the top. We must reverse direction.
    ball_ydir = -ball_ydir ;
    r24 = ball_y + ball_ydir ;
  }

  return r24 ;
}


/*
byte handle_ball_y_move(){
  byte r24 = ball_y ;
  byte r22 = ball_ydir ;
  r24 = r24 + r22 ;
  // cpi r24, 8
  if (r24 >= 8){   // brlt 1f
    // The ball would leave the buffer by the top. We must reverse direction.
    ball_ydir = -ball_ydir ;
    // lds r22, ball_ydir
    // neg r22
    // sts ball_ydir, r22
    r24 = ball_y + ball_ydir ;
    // lds r24, ball_y
    // add r24, r22
  }
x:
  return r24 ;
}
*/


/*
byte handle_paddle_contact(byte r24, byte r22){
  //push r24
  //push r22
  byte r20 = paddle_contact(r24, r22) ;
  //pop r22
  //pop r24
  //cpi r20, 0
  //breq
  if (r20 != 0){  // breq 1f
    // The ball would touch the player or computer paddle. We must reverse direction.
    // lds r22, ball_dir
    // neg r22
    // sds ball_dir, r22
    ball_xdir = -ball_xdir ;
    // lds r20, ball_x
    // add r22, r20
    // mov r24, r20
    r24 = ball_x + ball_xdir ;
  }

// 1:
  return r24 ;
}


byte paddle_contact(byte r24, byte r22){
  if (r24 == 0) // brne l1
    goto l1 ;
  if (r24 == 15) // brne l1
    goto l1 ;
  r24 = 0 ;
  return r24 ;
l1:
  byte r20 = shiftln(1, r22) ;
  byte r18 = buffer[r24] ;
  r18 = r18 & r20 ;
  if (r18){     // breq ret:
    r24 = 1 ;
    return r24 ;
  }
  r24 = 0 ;
  return r24 ;
}


void spi_transfer(byte r24){
    SPDR = r24 ;
    asm volatile("nop");
spi_loop:
    byte reg22 = SPSR & 0b10000000 ;
    if (! reg22) goto spi_loop ;    // breq spi_loop
}


byte button_up_pushed(){
  if (digitalRead(7) == 0){
    button_up_state = 0 ;
    return 0 ;
  }
  if (button_up_state == 0){
    button_up_state = 1 ;
    return 1 ;
  }  

  return 0 ;
}


byte button_down_pushed(){
  if (digitalRead(6) == 0){
    button_down_state = 0 ;
  }
  else if (button_down_state == 0){    
    button_down_state = 1 ;
    return 1 ;
  }

  return 0 ;
}


void paddle_up(byte x){
  if (buffer[x] > 0b00001111){
    buffer[x] >>= 1 ;  
  }
}


void paddle_down(byte x){
  if (buffer[x] < 0b11110000){
    buffer[x] <<= 1 ;
  }
}


void erase_ball(){
  buffer[ball_x] &= ~shiftln(1, ball_y) ;
}


void draw_ball(){
  if (display_ball != 0){
    buffer[ball_x] |= shiftln(1, ball_y) ;
  }
}


byte shiftln(byte v, byte n){
  while (n > 0){
    v <<= 1 ;
    n-- ;  
  }  

  return v ;
}


byte shiftrn(byte v, byte n){
  while (n > 0){
    v >>= 1 ;
    n-- ;
  }

  return v ;
}
*/
