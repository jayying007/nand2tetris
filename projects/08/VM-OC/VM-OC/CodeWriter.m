//
//  CodeWriter.m
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "CodeWriter.h"

@interface CodeWriter ()
@property (nonatomic) NSMutableString *asmString;
@property (nonatomic) UInt32 judgeIndex;
@property (nonatomic) UInt32 callIndex;
@end

@implementation CodeWriter

- (id)initWithPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.filePath = filePath;
        self.asmString = [NSMutableString string];
    }
    return self;
}

- (void)close {
    [self.asmString writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

- (void)writeInit {
    //初始化栈顶地址
    [self _writeLines:@[ @"@256",
                         @"D=A",
                         @"@SP",
                         @"M=D"]];
    [self writeCall:@"Sys.init" numArgs:0];
}

- (void)writeArithmetic:(NSString *)command {
    NSArray *popToDRegister = @[ @"@SP",
                                 @"AM=M-1",
                                 @"D=M"];
    NSArray *stackPointToARegister = @[ @"@SP",
                                        @"AM=M-1"];
    
    if ([command isEqualToString:@"add"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeLine:@"M=M+D"];
    } else if ([command isEqualToString:@"sub"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeLine:@"M=M-D"];
    } else if ([command isEqualToString:@"and"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeLine:@"M=M&D"];
    } else if ([command isEqualToString:@"or"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeLine:@"M=M|D"];
    } else if ([command isEqualToString:@"lt"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeJudge:@"JLT" index:self.judgeIndex++];
    } else if ([command isEqualToString:@"eq"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeJudge:@"JEQ" index:self.judgeIndex++];
    } else if ([command isEqualToString:@"gt"]) {
        [self _writeLines:popToDRegister];
        [self _writeLines:stackPointToARegister];
        [self _writeJudge:@"JGT" index:self.judgeIndex++];
    } else if ([command isEqualToString:@"neg"]) {
        [self _writeLines:popToDRegister];
        [self _writeLine:@"M=-D"];
    } else if ([command isEqualToString:@"not"]) {
        [self _writeLines:popToDRegister];
        [self _writeLine:@"M=!D"];
    }
    [self _writeLines:@[ @"@SP",
                         @"M=M+1"]];
}

- (void)writePushWithSegment:(NSString *)segment atIndex:(SInt32)index {
    if ([segment isEqualToString:@"constant"]) {
        [self _writeLines:@[ [NSString stringWithFormat:@"@%d", index],
                             @"D=A",
                             @"@SP",
                             @"A=M",
                             @"M=D",
                             @"@SP",
                             @"M=M+1"]];
    }
    //push local、argument、this、that x，是把这个段内存对应的地址（base+x）取数据到栈中
    else if ([segment isEqualToString:@"local"]) {
        [self _writePushWithSegment:@"LCL" atIndex:index];
    }
    else if ([segment isEqualToString:@"argument"]) {
        [self _writePushWithSegment:@"ARG" atIndex:index];
    }
    else if ([segment isEqualToString:@"this"]) {
        [self _writePushWithSegment:@"THIS" atIndex:index];
    }
    else if ([segment isEqualToString:@"that"]) {
        [self _writePushWithSegment:@"THAT" atIndex:index];
    }
    // push pointer 0，是把this指针的地址加到栈中
    else if ([segment isEqualToString:@"pointer"]) {
        [self _writeLines:@[ @"@R3",
                             @"D=A", //基地址
                             [NSString stringWithFormat:@"@%d", index],
                             @"A=A+D", //补上偏移量
                             @"D=M", //得到this或that指针的地址，存到D寄存器
                             @"@SP",
                             @"A=M",
                             @"M=D",
                             @"@SP",
                             @"M=M+1"
                          ]];
    }
    //R5~R12作为temp段
    else if ([segment isEqualToString:@"temp"]) {
        [self _writeLines:@[ @"@R5",
                             @"D=A", //基地址
                             [NSString stringWithFormat:@"@%d", index],
                             @"A=A+D", //补上偏移量
                             @"D=M",
                             @"@SP",
                             @"A=M",
                             @"M=D",
                             @"@SP",
                             @"M=M+1"
                          ]];
    }
    else if ([segment isEqualToString:@"static"]) {
        [self _writeLines:@[ [NSString stringWithFormat:@"@%@.%d", self.fileName, index],
                             @"D=M",
                             @"@SP",
                             @"A=M",
                             @"M=D",
                             @"@SP",
                             @"M=M+1"
                          ]];
    }
}

- (void)writePopWithSegment:(NSString *)segment atIndex:(SInt32)index {
    if ([segment isEqualToString:@"local"]) {
        [self _writePopWithSegment:@"LCL" atIndex:index];
    }
    else if ([segment isEqualToString:@"argument"]) {
        [self _writePopWithSegment:@"ARG" atIndex:index];
    }
    else if ([segment isEqualToString:@"this"]) {
        [self _writePopWithSegment:@"THIS" atIndex:index];
    }
    else if ([segment isEqualToString:@"that"]) {
        [self _writePopWithSegment:@"THAT" atIndex:index];
    }
    else if ([segment isEqualToString:@"pointer"]) {
        [self _writeLines:@[ @"@R3",
                             @"D=A",
                             [NSString stringWithFormat:@"@%d", index],
                             @"D=A+D",
                             @"@R13",
                             @"M=D",
                             @"@SP",
                             @"AM=M-1",
                             @"D=M",
                             @"@R13",
                             @"A=M",
                             @"M=D"
                          ]];
    }
    else if ([segment isEqualToString:@"temp"]) {
        [self _writeLines:@[ @"@R5",
                             @"D=A",
                             [NSString stringWithFormat:@"@%d", index],
                             @"D=A+D",
                             @"@R13",
                             @"M=D",
                             @"@SP",
                             @"AM=M-1",
                             @"D=M",
                             @"@R13",
                             @"A=M",
                             @"M=D"
                          ]];
    }
    else if ([segment isEqualToString:@"static"]) {
        [self _writeLines:@[ @"@SP",
                             @"AM=M-1",
                             @"D=M",
                             [NSString stringWithFormat:@"@%@.%d", self.fileName, index],
                             @"M=D"
                          ]];
    }
}

- (void)writeLabel:(NSString *)label {
    [self _writeLine:[NSString stringWithFormat:@"(%@)", label]];
}

- (void)writeGoto:(NSString *)label {
    [self _writeLines:@[ [NSString stringWithFormat:@"@%@", label],
                         @"0;JMP"]];
}
/// 如果栈顶元素非0，执行跳转
- (void)writeIf:(NSString *)label {
    NSArray *popToDRegister = @[ @"@SP",
                                 @"AM=M-1",
                                 @"D=M"];
    [self _writeLines:popToDRegister];
    [self _writeLines:@[ [NSString stringWithFormat:@"@%@", label],
                         @"D;JNE"]];
}
/// 参考P167的图
- (void)writeCall:(NSString *)functionName numArgs:(SInt32)numArgs {
    //跳转函数前，先把调用者的上下文保存起来
    //1.保存跳转回来的地址
    [self _writeLines:@[ [NSString stringWithFormat:@"@RETURN_ADDR_%d", self.callIndex],
                         @"D=A",
                         @"@SP",
                         @"A=M",
                         @"M=D",
                         @"@SP",
                         @"M=M+1"
                      ]];
    //2.保存所有寄存器的值
    for (NSString *segment in @[ @"LCL", @"ARG", @"THIS", @"THAT" ]) {
        [self _writeLines:@[ [NSString stringWithFormat:@"@%@", segment],
                             @"D=M",
                             @"@SP",
                             @"A=M",
                             @"M=D",
                             @"@SP",
                             @"M=M+1"
        ]];
    }
    //3.调用Call之前，已经push了参数了，所以更新下ARG的基地址(SP - 寄存器数 - 跳转地址 - 参数个数)
    [self _writeLines:@[ @"@SP",
                         @"D=M",
                         [NSString stringWithFormat:@"@%d", 4 + 1 + numArgs],
                         @"D=D-A",
                         @"@ARG",
                         @"M=D"
                      ]];
    //4.更新LCL
    [self _writeLines:@[ @"@SP",
                         @"D=M",
                         @"@LCL",
                         @"M=D"
                      ]];
    //跳转函数
    [self _writeLines:@[ [NSString stringWithFormat:@"@%@", functionName],
                         @"0;JMP",
                         [NSString stringWithFormat:@"(RETURN_ADDR_%d)", self.callIndex],
                      ]];
    self.callIndex++;
}
/// 参考P167的图
- (void)writeReturn {
    //将返回的地址暂存在R14，注意R13在Pop的时候用到，这里不能再用
    [self _writeLines:@[ @"@LCL",
                         @"D=M",
                         @"@5",
                         @"A=D-A", //LCL往上5个就是返回的地址
                         @"D=M",
                         @"@R14",
                         @"M=D"
                      ]];
    //调整栈顶返回值的位置
    [self writePopWithSegment:@"argument" atIndex:0];
    //恢复SP
    [self _writeLines:@[ @"@ARG",
                         @"D=M+1",
                         @"@SP",
                         @"M=D"
                      ]];
    //恢复寄存器
    NSArray *registers = @[ @"", @"THAT", @"THIS", @"ARG", @"LCL" ];
    for (int i = 1; i < registers.count; i++) {
        [self _writeLines:@[ @"@LCL",
                             @"D=M",
                             [NSString stringWithFormat:@"@%d", i],
                             @"A=D-A",
                             @"D=M",
                             [NSString stringWithFormat:@"@%@", registers[i]],
                             @"M=D"
                          ]];
    }
    //上下文已恢复，现在正式跳转
    [self _writeLines:@[ @"@R14",
                         @"A=M",
                         @"0;JMP"
                      ]];
}

- (void)writeFunction:(NSString *)functionName numLocals:(SInt32)numLocals {
    [self writeLabel:functionName];
    //预留空间给局部变量
    for (int i = 0; i < numLocals; i++) {
        [self writePushWithSegment:@"constant" atIndex:0];
    }
}
#pragma mark - Internal
/// 此刻的情况：栈顶先pop到D寄存器，然后A寄存器保存栈顶的地址
- (void)_writeJudge:(NSString *)judge index:(SInt32)index {
    [self _writeLines:@[ @"D=M-D",
                         [NSString stringWithFormat:@"@_JUDGE_TRUE_%d", index],
                         [NSString stringWithFormat:@"D;%@", judge],
                         @"@SP",
                         @"A=M",
                         @"M=0",
                         [NSString stringWithFormat:@"@_JUDGE_CONTINUE_%d", index],
                         @"0;JMP",
                         [NSString stringWithFormat:@"(_JUDGE_TRUE_%d)", index],
                         @"@SP",
                         @"A=M",
                         @"M=-1",
                         [NSString stringWithFormat:@"(_JUDGE_CONTINUE_%d)", index]
                      ]];
}

- (void)_writePushWithSegment:(NSString *)segment atIndex:(SInt32)index {
    [self _writeLines:@[ [NSString stringWithFormat:@"@%@", segment],
                         @"D=M",
                         [NSString stringWithFormat:@"@%d", index],
                         @"A=A+D",
                         @"D=M",
                         @"@SP",
                         @"A=M",
                         @"M=D",
                         @"@SP",
                         @"M=M+1"
                      ]];
}

- (void)_writePopWithSegment:(NSString *)segment atIndex:(SInt32)index {
    [self _writeLines:@[ [NSString stringWithFormat:@"@%@", segment],
                         @"D=M",
                         [NSString stringWithFormat:@"@%d", index],
                         @"D=A+D",
                         @"@R15", //R13~R15作为通用寄存器
                         @"M=D",
                         @"@SP",
                         @"AM=M-1",
                         @"D=M",
                         @"@R15",
                         @"A=M",
                         @"M=D"
                      ]];
}

- (void)_writeLine:(NSString *)line {
    [self.asmString appendFormat:@"%@\n", line];
}

- (void)_writeLines:(NSArray *)lines {
    for (NSString *line in lines) {
        [self _writeLine:line];
    }
}

@end
