// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.

// screen -- 16384
// keyboard -- 24576
//在一块256x512像素的屏幕上，有8K的地址空间来映射，则平均1bit代表2像素点
(LOOP)
//R0=8K=8192
@8192
D=A
@R0
M=D
//D=M[Keyboard]
@KBD
D=M
//if D == 0 then goto FILL_WHITE
@FILL_WHITE
D;JEQ

(FILL_BLACK)
//if R0 < 0 then goto LOOP
@R0
D=M
@LOOP
D;JLT
//M[Screen+R0] = -1 (11111111)  一个内存地址有8bit
@SCREEN
D=D+A
@screenAddrForDraw
M=D
@1
D=-A
@screenAddrForDraw
A=M
M=D
//R0 = R0 - 1
@R0
M=M-1
//goto FILL_BLACK
@FILL_BLACK
0;JMP


(FILL_WHITE)
//if R0 < 0 then goto LOOP
@R0
D=M
@LOOP
D;JLT
//M[Screen+R0] = 0
@SCREEN
D=D+A
A=D
M=0
//R0 = R0 - 1
@R0
M=M-1
//goto FILE_WHITE
@FILL_WHITE
0;JMP


// while(true) {
//     if(keyboard == 0) {
//         // set white
//     } else {
//         // set black
//     }
// }