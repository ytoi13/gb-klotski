;Team: Milk Drogan
;Developers:
; Mingsong Liu(999019821)
; Nuo Chen(999019532)
; Zican Lin(999022056)
; Shang Wang(999019987)


; Random Walk example
; with input (A button resets the state)
; and background (just shows a border)

INCLUDE "hardware.inc"
INCLUDE "data.inc"
DEF OBJCOUNT EQU 2


SECTION "Header", ROM0[$100]
  jp EntryPoint

  ds $150 - @, 0

EntryPoint:
  call WaitVBlank
  ld a, 0
  ld [rLCDC], a

  ;ld a,%11111100 ; black and white palette
  ld a,%11100100 ;4color
  ld [rOBP0], a
  ld [rBGP],  a

  call   CopyTileDataToVRAM
  call   CopyTitleBGToVRAM
  ld     hl, _OAMRAM
  call   ResetOAM
  ld     hl, ShadowOAM
  call   ResetOAM

  call   InitializeObjects  ;print the objects to the screen

  ld a,0;new,init fsmState,0is normal,1 is select
  ld [fsmState],a
  ld [counter],a
  ld [buffer],a
  ld [buffer+1],a
  ld [buffer+2],a
  ld [gamestate],a
  ld [current],a
; LCD on, enable object layer (no background)
  ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_BGON | LCDCF_BG8000
  ld [rLCDC], a



;初始化变量
  ld a,1;初始化为1,
  ld [gotostate],a;gai
  ld [positionincaocao],a
  ld [positioninzhangfei],a
  ld [positioninhuangzhong],a
  ld [positioninmachao],a
  ld [positioninguanyu],a
  ld [positioninzhaoyun],a
  ld [hadgoto],a;gai
  ld [ifneedreturn],a

MainLoop:;--------------------------------------------------------------------------------
  ld a, [gamestate] 
  cp 1
  call nz,Titlemainloop
  ld a, [hadgoto];gai
  cp 2
  call z, needgoto;gai
  call Gamemainloop
  jp MainLoop

SECTION "Functions", ROM0;------------------------------------------------------------

Titlemainloop:
  call UpdateGamestates
  ld a, [gamestate]       ; 检查游戏状态
  cp 1                    ; 如果是 1，则运行游戏主循环
  jp z, betweenTitleandmap
  jp nz,Titlemainloop

betweenTitleandmap:
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAM
  call EnableLCD
  jp MainLoop

Gamemainloop:
  call readKeys
  call Maygoto;gai
  call MaybeReset  ;check if A was pressed not yet
  call updateFSM;new
  call binToDec
  call WaitVBlank
  call CopyShadowOAMtoOAM
  call copyDigitsRev
  ret

Maygoto:;gai
  ld hl,current
  bit 1, [hl] ; check if B was pressed
  call nz, increasegotostate

  ret
increasegotostate:;if changestate is 4,change to 1
  call InitializeObjects
  ld a,1
  ld [ifneedreturn],a;new
  ld a,0
  ld [counter],a
  ld a,2
  ld [hadgoto],a;记得改回1
  ld a,[gotostate]
  inc a
  cp 6
  jp z,returngotostate
  ld [gotostate],a
  ret
returngotostate:
  ld a,1
  ld [gotostate],a
  ret


needgoto:;gai
  ld a,[gotostate]
  cp 1
  call z, gotofirst
  ld a,[gotostate]
  cp 2
  call z, gotosecond
  ld a,[gotostate]
  cp 3
  call z, gotothird
  ld a,[gotostate]
  cp 4
  call z, gotofour
  ld a,[gotostate]
  cp 5
  call z, gotofive
  ld a,1
  ld [hadgoto],a
  ret

gotofirst:
  ld a, 41
  ld [ShadowOAM+6], a
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAM
  call EnableLCD
  ret

gotosecond:
  ld a, 42
  ld [ShadowOAM+6], a
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAMsecond
  call EnableLCD
  ret

gotothird:
  ld a, 43
  ld [ShadowOAM+6], a
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAMthird
  call EnableLCD
  ret


gotofour:
  ld a, 44
  ld [ShadowOAM+6], a
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAMfour
  call EnableLCD
  ret

gotofive:
  ld a, 45
  ld [ShadowOAM+6], a
  call DisableLCD
  call ClearVRAM
  call CopyBGToVRAMfive
  call EnableLCD
  ret

checkselect:
  
  ld a,[ShadowOAM]
  sub 16
  ld c,a
  ld a,[ShadowOAM+1]
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,h
  ld [currentpixel],a;save current tile position in the background
  ld a,l
  ld [currentpixel+1],a
  ld a,[hl]
  ;获得当前块的tile
  ;!!!!!!!!!!!当前块的tile已经改变
  cp 0;empty
  call z, returnstate0
  cp 12;B
  call z, bingisselect
  cp 13;C
  call z, caocaosselect
  cp 16;zhangfei
  call z, zhangfeiselect
  cp 18;huangzhong
  call z, huangzhongselect
  cp 23;machao
  call z, machaoselect
  cp 35;guanyu
  call z, guanyuselect
  cp 36;zhaoyun
  call z, zhaoyunselect
  ret

guanyuselect:;---------------------------------------------------------------guanyu
  ld a,35
  ld [currenttile],a;save guanyu tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  call findpositioninguanyu;if is 左上角，改图
  ld a,[positioninguanyu];在move后改回1
  cp 1
  call z ,notcahngeguanyu;not 左上角
  
  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret
notcahngeguanyu:
  ld hl, ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl], a
  ret

findpositioninguanyu:;检测右边是否为G
  ;检测是否在左边，检测右边
  inc hl
  inc hl
  inc hl
  ld a,[hl]
  cp 35
  call z, rigthguanyu
  ret

rigthguanyu:
  ld a,2;是就设置为2
  ld [positioninguanyu],a
  ld [hl],39;更改为其他(改M)下方
  ret

guanyumove:
  call returnstate0
  ld a,1
  ld [positioninguanyu],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, guanyuGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, guanyuGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, guanyuGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, guanyuGoDown
  ret

guanyuGoLeft:
  ;先把原位置的guanyu改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+3
  inc hl
  inc hl
  inc hl
  ld [hl],35;guanyu(下方)
  
  
  ;检测左边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updateguanyubackground;用的是左边的Y
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updateguanyubackground:;(y,x)
  inc hl
  ld [hl],0;(1,0)
  dec hl
  dec hl
  ld [hl],35;(1,-2)
  dec hl
  ld [hl],7;(1,-3)左边
  inc hl
  inc hl
  inc hl
  inc hl
  inc hl
  ld [hl],8;(1,2)右边
  inc hl
  inc hl
  ld [hl],0;(1,4)
  inc hl
  ld [hl],0;(1,5)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(2,5)
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],0;(2,3)
  dec hl
  ld [hl],6;(2,2)right down corner
  dec hl
  dec hl
  ld [hl],10;(2,0)down egde
  dec hl
  ld [hl],10;(2,-1)down egde
  dec hl
  ld [hl],10;(2,-2)down egde
  dec hl
  ld [hl],4;(2,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],3;(0,-3)左上角
  inc hl
  ld [hl],9;(0,-2)上边
  inc hl
  ld [hl],9;(0,-1)上边
  inc hl
  ld [hl],9;(0,0)上边
  inc hl
  ld [hl],9;(0,1)上边
  inc hl
  ld [hl],5;(0,2)右上角
  inc hl
  ld [hl],0;(0,3)
  inc hl
  ld [hl],0;(0,4)
  inc hl
  ld [hl],0;(0,5)

  ret


guanyuGoRight:
  ;先把原位置的guanyu改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+3
  inc hl
  inc hl
  inc hl
  ld [hl],35;guanyu(下方)
  
  
  ;检测右边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 48;48 check right 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 40;40 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updateguanyubackground;用的是左边的Y
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updateguanyubackground:;(y,x)
  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  inc hl
  inc hl

  ld [hl],6;(2,8) rdc
  dec hl
  ld [hl],10;(2,7) de
  dec hl
  ld [hl],10;(2,6)
  dec hl
  ld [hl],10;(2,5)
  dec hl
  ld [hl],10;(2,4)
  dec hl
  ld [hl],4;(2,3) ldc
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],7;(1,3) le
  inc hl
  ld [hl],35;(1,4) Y
  inc hl
  ld [hl],0;(1,5)
  inc hl
  ld [hl],0;(1,6)
  inc hl
  ld [hl],35;(1,7)
  inc hl
  ld [hl],8;(1,8) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(0,8) ruc
  dec hl
  ld [hl],9;(0,7) ue
  dec hl
  ld [hl],9;(0,6)
  dec hl
  ld [hl],9;(0,5)
  dec hl
  ld [hl],9;(0,4)
  dec hl
  ld [hl],3;(0,3) luc
  dec hl
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)

  ret


