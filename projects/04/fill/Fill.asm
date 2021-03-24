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
@24576
D=M
@WHITE
D;JEQ


@7000
D=A
@0
M=D

(FILL)
@0
D=M
@LOOP
D;JEQ

@16384
D=D+A
A=D
M=1
@0
M=M-1
@FILL
0;JMP



(WHITE)

@7000
D=A
@0
M=D

(FILL2)
@0
D=M
@LOOP
D;JEQ

@16384
D=D+A
A=D
M=1
@0
M=M-1
@FILL2
0;JMP



// while(true) {
//     if(keyboard == 0) {
//         // set white
//     } else {
//         // set black
//     }
// }