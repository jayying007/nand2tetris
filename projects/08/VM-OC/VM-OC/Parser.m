//
//  Parser.m
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "Parser.h"
#import "Utility.h"

@interface Parser ()
/// 所有要读取的VM文件
@property (nonatomic) NSMutableArray *remainFilePaths;
/// 当前VM文件包含的指令
@property (nonatomic) NSMutableArray *commands;
/// 当前VM文件读取的位置
@property (nonatomic) SInt32 currentIndex;
/// 当前VM文件的路径
@property (nonatomic, copy) NSString *currentFilePath;
@property (nonatomic) NSDictionary *commandMap;
@end


@implementation Parser

- (id)initWithVMFilePaths:(NSArray *)vmFilePaths {
    self = [super init];
    if (self) {
        self.remainFilePaths = [vmFilePaths mutableCopy];
        self.commands = @[].mutableCopy;
        self.currentIndex = -1;
        self.commandMap = @{
            @"push" : @(Command_Push),
            @"pop" : @(Command_Pop),
            @"call" : @(Command_Call),
            @"function" : @(Command_Function),
            @"if-goto" : @(Command_If),
            @"return" : @(Command_Return),
            @"label" : @(Command_Label),
            @"goto" : @(Command_Goto),
            @"add" : @(Command_Arithmetic),
            @"sub" : @(Command_Arithmetic),
            @"lt" : @(Command_Arithmetic),
            @"eq" : @(Command_Arithmetic),
            @"gt" : @(Command_Arithmetic),
            @"and" : @(Command_Arithmetic),
            @"or" : @(Command_Arithmetic),
            @"not" : @(Command_Arithmetic),
            @"neg" : @(Command_Arithmetic),
        };
    }
    return self;
}

- (NSString *)currentFileName {
    return [self.currentFilePath lastPathComponent];
}

- (BOOL)hasMoreCommands {
    if (self.remainFilePaths.count > 0) {
        return YES;
    }
    if (self.commands.count > 0 && self.currentIndex + 1 < self.commands.count) {
        return YES;
    }
    return NO;
}

- (void)advance {
    //已读取到文件末尾
    if (self.currentIndex + 1 == self.commands.count) {
        [self.commands removeAllObjects];
        self.currentIndex = -1;
        self.currentFilePath = [self.remainFilePaths firstObject];
        [self.remainFilePaths removeObjectAtIndex:0];
        
        NSString *content = [NSString stringWithContentsOfFile:self.currentFilePath encoding:NSUTF8StringEncoding error:nil];
        [content enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            NSString *command = [Utility filterNote:line];
            if (command.length > 0) {
                [self.commands addObject:command];
            }
        }];
    }
    self.currentIndex++;
}

- (Command)commandType {
    NSString *keyword = [self.command componentsSeparatedByString:@" "][0];
    NSNumber *value = [self.commandMap objectForKey:keyword];
    if (value == 0) {
        NSLog(@"error: can not find keyword match '%@'", keyword);
        exit(0);
    }
    return (Command)value.intValue;
}

- (NSString *)arg1 {
    if (self.commandType == Command_Arithmetic) {
        return self.command;
    }
    return [self.command componentsSeparatedByString:@" "][1];
}

- (SInt32)arg2 {
    return [[self.command componentsSeparatedByString:@" "][2] intValue];
}
#pragma mark -
- (NSString *)command {
    return self.commands[self.currentIndex];
}
@end