guanyuGoUp:
  ;先把原位置的guanyu改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+3
  inc hl
  inc hl
  inc hl
  ld [hl],35;guanyu(下方)
  
  
  ;检测左边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;24 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测右边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;24 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updateguanyubackground;用的是左边的Y
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updateguanyubackground:;(y,x)
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  inc hl

  ld [hl],5;(-3,5) ruc
  dec hl
  ld [hl],9;(-3,4) ue
  dec hl
  ld [hl],9;(-3,3)
  dec hl
  ld [hl],9;(-3,2)
  dec hl
  ld [hl],9;(-3,1)
  dec hl
  ld [hl],3;(-3,0) luc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(-2,0) le
  inc hl
  ld [hl],35;(-2,1) Y
  inc hl
  ld [hl],0;(-2,2)
  inc hl
  ld [hl],0;(-2,3)
  inc hl
  ld [hl],35;(-2,4)
  inc hl
  ld [hl],8;(-2,5) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(-1,5) rdc
  dec hl
  ld [hl],10;(-1,4) de
  dec hl
  ld [hl],10;(-1,3)
  dec hl
  ld [hl],10;(-1,2)
  dec hl
  ld [hl],10;(-1,1)
  dec hl
  ld [hl],4;(-1,0) ldc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)
  inc hl
  ld [hl],0;(0,3)
  inc hl
  ld [hl],0;(0,4)
  inc hl
  ld [hl],0;(0,5)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(1,0)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,3)
  dec hl
  ld [hl],0;(1,4)
  dec hl
  ld [hl],0;(1,5)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)
  inc hl
  ld [hl],0;(2,3)
  inc hl
  ld [hl],0;(2,4)
  inc hl
  ld [hl],0;(2,5)

  ret


guanyuGoDown:
  ;先把原位置的guanyu改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+3
  inc hl
  inc hl
  inc hl
  ld [hl],35;guanyu(下方)
  
  
  ;检测左边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 24;24 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测右边的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 24;24 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updateguanyubackground;用的是左边的Y
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updateguanyubackground:;(y,x)
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  inc hl

  ld [hl],6;(5,5) rdc
  dec hl
  ld [hl],10;(5,4) de
  dec hl
  ld [hl],10;(5,3)
  dec hl
  ld [hl],10;(5,2)
  dec hl
  ld [hl],10;(5,1)
  dec hl
  ld [hl],4;(5,0) ldc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(4,0) le
  inc hl
  ld [hl],35;(4,1) Y
  inc hl
  ld [hl],0;(4,2)
  inc hl
  ld [hl],0;(4,3)
  inc hl
  ld [hl],35;(4,4)
  inc hl
  ld [hl],8;(4,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(3,5) ruc
  dec hl
  ld [hl],9;(3,4) ue
  dec hl
  ld [hl],9;(3,3)
  dec hl
  ld [hl],9;(3,2)
  dec hl
  ld [hl],9;(3,1)
  dec hl
  ld [hl],3;(3,0) luc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)
  inc hl
  ld [hl],0;(2,3)
  inc hl
  ld [hl],0;(2,4)
  inc hl
  ld [hl],0;(2,5)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,5)
  dec hl
  ld [hl],0;(1,4)
  dec hl
  ld [hl],0;(1,3)
  dec hl
  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32     
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)
  inc hl
  ld [hl],0;(0,3)
  inc hl
  ld [hl],0;(0,4)
  inc hl
  ld [hl],0;(0,5)

  ret



zhangfeiselect:;---------------------------------------------------------------zhangfei
  ld a,16
  ld [currenttile],a;save zhangfei tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  call findpositioninzhangfei;if is 左上角，改图
  ld a,[positioninzhangfei];在move后改回1
  cp 1
  call z ,notcahngezhangfei;not 左上角
  
  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret
notcahngezhangfei:
  ld hl, ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl], a
  ret

findpositioninzhangfei:;检测对角是否为Z
  ;检测是否在上面，检测下方
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld a,[hl]
  cp 16
  call z, upzhangfei
  ret
upzhangfei:
  ld a,2;是左上角设置为2
  ld [positioninzhangfei],a
  ld [hl],39;更改为其他(改M)下方
  ret

zhangfeimove:
  call returnstate0
  ld a,1
  ld [positioninzhangfei],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, zhangfeiGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, zhangfeiGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, zhangfeiGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, zhangfeiGoDown
  ret

zhangfeiGoLeft:
  ;先把原位置的machao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],16;zhangfei(下方)
  
  
  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;not wall
  call .updatezhangfeibackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatezhangfeibackground:;(y,x)
  dec hl
  ld [hl],16;(4,-2)
  dec hl
  ld [hl],7;(4,-3)左边
  inc hl
  inc hl
  ld [hl],8;(4,-1)右边
  inc hl
  ld [hl],0;(4,0)
  inc hl
  ld [hl],0;(4,1)
  inc hl
  ld [hl],0;(4,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(5,2)
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],0;(5,0)
  dec hl
  ld [hl],6;(5,-1)right down corner
  dec hl
  ld [hl],10;(5,-2)down egde
  dec hl
  ld [hl],4;(5,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(3,-3)
  inc hl
  inc hl
  ld [hl],8;(3,-1)right egde
  inc hl
  ld [hl],0;(3,0)
  inc hl
  inc hl
  ld [hl],0;(3,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(2,2)
  dec hl
  dec hl
  ld [hl],0;(2,0)
  dec hl
  ld [hl],8;(2,-1)
  dec hl
  dec hl
  ld [hl],7;(2,-3)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(1,-3)
  inc hl
  ld [hl],16;(1,-2)
  inc hl
  ld [hl],8;(1,-1)
  inc hl
  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)
  dec hl
  ld [hl],5;(0,-1)right up corner
  dec hl
  ld [hl],9;(0,-2)up egde
  dec hl
  ld [hl],3;(0,-3)left up corner


  ret


zhangfeiGoRight:
  ;先把原位置的zhangfei改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],16;zhangfei(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl
  dec hl
  dec hl

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)
  inc hl
  ld [hl],4;(5,3) ldc
  inc hl
  ld [hl],10;(5,4) de
  inc hl
  ld [hl],6;(5,5) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(4,5) re
  dec hl
  ld [hl],16;(4,4) F
  dec hl
  ld [hl],7;(4,3) le
  dec hl
  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)
  inc hl
  ld [hl],7;(3,3) le
  inc hl
  ld [hl],0;(3,4)
  inc hl
  ld [hl],8;(3,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(2,5) re
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],7;(2,3) le
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],7;(1,3) le
  inc hl
  ld [hl],16;(1,4) F
  inc hl
  ld [hl],8;(1,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(0,0)ruc
  dec hl
  ld [hl],9;(0,1)ue
  dec hl
  ld [hl],3;(0,2)luc
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,5)

  ret

