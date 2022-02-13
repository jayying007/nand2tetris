//
//  VM.m
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "VM.h"
#import "Parser.h"
#import "CodeWriter.h"

@implementation VM

- (id)initWithVMFilePaths:(NSArray *)vmFilePaths asmFilePath:(NSString *)asmFilePath {
    self = [super init];
    if (self) {
        self.vmFilePaths = vmFilePaths;
        self.asmFilePath = asmFilePath;
    }
    return self;
}

- (void)startTranslate:(void (^)(BOOL))completeHandler {
    Parser *parser = [[Parser alloc] initWithVMFilePaths:self.vmFilePaths];
    CodeWriter *writer = [[CodeWriter alloc] initWithPath:self.asmFilePath];
    //写引导代码
    [writer writeInit];
    
    while ([parser hasMoreCommands]) {
        [parser advance];
        [writer setFileName:parser.currentFileName];
        
        switch (parser.commandType) {
            case Command_If:
                [writer writeIf:parser.arg1];
                break;
            case Command_Pop:
                [writer writePopWithSegment:parser.arg1 atIndex:parser.arg2];
                break;
            case Command_Call:
                [writer writeCall:parser.arg1 numArgs:parser.arg2];
                break;
            case Command_Goto:
                [writer writeGoto:parser.arg1];
                break;
            case Command_Push:
                [writer writePushWithSegment:parser.arg1 atIndex:parser.arg2];
                break;
            case Command_Label:
                [writer writeLabel:parser.arg1];
                break;
            case Command_Return:
                [writer writeReturn];
                break;
            case Command_Function:
                [writer writeFunction:parser.arg1 numLocals:parser.arg2];
                break;
            case Command_Arithmetic:
                [writer writeArithmetic:parser.arg1];
                break;
        }
    }
    [writer close];
    completeHandler(YES);
}

@end
