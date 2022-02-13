//
//  Assembler.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/29.
//

#import "Assembler.h"
#import "Parser.h"
#import "SymbolTable.h"
#import "Coder.h"
#import "Utility.h"

@interface Assembler ()
//符号表
@property (nonatomic) SymbolTable *symbolTable;
@end


@implementation Assembler

- (id)initWithAsmFilePath:(NSString *)asmFilePath hackFilePath:(NSString *)hackFilePath {
    self = [super init];
    if (self) {
        self.asmFilePath = asmFilePath;
        self.hackFilePath = hackFilePath;
        self.symbolTable  = [[SymbolTable alloc] init];
    }
    return self;
}

- (void)startTranslate:(void (^)(BOOL))completeHandler {
    [self buildSymbolTable];
    //从地址16开始存放变量
    UInt16 variableAddr = 16;
    NSMutableString *hackString = [NSMutableString string];
    Parser *parser = [[Parser alloc] initWithFilePath:self.asmFilePath];
    Coder *coder = [[Coder alloc] init];
    while ([parser hasMoreCommands]) {
        [parser advance];
        
        if (parser.commandType == Command_A) {
            NSString *symbol = [parser symbol];
            //立即数
            if ([Utility isNumber:symbol]) {
                [hackString appendFormat:@"%@\n", [Coder intValueTo16Bits:[symbol intValue]]];
            }
            //符号表能找到
            else if ([self.symbolTable containsSymbol:symbol]) {
                [hackString appendFormat:@"%@\n", [Coder intValueTo16Bits:[self.symbolTable getAddress:symbol]]];
            }
            //变量
            else {
                [self.symbolTable addEntryWithSymbol:symbol address:variableAddr];
                [hackString appendFormat:@"%@\n", [Coder intValueTo16Bits:variableAddr]];
                variableAddr++;
            }
        } else if (parser.commandType == Command_C) {
            NSString *destBit = [coder destTo3Bits:parser.dest];
            NSString *compBit = [coder compTo7Bits:parser.comp];
            NSString *jumpBit = [coder jumpTo3Bits:parser.jump];
            [hackString appendFormat:@"111%@%@%@\n", compBit, destBit, jumpBit];
        }
    }
    NSError *error;
    [hackString writeToFile:self.hackFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"%@", error);
    completeHandler(error == nil);
}

- (void)buildSymbolTable {
    Parser *parser = [[Parser alloc] initWithFilePath:self.asmFilePath];
    //程序计数器，记录Command所在行，即地址
    UInt32 pc = 0;
    while ([parser hasMoreCommands]) {
        [parser advance];
        if (parser.commandType == Command_A) {
            pc++;
        } else if (parser.commandType == Command_C) {
            pc++;
        } else if (parser.commandType == Command_L) {
            [self.symbolTable addEntryWithSymbol:parser.symbol address:pc];
        }
    }
}
#pragma mark - Internal


@end
