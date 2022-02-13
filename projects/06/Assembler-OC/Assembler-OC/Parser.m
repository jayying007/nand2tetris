//
//  Parser.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/29.
//

#import "Parser.h"
#import "Utility.h"

@interface Parser ()
@property (nonatomic) NSMutableArray *commands;
@property (nonatomic) SInt32 currentIndex;
@end

@implementation Parser

- (id)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.commands = @[].mutableCopy;
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [content enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            NSString *command = [Utility filterNote:line];
            if (command.length > 0) {
                [self.commands addObject:command];
            }
        }];
        self.currentIndex = -1;
    }
    return self;
}

- (BOOL)hasMoreCommands {
    return self.commands.count > 0 && self.currentIndex + 1 < self.commands.count;
}

- (void)advance {
    self.currentIndex++;
}

- (Command)commandType {
    NSString *command = self.commands[self.currentIndex];
    if ([command characterAtIndex:0] == '@') {
        NSString *targetString = [command substringFromIndex:1];
        if ([Utility isNumber:targetString] || [Utility isSymbol:targetString]) {
            return Command_A;
        }
    }
    if ([command characterAtIndex:0] == '(' && [command characterAtIndex:command.length - 1] == ')') {
        NSString *targetString = [command substringWithRange:NSMakeRange(1, command.length - 2)];
        if ([Utility isSymbol:targetString]) {
            return Command_L;
        }
    }
    return Command_C;
}

- (NSString *)symbol {
    NSString *command = self.commands[self.currentIndex];
    if (self.commandType == Command_A) {
        return [command substringFromIndex:1];
    }
    if (self.commandType == Command_L) {
        return [command substringWithRange:NSMakeRange(1, command.length - 2)];
    }
    return @"";
}

- (NSString *)dest {
    if (self.commandType != Command_C) {
        return @"";
    }
    
    NSString *command = self.commands[self.currentIndex];
    if ([command containsString:@"="]) {
        NSArray *array = [command componentsSeparatedByString:@"="];
        return array[0];
    }
    return @"";
}

- (NSString *)comp {
    if (self.commandType != Command_C) {
        return @"";
    }
    
    NSString *command = self.commands[self.currentIndex];
    if ([command containsString:@"="]) {
        NSString *tmp = [command componentsSeparatedByString:@"="][1];
        if ([tmp containsString:@";"]) {
            return [tmp componentsSeparatedByString:@";"][0];
        } else {
            return tmp;
        }
    }
    if ([command containsString:@";"]) {
        NSString *tmp = [command componentsSeparatedByString:@";"][0];
        if ([tmp containsString:@"="]) {
            return [tmp componentsSeparatedByString:@"="][1];
        } else {
            return tmp;
        }
    }
    return @"";
}

- (NSString *)jump {
    if (self.commandType != Command_C) {
        return @"";
    }
    
    NSString *command = self.commands[self.currentIndex];
    if ([command containsString:@";"]) {
        return [command componentsSeparatedByString:@";"][1];
    }
    return @"";
}

@end