zhangfeiGoUp:
  ;先把原位置的zhangfei改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],16;zhangfei(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;48 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  dec hl

  ld [hl],3;(-3,0) luc
  inc hl
  ld [hl],9;(-3,1) ue
  inc hl
  ld [hl],5;(-3,2) ruc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(-2,2) re
  dec hl
  ld [hl],16;(-2,1) F
  dec hl
  ld [hl],7;(-2,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(-1,0) le
  inc hl
  ld [hl],0;(-1,1)
  inc hl
  ld [hl],8;(-1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(0,2) re
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],7;(0,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a


  ld [hl],7;(1,0) le
  inc hl
  ld [hl],16;(1,1) F
  inc hl
  ld [hl],8;(1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(2,2)rdc
  dec hl
  ld [hl],10;(2,1)de
  dec hl
  ld [hl],4;(2,0)ldc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)

  ret


zhangfeiGoDown:
  ;先把原位置的zhangfei改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],16;zhangfei(下方)


  ;检测下面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 48;48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 40;48 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  cp 2;full
  ret z;if is full ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl

  ld [hl],4;(8,0) ldc
  inc hl
  ld [hl],10;(8,1) de
  inc hl
  ld [hl],6;(8,2) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(7,2) re
  dec hl
  ld [hl],16;(7,1) F
  dec hl
  ld [hl],7;(7,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(6,0) le
  inc hl
  ld [hl],0;(6,1)
  inc hl
  ld [hl],8;(6,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(5,2) re
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],7;(5,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],7;(4,0) le
  inc hl
  ld [hl],16;(4,1) F
  inc hl
  ld [hl],8;(4,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(3,2)ruc
  dec hl
  ld [hl],9;(3,1)ue
  dec hl
  ld [hl],3;(3,0)luc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ret


huangzhongselect:;-------------------------------------------------------huangzhong
  ld a,18
  ld [currenttile],a;save machao tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  call findpositioninhuangzhong;if is 左上角，改图
  ld a,[positioninhuangzhong];在move后改回1
  cp 1
  jr z ,notcahngehuangzhong;not 左上角
  
  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret
notcahngehuangzhong:
  ld hl, ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl], a
  ret


findpositioninhuangzhong:;检测下面是否为H
  ;检测是否在上面，检测下方
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld a,[hl]
  cp 18
  call z, uphuangzhong
  ret

uphuangzhong:
  ld a,2;是左上角设置为2
  ld [positioninhuangzhong],a
  ld [hl],39;更改为其他(改M)下方
  ret

huangzhongmove:
  call returnstate0
  ld a,1
  ld [positioninhuangzhong],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, huangzhongGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, huangzhongGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, huangzhongGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, huangzhongGoDown
  ret

huangzhongGoLeft:
  ;先把原位置的huangzhong改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],18;huangzhong(下方)
  
  
  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;not wall
  call .updatehuangzhongbackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatehuangzhongbackground:;(y,x)
  dec hl
  ld [hl],18;(4,-2)
  dec hl
  ld [hl],7;(4,-3)左边
  inc hl
  inc hl
  ld [hl],8;(4,-1)右边
  inc hl
  ld [hl],0;(4,0)
  inc hl
  ld [hl],0;(4,1)
  inc hl
  ld [hl],0;(4,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(5,2)
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],0;(5,0)
  dec hl
  ld [hl],6;(5,-1)right down corner
  dec hl
  ld [hl],10;(5,-2)down egde
  dec hl
  ld [hl],4;(5,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(3,-3)
  inc hl
  inc hl
  ld [hl],8;(3,-1)right egde
  inc hl
  ld [hl],0;(3,0)
  inc hl
  inc hl
  ld [hl],0;(3,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(2,2)
  dec hl
  dec hl
  ld [hl],0;(2,0)
  dec hl
  ld [hl],8;(2,-1)
  dec hl
  dec hl
  ld [hl],7;(2,-3)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(1,-3)
  inc hl
  ld [hl],18;(1,-2)
  inc hl
  ld [hl],8;(1,-1)
  inc hl
  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)
  dec hl
  ld [hl],5;(0,-1)right up corner
  dec hl
  ld [hl],9;(0,-2)up egde
  dec hl
  ld [hl],3;(0,-3)left up corner


  ret


huangzhongGoRight:
  ;先把原位置的huangzhong改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],18;huangzhong(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl
  dec hl
  dec hl

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)
  inc hl
  ld [hl],4;(5,3) ldc
  inc hl
  ld [hl],10;(5,4) de
  inc hl
  ld [hl],6;(5,5) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(4,5) re
  dec hl
  ld [hl],18;(4,4) H
  dec hl
  ld [hl],7;(4,3) le
  dec hl
  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)
  inc hl
  ld [hl],7;(3,3) le
  inc hl
  ld [hl],0;(3,4)
  inc hl
  ld [hl],8;(3,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(2,5) re
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],7;(2,3) le
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],7;(1,3) le
  inc hl
  ld [hl],18;(1,4) H
  inc hl
  ld [hl],8;(1,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(0,0)ruc
  dec hl
  ld [hl],9;(0,1)ue
  dec hl
  ld [hl],3;(0,2)luc
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,5)

  ret

huangzhongGoUp:
  ;先把原位置的huangzhong改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],18;huangzhong(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;48 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  dec hl

  ld [hl],3;(-3,0) luc
  inc hl
  ld [hl],9;(-3,1) ue
  inc hl
  ld [hl],5;(-3,2) ruc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(-2,2) re
  dec hl
  ld [hl],18;(-2,1) H
  dec hl
  ld [hl],7;(-2,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(-1,0) le
  inc hl
  ld [hl],0;(-1,1)
  inc hl
  ld [hl],8;(-1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(0,2) re
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],7;(0,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a


  ld [hl],7;(1,0) le
  inc hl
  ld [hl],18;(1,1) H
  inc hl
  ld [hl],8;(1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(2,2)rdc
  dec hl
  ld [hl],10;(2,1)de
  dec hl
  ld [hl],4;(2,0)ldc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)

  ret


huangzhongGoDown:
  ;先把原位置的huangzhong改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],18;huangzhong(下方)


  ;检测下面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 48;48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 40;48 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  cp 2;full
  ret z;if is full ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl

  ld [hl],4;(8,0) ldc
  inc hl
  ld [hl],10;(8,1) de
  inc hl
  ld [hl],6;(8,2) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(7,2) re
  dec hl
  ld [hl],18;(7,1) H
  dec hl
  ld [hl],7;(7,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(6,0) le
  inc hl
  ld [hl],0;(6,1)
  inc hl
  ld [hl],8;(6,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(5,2) re
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],7;(5,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],7;(4,0) le
  inc hl
  ld [hl],18;(4,1) H
  inc hl
  ld [hl],8;(4,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(3,2)ruc
  dec hl
  ld [hl],9;(3,1)ue
  dec hl
  ld [hl],3;(3,0)luc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ret


zhaoyunselect:;--------------------------------------------------------zhaoyun
  ld a,36
  ld [currenttile],a;save machao tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  call findpositioninzhaoyun;if is 左上角，改图
  ld a,[positioninzhaoyun];在move后改回1
  cp 1
  jr z ,notcahngezhaoyun;not 左上角
  
  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret
notcahngezhaoyun:
  ld hl, ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl], a
  ret


findpositioninzhaoyun:;检测下面是否为Z
  ;检测是否在上面，检测下方
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld a,[hl]
  cp 36
  call z, upzhaoyun
  ret

upzhaoyun:
  ld a,2;是左上角设置为2
  ld [positioninzhaoyun],a
  ld [hl],39;更改为其他(改M)下方
  ret

zhaoyunmove:
  call returnstate0
  ld a,1
  ld [positioninzhaoyun],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, zhaoyunGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, zhaoyunGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, zhaoyunGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, zhaoyunGoDown
  ret

zhaoyunGoLeft:
  ;先把原位置的zhaoyun改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],36;zhaoyun(下方)
  
  
  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;not wall
  call .updatezhaoyunbackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatezhaoyunbackground:;(y,x)
  dec hl
  ld [hl],36;(4,-2)
  dec hl
  ld [hl],7;(4,-3)左边
  inc hl
  inc hl
  ld [hl],8;(4,-1)右边
  inc hl
  ld [hl],0;(4,0)
  inc hl
  ld [hl],0;(4,1)
  inc hl
  ld [hl],0;(4,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(5,2)
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],0;(5,0)
  dec hl
  ld [hl],6;(5,-1)right down corner
  dec hl
  ld [hl],10;(5,-2)down egde
  dec hl
  ld [hl],4;(5,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(3,-3)
  inc hl
  inc hl
  ld [hl],8;(3,-1)right egde
  inc hl
  ld [hl],0;(3,0)
  inc hl
  inc hl
  ld [hl],0;(3,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(2,2)
  dec hl
  dec hl
  ld [hl],0;(2,0)
  dec hl
  ld [hl],8;(2,-1)
  dec hl
  dec hl
  ld [hl],7;(2,-3)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(1,-3)
  inc hl
  ld [hl],36;(1,-2)
  inc hl
  ld [hl],8;(1,-1)
  inc hl
  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)
  dec hl
  ld [hl],5;(0,-1)right up corner
  dec hl
  ld [hl],9;(0,-2)up egde
  dec hl
  ld [hl],3;(0,-3)left up corner


  ret


zhaoyunGoRight:
  ;先把原位置的zhaoyun改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],36;zhaoyun(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl
  dec hl
  dec hl

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)
  inc hl
  ld [hl],4;(5,3) ldc
  inc hl
  ld [hl],10;(5,4) de
  inc hl
  ld [hl],6;(5,5) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(4,5) re
  dec hl
  ld [hl],36;(4,4) Z
  dec hl
  ld [hl],7;(4,3) le
  dec hl
  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)
  inc hl
  ld [hl],7;(3,3) le
  inc hl
  ld [hl],0;(3,4)
  inc hl
  ld [hl],8;(3,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(2,5) re
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],7;(2,3) le
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],7;(1,3) le
  inc hl
  ld [hl],36;(1,4) Z
  inc hl
  ld [hl],8;(1,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(0,0)ruc
  dec hl
  ld [hl],9;(0,1)ue
  dec hl
  ld [hl],3;(0,2)luc
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,5)

  ret

