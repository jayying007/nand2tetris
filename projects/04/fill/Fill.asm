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

(LOOP)
//R0=5000
@5000
D=A
@0
M=D
//D=M[Keyboard]
@KBD
D=M
//if D == 0 then goto FILL2
@FILL2
D;JEQ

(FILL)
//if R0 == 0 then goto LOOP
@0
D=M
@LOOP
D;JEQ
//M[Screen+R0] = 1
@SCREEN
D=D+A
@1
M=D
@255
D=A
@1
A=M
M=D
//R0 = R0 - 1
@0
M=M-1
//goto FILL
@FILL
0;JMP


(FILL2)
//if R0 == 0 then goto LOOP
@0
D=M
@LOOP
D;JEQ
//M[Screen+R0] = 0
@SCREEN
D=D+A
A=D
M=0
//R0 = R0 - 1
@0
M=M-1
//goto FILL2
@FILL2
0;JMP


// while(true) {
//     if(keyboard == 0) {
//         // set white
//     } else {
//         // set black
//     }
// }