zhaoyunGoUp:
  ;先把原位置的zhaoyun改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],36;zhaoyun(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;48 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  dec hl

  ld [hl],3;(-3,0) luc
  inc hl
  ld [hl],9;(-3,1) ue
  inc hl
  ld [hl],5;(-3,2) ruc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(-2,2) re
  dec hl
  ld [hl],36;(-2,1) Z
  dec hl
  ld [hl],7;(-2,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(-1,0) le
  inc hl
  ld [hl],0;(-1,1)
  inc hl
  ld [hl],8;(-1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(0,2) re
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],7;(0,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a


  ld [hl],7;(1,0) le
  inc hl
  ld [hl],36;(1,1) Z
  inc hl
  ld [hl],8;(1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(2,2)rdc
  dec hl
  ld [hl],10;(2,1)de
  dec hl
  ld [hl],4;(2,0)ldc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)

  ret


zhaoyunGoDown:
  ;先把原位置的zhaoyun改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],36;zhaoyun(下方)


  ;检测下面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 48;48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 40;48 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  cp 2;full
  ret z;if is full ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl

  ld [hl],4;(8,0) ldc
  inc hl
  ld [hl],10;(8,1) de
  inc hl
  ld [hl],6;(8,2) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(7,2) re
  dec hl
  ld [hl],36;(7,1) Z
  dec hl
  ld [hl],7;(7,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(6,0) le
  inc hl
  ld [hl],0;(6,1)
  inc hl
  ld [hl],8;(6,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(5,2) re
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],7;(5,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],7;(4,0) le
  inc hl
  ld [hl],36;(4,1) Z
  inc hl
  ld [hl],8;(4,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(3,2)ruc
  dec hl
  ld [hl],9;(3,1)ue
  dec hl
  ld [hl],3;(3,0)luc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ret



machaoselect:;-----------------------------------------------machao have porblem!!!!!!!!!!!
  ld a,23
  ld [currenttile],a;save machao tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  call findpositioninmachao;if is 左上角，改图
  ld a,[positioninmachao];在move后改回1
  cp 1
  jr z ,notcahngemachao;not 左上角
  
  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret
notcahngemachao:
  ld hl, ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl], a
  ret


findpositioninmachao:;检测下面是否为M
  ;检测是否在上面，检测下方
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld a,[hl]
  cp 23
  call z, upmachao
  ret

upmachao:
  ld a,2;是左上角设置为2
  ld [positioninmachao],a
  ld [hl],39;更改为其他(改M)下方
  ret

machaomove:
  call returnstate0
  ld a,1
  ld [positioninmachao],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, machaoGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, machaoGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, machaoGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, machaoGoDown
  ret

machaoGoLeft:
  ;先把原位置的machao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],23;machao(下方)
  
  
  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  dec hl
  ld [hl],23;(4,-2)
  dec hl
  ld [hl],7;(4,-3)左边
  inc hl
  inc hl
  ld [hl],8;(4,-1)右边
  inc hl
  ld [hl],0;(4,0)
  inc hl
  ld [hl],0;(4,1)
  inc hl
  ld [hl],0;(4,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(5,2)
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],0;(5,0)
  dec hl
  ld [hl],6;(5,-1)right down corner
  dec hl
  ld [hl],10;(5,-2)down egde
  dec hl
  ld [hl],4;(5,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(3,-3)
  inc hl
  inc hl
  ld [hl],8;(3,-1)right egde
  inc hl
  ld [hl],0;(3,0)
  inc hl
  inc hl
  ld [hl],0;(3,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(2,2)
  dec hl
  dec hl
  ld [hl],0;(2,0)
  dec hl
  ld [hl],8;(2,-1)
  dec hl
  dec hl
  ld [hl],7;(2,-3)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],7;(1,-3)
  inc hl
  ld [hl],23;(1,-2)
  inc hl
  ld [hl],8;(1,-1)
  inc hl
  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32      
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)
  dec hl
  ld [hl],5;(0,-1)right up corner
  dec hl
  ld [hl],9;(0,-2)up egde
  dec hl
  ld [hl],3;(0,-3)left up corner


  ret


machaoGoRight:
  ;先把原位置的machao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],23;machao(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;检测下方的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  sub 16
  add 24;d
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl
  dec hl
  dec hl

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)
  inc hl
  ld [hl],4;(5,3) ldc
  inc hl
  ld [hl],10;(5,4) de
  inc hl
  ld [hl],6;(5,5) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(4,5) re
  dec hl
  ld [hl],23;(4,4) M
  dec hl
  ld [hl],7;(4,3) le
  dec hl
  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)
  inc hl
  ld [hl],7;(3,3) le
  inc hl
  ld [hl],0;(3,4)
  inc hl
  ld [hl],8;(3,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(2,5) re
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],7;(2,3) le
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],0;(1,0)
  inc hl
  ld [hl],0;(1,1)
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],7;(1,3) le
  inc hl
  ld [hl],23;(1,4)
  inc hl
  ld [hl],8;(1,5) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(0,0)ruc
  dec hl
  ld [hl],9;(0,1)ue
  dec hl
  ld [hl],3;(0,2)luc
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,5)

  ret


machaoGoUp:
  ;先把原位置的machao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],23;machao(下方)


  ;检测上面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;48 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  dec hl

  ld [hl],3;(-3,0) luc
  inc hl
  ld [hl],9;(-3,1) ue
  inc hl
  ld [hl],5;(-3,2) ruc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(-2,2) re
  dec hl
  ld [hl],23;(-2,1) M
  dec hl
  ld [hl],7;(-2,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(-1,0) le
  inc hl
  ld [hl],0;(-1,1)
  inc hl
  ld [hl],8;(-1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(0,2) re
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],7;(0,0) le

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a


  ld [hl],7;(1,0) le
  inc hl
  ld [hl],23;(1,1) M
  inc hl
  ld [hl],8;(1,2) re

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(2,2)rdc
  dec hl
  ld [hl],10;(2,1)de
  dec hl
  ld [hl],4;(2,0)ldc

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(3,0)
  inc hl
  ld [hl],0;(3,1)
  inc hl
  ld [hl],0;(3,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(4,2)
  dec hl
  ld [hl],0;(4,1)
  dec hl
  ld [hl],0;(4,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,0)
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)

  ret


machaoGoDown:
  ;先把原位置的machao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],23;machao(下方)


  ;检测下面的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 48;48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 40;48 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  cp 2;full
  ret z;if is full ,return

  ;not wall
  call .updatemacachaobackground;用的是下方的hl
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret

.updatemacachaobackground:;(y,x)
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  dec hl

  ld [hl],4;(8,0) ldc
  inc hl
  ld [hl],10;(8,1) de
  inc hl
  ld [hl],6;(8,2) rdc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(7,2) re
  dec hl
  ld [hl],23;(7,1) M
  dec hl
  ld [hl],7;(7,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(6,0) le
  inc hl
  ld [hl],0;(6,1)
  inc hl
  ld [hl],8;(6,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(5,2) re
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],7;(5,0) le

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],7;(4,0) le
  inc hl
  ld [hl],23;(4,1)
  inc hl
  ld [hl],8;(4,2) re

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(3,2)ruc
  dec hl
  ld [hl],9;(3,1)ue
  dec hl
  ld [hl],3;(3,0)luc

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ret



caocaosselect:;会被多次调用-------------------------------------caocao
  call .fixcaocaoselect

  ld a,13
  ld [currenttile],a;save caocao tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a

  call findpositionincao;if is 左上角，改图


  ld a,[positionincaocao];在move后改回1
  cp 1
  jp z ,notcahngecaocao;not 左上角

  ;ld [hl],39;更改为其他(改C)
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject（改obj）
  ret


.fixcaocaoselect:
.l:
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a

  ;hl-3 too right
  ld a, l        ; 将 L 的值加载到 A
  sub 3
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld a,[hl]
  cp 13
  jp nz, .u

  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a

  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a

  ;hl-3 
  ld a, l        ; 将 L 的值加载到 A
  sub 3
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld a,h
  ld [currentpixel],a
  ld a,l
  ld [currentpixel+1],a

.u:
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a


  ;hl-96 too down
  ld a, l        ; 将 L 的值加载到 A
  sub 96
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld a,[hl]
  cp 13
  ret nz
  
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a

  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a

  ;hl-96
  ld a, l        ; 将 L 的值加载到 A
  sub 96
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld a,h
  ld [currentpixel],a
  ld a,l
  ld [currentpixel+1],a
.done
  ret



notcahngecaocao:
  call returnstate0
  ret


findpositionincao:;检测对角是否为C 
  ;检测是否在左上角
  ;hl+32*3+3检测右下角 下三行
  ld a,99
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld a,[hl]
  cp 13
  call z, leftupcao
  ret

leftupcao:
  ld a,2;是左上角设置为2
  ld [positionincaocao],a
  ld [hl],39;更改为其他(改C)右下角

  ;hl-3左下角
  ld a, l        ; 将 L 的值加载到 A
  sub 3
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a 
  ld [hl],39;更改为其他(改C)左下角

  ;hl-32*3+3右上角
  ld a, l        ; 将 L 的值加载到 A
  sub 93
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a 
  ld [hl],39;更改为其他(改C)右上角
  ret

caocaomove:
  call returnstate0
  ld a,1
  ld [positionincaocao],a
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, caocaoGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, caocaoGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, caocaoGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, caocaoGoDown
  call checkcaocaoout
  ret

checkcaocaoout:
  ld a,[ShadowOAM+4];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+5];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  cp 13;caocao
  jp z,caocaoout
  ret
caocaoout:
 ld a,0
 ld [ShadowOAM+2],a
 ld [ShadowOAM+6],a
 ld [ifneedreturn],a
 call printcaocao
 ret

printcaocao:
 call DisableLCD
 call ClearVRAM
 call copycaocaotoscreen
 call EnableLCD
 ret

copycaocaotoscreen:
  call DisableLCD
  ld de, Winpage
  ld hl, $9800;_SCRN0
  ld bc, WinpageEnd - Winpage
  call CopyMemory
  call EnableLCD
  ret


caocaoGoLeft:
  ;先把原位置的caocao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  inc hl
  inc hl
  inc hl
  ld [hl],13;caocao(右上角)
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],13;caocao(右下角)
  dec hl
  dec hl
  dec hl
  ld [hl],13;caocao(左下角)
  
  ;检测左上角的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return


  ;检测左下角的obj
  ld a,[ShadowOAM];y：-16+24
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  
  ;not wall

  call .updatecaocaobackground;用的是左下角的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret
.updatecaocaobackground:;(y,x)
  
  inc hl
  ld [hl],0;(4,0)
  dec hl
  ld [hl],0;(4,-1)
  dec hl
  ld [hl],13;(4,-2)
  dec hl
  ld [hl],7;(4,-3)左边
  ;hl+5
  ld a,5
  add l
  ld l,a
  ld [hl],8;(4,2)right egde
  inc hl
  inc hl
  ld [hl],0;(4,4)
  inc hl
  ld [hl],0;(4,5)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,5)
  dec hl
  ld [hl],0;(5,4)
  dec hl
  ld [hl],0;(5,3)
  dec hl
  ld [hl],6;(5,2) right down corner
  dec hl
  dec hl
  ld [hl],10;(5,0)
  dec hl
  ld [hl],10;(5,-1)down egde
  dec hl
  ld [hl],10;(5,-2)
  dec hl
  ld [hl],4;(5,-3)left down corner

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64        
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(3,-3)
  inc hl
  inc hl
  inc hl
  ld [hl],0;(3,0)
  inc hl
  inc hl
  ld [hl],8;(3,2)
  inc hl
  inc hl
  inc hl
  ld [hl],0;(3,5)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,5)
  dec hl
  dec hl
  dec hl
  ld [hl],8;(2,2)
  dec hl
  dec hl
  ld [hl],0;(2,0)
  dec hl
  dec hl
  dec hl
  ld [hl],7;(2,-3)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(1,-3)
  inc hl
  ld [hl],13;(1,-2)
  inc hl
  inc hl
  ld [hl],0;(1,0)
  inc hl
  inc hl
  ld [hl],8;(1,2)
  inc hl
  inc hl
  ld [hl],0;(1,4)
  inc hl
  ld [hl],0;(1,5)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32       
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,5)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],5;(0,2)
  dec hl
  dec hl
  ld [hl],9;(0,0)up egde
  dec hl
  ld [hl],9;(0,-1)
  dec hl
  ld [hl],9;(0,-2)
  dec hl
  ld [hl],3;(0,-3)left up corner


  ret

caocaoGoRight:
  ;先把原位置的caocao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  inc hl
  inc hl
  inc hl
  ld [hl],13;caocao(右上角)
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],13;caocao(右下角)
  dec hl
  dec hl
  dec hl
  ld [hl],13;caocao(左下角)

  ;检测右上角的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 48;48 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 40;40 check right wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return


  ;检测右下角的obj
  ld a,[ShadowOAM];y：-16+24
  sub 16;sub 16;fist 16 must sub ,get y in the background
  add 24;d-r
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 48;48 check left
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;sub 16;fist 16 must sub ,get y in the background
  add 24;d-r
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 40;48 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall

  call .updatecaocaobackground;用的是左下角的hl
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret
.updatecaocaobackground:;(y,x)

  inc hl
  inc hl

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(5,8) right down corner
  dec hl
  ld [hl],10;(5,7) down egde
  dec hl
  ld[hl],10;(5,6)
  dec hl
  ld[hl],10;(5,5)
  dec hl
  ld[hl],10;(5,4)
  dec hl
  ld[hl],4;(5,3) left down corner
  dec hl
  ld[hl],0;(5,2)
  dec hl
  ld[hl],0;(5,1)
  dec hl
  ld[hl],0;(5,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(4,0)
  inc hl
  ld [hl],0;(4,1)
  inc hl
  ld [hl],0;(4,2)
  inc hl
  ld [hl],7;(4,3) left edge
  inc hl
  ld [hl],13;(4,4) C
  inc hl
  ld [hl],0;(4,5)
  inc hl
  ld [hl],0;(4,6)
  inc hl
  ld [hl],13;(4,7)
  inc hl
  ld [hl],8;(4,8) right edge


  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(3,8) right edge
  dec hl
  ld [hl],0;(3,7)
  dec hl
  ld[hl],0;(3,6)
  dec hl
  ld[hl],0;(3,5)
  dec hl
  ld[hl],0;(3,4)
  dec hl
  ld[hl],7;(3,3) left edge
  dec hl
  ld[hl],0;(3,2)
  dec hl
  ld[hl],0;(3,1)
  dec hl
  ld[hl],0;(3,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,0)
  inc hl
  ld [hl],0;(2,1)
  inc hl
  ld [hl],0;(2,2)
  inc hl
  ld [hl],7;(2,3) left edge
  inc hl
  ld [hl],0;(2,4)
  inc hl
  ld [hl],0;(2,5)
  inc hl
  ld [hl],0;(2,6)
  inc hl
  ld [hl],0;(2,7)
  inc hl
  ld [hl],8;(2,8) right edge

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(1,8) right edge
  dec hl
  ld [hl],13;(1,7) C
  dec hl
  ld[hl],0;(1,6)
  dec hl
  ld[hl],0;(1,5)
  dec hl
  ld[hl],13;(1,4) C
  dec hl
  ld[hl],7;(1,3) left edge
  dec hl
  ld[hl],0;(1,2)
  dec hl
  ld[hl],0;(1,1)
  dec hl
  ld[hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)
  inc hl
  ld [hl],3;(0,3) left up corner
  inc hl
  ld [hl],9;(0,4) up edge
  inc hl
  ld [hl],9;(0,5)
  inc hl
  ld [hl],9;(0,6)
  inc hl
  ld [hl],9;(0,7)
  inc hl
  ld [hl],5;(0,8) right up corner

  ret


caocaoGoUp:
  ;先把原位置的caocao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  inc hl
  inc hl
  inc hl
  ld [hl],13;caocao(右上角)
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],13;caocao(右下角)
  dec hl
  dec hl
  dec hl
  ld [hl],13;caocao(左下角)

  ;检测左上角的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24; 24 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16; 16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return


  ;检测右上角的obj
  ld a,[ShadowOAM];y：-16+24
  sub 16;sub 16;fist 16 must sub ,get y in the background
  sub 24;24 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;u-r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;u-r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall

  call .updatecaocaobackground;用的是左下角的hl
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret
.updatecaocaobackground:;(y,x)

  inc hl
  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],5;(-3,5) right up corner
  dec hl
  ld [hl],9;(-3,4) up egde
  dec hl
  ld [hl],9;(-3,3)
  dec hl
  ld [hl],9;(-3,2)
  dec hl
  ld [hl],9;(-3,1)
  dec hl
  ld [hl],3;(-3,0) left up corner

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a


  ld [hl],7;(-2,0) left edge
  inc hl
  ld [hl],13;(-2,1) C
  inc hl
  ld [hl],0;(-2,2)
  inc hl
  ld [hl],0;(-2,3)
  inc hl
  ld [hl],13;(-2,4)
  inc hl
  ld [hl],8;(-2,5) right edge


  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(-1,5) right edge
  dec hl
  ld [hl],0;(-1,4)
  dec hl
  ld [hl],0;(-1,3)
  dec hl
  ld [hl],0;(-1,2)
  dec hl
  ld [hl],0;(-1,1)
  dec hl
  ld [hl],7;(-1,0) left edge

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(0,0) left edge
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)
  inc hl
  ld [hl],0;(0,3)
  inc hl
  ld [hl],0;(0,4)
  inc hl
  ld [hl],8;(0,5) right edge

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],8;(1,5) right edge
  dec hl
  ld [hl],13;(1,4) C
  dec hl
  ld [hl],0;(1,3)
  dec hl
  ld [hl],0;(1,2)
  dec hl
  ld [hl],13;(1,1) C
  dec hl
  ld [hl],7;(1,0) left edge

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],4;(2,0) left down corner
  inc hl
  ld [hl],10;(2,1) down edge
  inc hl
  ld [hl],10;(2,2)
  inc hl
  ld [hl],10;(2,3)
  inc hl
  ld [hl],10;(2,4)
  inc hl
  ld [hl],6;(2,5) right down corner

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(3,5)
  dec hl
  ld [hl],0;(3,4)
  dec hl
  ld [hl],0;(3,3)
  dec hl
  ld [hl],0;(3,2)
  dec hl
  ld [hl],0;(3,1)
  dec hl
  ld [hl],0;(3,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(4,0) left up corner
  inc hl
  ld [hl],0;(4,1) up edge
  inc hl
  ld [hl],0;(4,2)
  inc hl
  ld [hl],0;(4,3)
  inc hl
  ld [hl],0;(4,4)
  inc hl
  ld [hl],0;(4,5) right up corner

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(5,5)
  dec hl
  ld [hl],0;(5,4)
  dec hl
  ld [hl],0;(5,3)
  dec hl
  ld [hl],0;(5,2)
  dec hl
  ld [hl],0;(5,1)
  dec hl
  ld [hl],0;(5,0)

  ret




caocaoGoDown:
  ;先把原位置的caocao改回来
  ld a,[ShadowOAM];y
  sub 16
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  inc hl
  inc hl
  inc hl
  ld [hl],13;caocao(右上角)
  ;hl+32*3
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],13;caocao(右下角)
  dec hl
  dec hl
  dec hl
  ld [hl],13;caocao(左下角)

  ;检测左下角的obj
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 48; 48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  add 40; 40 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return


  ;检测右下角的obj
  ld a,[ShadowOAM];y：-16+24
  sub 16;sub 16;fist 16 must sub ,get y in the background
  add 48;48 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;d-r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;sub 16;fist 16 must sub ,get y in the background
  add 40;48 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;d-r
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

  ;not wall

  call .updatecaocaobackground;用的是左下角的hl
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret
.updatecaocaobackground:;(y,x)

  inc hl

  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(8,5) right down corner
  dec hl
  ld [hl],10;(8,4) down egde
  dec hl
  ld [hl],10;(8,3)
  dec hl
  ld [hl],10;(8,2)
  dec hl
  ld [hl],10;(8,1)
  dec hl
  ld [hl],4;(8,0) left down corner

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a


  ld [hl],7;(7,0) left edge
  inc hl
  ld [hl],13;(7,1) C
  inc hl
  ld [hl],0;(7,2)
  inc hl
  ld [hl],0;(7,3)
  inc hl
  ld [hl],13;(7,4)
  inc hl
  ld [hl],8;(7,5) right edge


  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(6,5) right edge
  dec hl
  ld [hl],0;(6,4)
  dec hl
  ld [hl],0;(6,3)
  dec hl
  ld [hl],0;(6,2)
  dec hl
  ld [hl],0;(6,1)
  dec hl
  ld [hl],7;(6,0) left edge

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],7;(5,0) left edge
  inc hl
  ld [hl],0;(5,1)
  inc hl
  ld [hl],0;(5,2)
  inc hl
  ld [hl],0;(5,3)
  inc hl
  ld [hl],0;(5,4)
  inc hl
  ld [hl],8;(5,5) right edge

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],8;(4,5) right edge
  dec hl
  ld [hl],13;(4,4) C
  dec hl
  ld [hl],0;(4,3)
  dec hl
  ld [hl],0;(4,2)
  dec hl
  ld [hl],13;(4,1) C
  dec hl
  ld [hl],7;(4,0) left edge

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],3;(3,0) left up corner
  inc hl
  ld [hl],9;(3,1) up edge
  inc hl
  ld [hl],9;(3,2)
  inc hl
  ld [hl],9;(3,3)
  inc hl
  ld [hl],9;(3,4)
  inc hl
  ld [hl],5;(3,5) right up corner

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(2,5)
  dec hl
  ld [hl],0;(2,4)
  dec hl
  ld [hl],0;(2,3)
  dec hl
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,0) left up corner
  inc hl
  ld [hl],0;(1,1) up edge
  inc hl
  ld [hl],0;(1,2)
  inc hl
  ld [hl],0;(1,3)
  inc hl
  ld [hl],0;(1,4)
  inc hl
  ld [hl],0;(1,5) right up corner

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,5)
  dec hl
  ld [hl],0;(0,4)
  dec hl
  ld [hl],0;(0,3)
  dec hl
  ld [hl],0;(0,2)
  dec hl
  ld [hl],0;(0,1)
  dec hl
  ld [hl],0;(0,0)

  ret




bingisselect:;secend-----------------------------------------------bing
  ld a,12
  ld [currenttile],a;save bing tile
  ld a,[currentpixel]
  ld h,a
  ld a,[currentpixel+1]
  ld l,a
  ld [hl],39;更改为其他
  ld hl,ShadowOAM+2
  ld [hl],38;change selectobject
;改颜色

  ret

bingmove:;third
  call returnstate0
  ld hl,current2
  bit 5, [hl]  ; check if left was pressed
  call nz, bingGoLeft
  ld hl,current2
  bit 4, [hl]  ; check if right was pressed
  call nz, bingGoRight
  ld hl,current2
  bit 6, [hl]  ; check if up was pressed
  call nz, bingGoUp
  ld hl,current2
  bit 7, [hl]  ; check if down was pressed
  call nz, bingGoDown
  ret

bingGoLeft:
  ;先把原位置的bing改回来
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub , 
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ld [hl],12;bing

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+24;fist 8 must sub ,24 check left 
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

;not wall

  call .updatebingbackground
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter

  ret
.updatebingbackground:
  inc hl
  inc hl
  ld [hl],0;坐上角(0,0),这是(1,1)
  dec hl
  ld [hl],0;(1,0)
  inc hl
  inc hl
  ld [hl],0;(1,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 64         ; A = L - 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a 

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  dec hl
  dec hl
  dec hl;left
  ld [hl],5
  dec hl
  ld [hl],9
  dec hl
  ld [hl],3

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  
  ld [hl],7;(2,2)
  inc hl
  ld [hl],12;(2,1)
  inc hl
  ld [hl],8;(2,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(3,2)
  dec hl
  ld [hl],10;(3,1)
  dec hl
  ld [hl],4;(3,0)

  ret



bingGoRight:
  ;先把原位置的bing改回来
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub ,
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ld [hl],12;bing

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 24;24 check right
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei F
  ret z;if is zhangfei ,return
  cp 18;huangzhong H
  ret z;if is huangzhong ,return
  cp 23;machao M
  ret z;if is machao ,return
  cp 35;guanyu Y
  ret z;if is guanyu ,return
  cp 36;zhaoyun Z
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  add 16;16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

;not wall

  call .updatebingbackground
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret
.updatebingbackground:
  dec hl
  dec hl
  ld [hl],0;坐上角(0,0),这是(1,1)
  dec hl
  ld [hl],0;(1,0)
  inc hl
  inc hl
  ld [hl],0;(1,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a
  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64         ; A = L - 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  inc hl
  inc hl
  inc hl;right
  ld [hl],5
  dec hl
  ld [hl],9
  dec hl
  ld [hl],3

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(2,2)
  inc hl
  ld [hl],12;(2,1)
  inc hl
  ld [hl],8;(2,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(3,2)
  dec hl
  ld [hl],10;(3,1)
  dec hl
  ld [hl],4;(3,0)

  ret



bingGoUp:
  ;先把原位置的bing改回来
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub ,
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ld [hl],12;bing

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 24;24 check up
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  sub 16;16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return

;not wall

  call .updatebingbackground
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  call IncrementCounter
  ret
.updatebingbackground:
  ;hl+64
  ld a,64
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;坐上角(0,0),这是(1,1)
  dec hl
  ld [hl],0;(1,0)
  inc hl
  inc hl
  ld [hl],0;(1,2)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],0;(2,2)
  dec hl
  ld [hl],0;(2,1)
  dec hl
  ld [hl],0;(2,0)

  ;hl-64
  ld a, l        ; 将 L 的值加载到 A
  sub 64         ; A = L - 64
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ;hl-96
  ld a, l        ; 将 L 的值加载到 A
  sub 96         ; A = L - 96
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a
  ;up
  ld [hl],5
  dec hl
  ld [hl],9
  dec hl
  ld [hl],3

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(2,2)
  inc hl
  ld [hl],12;(2,1)
  inc hl
  ld [hl],8;(2,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(3,2)
  dec hl
  ld [hl],10;(3,1)
  dec hl
  ld [hl],4;(3,0)

  ret


bingGoDown:
 ;先把原位置的bing改回来
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub ,
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  ld [hl],12;bing

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  add 8;24 check down
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 12;bing
  ret z;if is bing ,return
  cp 13;caocao
  ret z;if is caocao ,return
  cp 16;zhangfei
  ret z;if is zhangfei ,return
  cp 18;huangzhong
  ret z;if is huangzhong ,return
  cp 23;machao
  ret z;if is machao ,return
  cp 35;guanyu
  ret z;if is guanyu ,return
  cp 36;zhaoyun
  ret z;if is zhaoyun ,return

  ld a,[ShadowOAM];y
  ;sub 16;fist 16 must sub ,get y in the background
  ;add 16;16 check down wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ;add 16;16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl];                     left position
  cp 1;wall
  ret z;if is wall ,return
  cp 2;full
  ret z;if is full ,return

;not wall
  inc hl
  inc hl
  call .updatebingbackground
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  call IncrementCounter
  ret
.updatebingbackground:
  dec hl
  dec hl
  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32         ; A = L - 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;坐上角(0,0),这是(2,1)
  dec hl
  ld [hl],0;(2,0)
  inc hl
  inc hl
  ld [hl],0;(2,2)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32         ; A = L - 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(1,2)
  dec hl
  ld [hl],0;(1,1)
  dec hl
  ld [hl],0;(1,0)

  ;hl-32
  ld a, l        ; 将 L 的值加载到 A
  sub 32         ; A = L - 32
  ld l, a        ; 将结果存回 L
  ld a, h        ; 将 H 的值加载到 A
  sbc 0          ; A = H - 借位
  ld h, a

  ld [hl],0;(0,0)
  inc hl
  ld [hl],0;(0,1)
  inc hl
  ld [hl],0;(0,2)

  ;hl+96
  ld a,96
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ;down
  ld [hl],5
  dec hl
  ld [hl],9
  dec hl
  ld [hl],3

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],7;(2,2)
  inc hl
  ld [hl],12;(2,1)
  inc hl
  ld [hl],8;(2,0)

  ;hl+32
  ld a,32
  add l
  ld l,a
  adc h
  sub l
  ld h,a

  ld [hl],6;(3,2)
  dec hl
  ld [hl],10;(3,1)
  dec hl
  ld [hl],4;(3,0)

  ret



;------------------------------------------------------------
checkselect2:
  ld a,[currenttile]
  cp 12;B
  call z, bingmove ;third

  ld a,[currenttile]
  cp 13;C
  call z, caocaomove

  ld a,[currenttile]
  cp 16;F zhangfei
  call z, zhangfeimove

  ld a,[currenttile]
  cp 18;H huangzhong
  call z, huangzhongmove

  ld a,[currenttile]
  cp 23;M machao
  call z, machaomove

  ld a,[currenttile]
  cp 35;Y guanyu
  call z, guanyumove

  ld a,[currenttile]
  cp 36;Z zhaoyun
  call z, zhaoyunmove
  ret






selectobjchangedirection:
  ld hl,current
  bit 5, [hl]  ; check if left was pressed
  call nz, GoLeft
  ld hl,current
  bit 4, [hl]  ; check if right was pressed
  call nz, GoRight
  ld hl,current
  bit 6, [hl]  ; check if up was pressed
  call nz, GoUp
  ld hl,current
  bit 7, [hl]  ; check if down was pressed
  call nz, GoDown
  ret

GoLeft:
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8+16;fist 8 must sub ,16 check left wall
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  cp $01;wall
  ret z;if is wall ,return
;not wall
  ld hl,ShadowOAM+1
  ld a,[hl]
  sub 24
  ld [hl],a
  ret
GoUp:
  ld a,[ShadowOAM];y
  sub 16+16;fist 16 must sub ,secend 16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  cp $01;wall
  ret z;if is wall ,return
;not wall
  ld hl,ShadowOAM
  ld a,[hl]
  sub 24
  ld [hl],a
  ret
GoRight:
  ld a,[ShadowOAM];y
  sub 16;fist 16 must sub ,get y in the background
  ld c,a
  ld a,[ShadowOAM+1];x
  add 8;=sub 8-16
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  cp $01;wall
  ret z;if is wall ,return
;not wall
  ld hl,ShadowOAM+1
  ld a,[hl]
  add 24
  ld [hl],a
  ret
GoDown:
  ld a,[ShadowOAM];y
  ;sub 16-16fist 16 must sub ,secend 16 check up wall
  ld c,a
  ld a,[ShadowOAM+1];x
  sub 8;fist 8 must sub
  ld b,a
  call GetTileByPixel
  ld a,[hl]
  cp $01;wall
  ret z;if is wall ,return
  cp $02;full
  ret z;if is full ,return
;not wall
  ld hl,ShadowOAM
  ld a,[hl]
  add 24
  ld [hl],a
  ret


MaybeReset:
  ld hl,current
  bit 2, [hl] ; check if A was pressed
  call nz, Resetpage1
  ;call nz, InitializeObjects 
  call nz, returnstate0
  ret

Resetpage1:;gainew
  ld a,1
  ld [ifneedreturn],a
  ld a,0
  ld [counter],a
  call DisableLCD
  call ClearVRAM
  ld a,[gotostate]
  cp 1
  call z, CopyBGToVRAM
  ld a,[gotostate]
  cp 2
  call z, CopyBGToVRAMsecond
  ld a,[gotostate]
  cp 3
  call z, CopyBGToVRAMthird
  ld a,[gotostate]
  cp 4
  call z, CopyBGToVRAMfour
  ld a,[gotostate]
  cp 5
  call z, CopyBGToVRAMfive
  call EnableLCD
  ret

;y=16,x=8 is (0,0) in the screen
;y=24,x=16 is (1,1) in the screen
InitializeObjects:
  ld hl,   ShadowOAM   ; hl points to first object entry
  ld a,32+24*4
  ld [hl], a
  inc      hl          ; point to first object`s X
  ld a,24+24*3
  ld [hl], a
  inc      hl
  ld       [hl], 2   ; smiling face
  inc      hl
  ld      [hl], %10000000 ;under the background
  inc      hl
  ; second object for caocao
  ld a,32+24*5
  ld [hl], a
  inc      hl          ; point to first object`s X
  ld a,24+24
  ld [hl], a
  inc      hl
  ld       [hl], 41  ; empty
  inc      hl
  ;ld       [hl], %10000000 ;under the background
  ret



updateFSM:;!!!!!!jp不会返回
  ld a,[fsmState]
  cp 0
  jp z, state0
  cp 1
  jp z, state1
  ret

state0:
  ld a,0
  ld [current2],a
  ld hl,current
  ld a,[ifneedreturn];new if is 0,return
  cp 0
  jp z, .done
  bit 0,[hl]
  jp nz, selectobjwaspressed
  call selectobjchangedirection
.done
  ret

selectobjwaspressed:
  ld a,1
  ld [fsmState],a
  ret


state1:; in select
  ld a,1
  ld [forcheckselect],a

  ld hl,current
  bit 5, [hl]  ; check if left was pressed
  call nz, willGo
  ld hl,current
  bit 4, [hl]  ; check if right was pressed
  call nz, willGo
  ld hl,current
  bit 6, [hl]  ; check if up was pressed
  call nz, willGo
  ld hl,current
  bit 7, [hl]  ; check if down was pressed
  call nz, willGo

  ld a,[forcheckselect]
  cp 1
  call z, checkselect;first

  ret

returnstate0:
  ld a,0
  ld [fsmState],a
  ld hl,ShadowOAM+2;change back
  ld [hl],2
  ret

willGo:
  ld a,[current]
  ld [current2],a
  call checkselect2 ;second
  ld a,2
  ld [forcheckselect],a
  ret




;maybe not need to change--------------------------------------------


; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32，背景的宽是32个瓷砖，所以Y轴的位置需要乘以32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:;将像素位置转换为瓷砖地图地址
	; First, we need to divide by 8 to convert a pixel position to a tile position.
	; After this we want to multiply the Y position by 32.
	; These operations effectively cancel out so we only need to mask the Y value.
	ld a, c
	and a, %11111000;将Y轴位置的低三位清零相当于向下取整到最近的 8 的倍数。例如，Y = 10 会变为 8。
	ld l, a
	ld h, 0
	; Now we have the position * 8 in hl
	add hl, hl ; position * 16
	add hl, hl ; position * 32
	; Just add the X position and offset to the tilemap, and we're done.
	ld a, b
	srl a ; a / 2
	srl a ; a / 4
	srl a ; a / 8
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld bc, $9800
	add hl, bc
	ret



ResetOAM:
; input: HL: location of OAM or Shadow OAM
  ld b,40*4
  ld a,0
.loop:
  ld [hl],a
  inc hl
  dec b
  jr nz,.loop
  ret

CopyShadowOAMtoOAM:
  ld hl, ShadowOAM
  ld de, _OAMRAM
  ld b, OBJCOUNT
.loop:
  ld a,[hl+]
  ld [de],a
  inc e
  ld a,[hl+]
  ld [de],a
  inc e
  ld a,[hl+]
  ld [de],a
  inc e
  ld a,[hl+]
  ld [de],a
  inc e
  dec b
  jr nz, .loop
  ret


;bit:7 down, 6 up, 5 left, 4 right, 3 start, 2 select, 1 B, 0 A
;---------------------------------------------------------------------
readKeys:
;---------------------------------------------------------------------
; Output:
; b : raw state:   pressing key triggers given action continuously
;                  as long as it is pressed
; c : rising edge: pressing key triggers given action only once,
;                  key must be released and pressed again
  ld    a,$20
  ldh   [rP1],a   
  ldh   a,[rP1]
  ldh   a,[rP1]
  cpl
  and   $0f         ; lower nibble has down, up, left, right
  swap	a           ; becomes high nibble
  ld	b,a
  ld    a,$10
  ldh   [rP1],a
  ldh   a,[rP1]
  ldh   a,[rP1]
  ldh   a,[rP1]
  ldh   a,[rP1]
  ldh   a,[rP1]
  ldh   a,[rP1]
  cpl
  and   $0f         ; lower nibble has start, select, B, A
  or    b
  ld    b,a

  ld    a,[previous]  ; load previous state
  xor   b	      ; result will be 0 if it`s the same as current read
  and   b	      ; keep buttons that were pressed during this read only
  ld    [current],a   ; store result in "current" variable and c register
  ld    c,a
  ld    a,b           ; current state will be previous in next read
  ld    [previous],a

  ld    a,$30         ; reset rP1
  ldh   [rP1],a
  ret


WaitVBlank:
  ld a, [rLY]
  cp 144
  jr nz, WaitVBlank
  ret


CopyMemory:
; input:
; de : source
; hl : destination
; bc : how many bytes
.copy:
  ld a,[de]
  inc de
  ld [hl],a
  inc hl
  dec bc
  ld a,b
  or c
  jr nz, .copy
  ret

CopyBGToVRAM:
  ld a,41
  ld [ShadowOAM+6],a
  call DisableLCD
  ld de, Background
  ld hl, $9800;_SCRN0
  ld bc, BackgroundEnd - Background
  call CopyMemory
  call EnableLCD
  ret

CopyBGToVRAMsecond:
  ld a,42
  ld [ShadowOAM+6],a
  call DisableLCD
  ld de, Backgroundse
  ld hl, $9800;_SCRN0
  ld bc, BackgroundEndse - Backgroundse
  call CopyMemory
  call EnableLCD
  ret

CopyBGToVRAMthird:
  ld a,43
  ld [ShadowOAM+6],a
  call DisableLCD
  ld de, Backgroundth
  ld hl, $9800;_SCRN0
  ld bc, BackgroundEndth - Backgroundth
  call CopyMemory
  call EnableLCD
  ret

CopyBGToVRAMfour:
  ld a,44
  ld [ShadowOAM+6],a
  call DisableLCD
  ld de, Background4
  ld hl, $9800;_SCRN0
  ld bc, BackgroundEnd4 - Background4
  call CopyMemory
  call EnableLCD
  ret

CopyBGToVRAMfive:
  ld a,45
  ld [ShadowOAM+6],a
  call DisableLCD
  ld de, Background5
  ld hl, $9800;_SCRN0
  ld bc, BackgroundEnd5 - Background5
  call CopyMemory
  call EnableLCD
  ret

CopyTileDataToVRAM:
  ld de, Tiles
  ld hl, _VRAM
  ld bc, TilesEnd - Tiles
  call CopyMemory
  ret

UpdateGamestates:
    call readKeys
    call Reset_start

    ld hl,gamestate
    bit 3,[hl]
    ret z

    call WaitVBlank
    jp UpdateGamestates

Reset_start:
    ld hl,current
    bit 3, [hl]  ; check if A was pressed
    call nz, changestate 
    ret

changestate:
    ld a,1
    ld [gamestate],a
    ret

TitleScreenLoop:
  call DisplayTitleScreen  ; 显示标题页面

DisplayTitleScreen:
  call ClearVRAM           ; 清空 VRAM
  call CopyTitleBGToVRAM   ; 加载标题页面内容
  ret


;標題
ClearVRAM:
    ld hl, $9800         ; 起始地址：背景 Tile Map 的起始地址
    ld bc, $0400         ; 计数器：1024 字节 (0x400)，32x32 Tile Map
    xor a               ; 将 A 寄存器设置为 0x00（清除值）

.clear_loop:
    ld [hl], a          ; 将 A (0x00) 写入当前 HL 指向的地址
    inc hl              ; HL 指向下一个字节
    dec bc              ; 字节计数器 -1
    ld a, b             ; 检查 BC 是否为 0
    or c
    jr nz, .clear_loop  ; 如果 BC 不为 0，继续循环

    ret                 ; 完成，返回


CopyTitleBGToVRAM:
  ld de, TitleBackground
  ld hl, $9800;_SCRN0
  ld bc, TitleBackgroundEnd - TitleBackground
  call CopyMemory
  ret

DisableLCD:
    ld a, [rLCDC]
    and %01111111            ; 清除 LCDCF_ON 位（关闭 LCD）
    ld [rLCDC], a
    ret

EnableLCD:
    ld a, [rLCDC]
    or %10000000             ; 设置 LCDCF_ON 位（打开 LCD）
    ld [rLCDC], a
    ret
;not change-----------------------------------------------------------








IncrementCounter:
  ld a, [counter]
  cp 255
  jr z, caocaoji
  inc a
  ld [counter], a
  ret
caocaoji:
  ld a,0
  ld [ShadowOAM+2],a
  ld [ShadowOAM+6],a
  ld [ifneedreturn],a;new
  call DisableLCD
  call ClearVRAM  
  ld de, Failpage
  ld hl, $9800;_SCRN0
  ld bc, FailpageEnd - Failpage
  call CopyMemory
  call EnableLCD
  ret

binToDec:
  ld hl, buffer
  ld a, [counter]
  ld b, 10
  ld c,0;divresult
  call modulo
  ld [hl], a;first
  inc hl
  ld a,c
  ld c,0;divresult
  ld b, 10
  call modulo
  ld [hl], a;secend
  inc hl
  ld a, c
  ld c,0;divresult
  ld b, 10
  call modulo
  ld [hl], a;third
; TODO
  ret

modulo:;if a < b, then a is the remainder
  cp b
  jr c, .done
  sub b
  inc c
  jr modulo
.done:
  ret

copyDigitsRev:
  ld hl, buffer
  ld de, _SCRN0 + 19

  ld a, [hl+]
  add 40
  ld [de], a
  dec de
  ld a, [hl+]
  add 40
  ld [de], a
  dec de
  ld a, [hl+]
  add 40
  ld [de], a
; TODO
  ret