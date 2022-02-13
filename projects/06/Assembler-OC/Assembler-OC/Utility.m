//
//  Utility.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "Utility.h"

@implementation Utility

+ (BOOL)isNumber:(NSString *)string {
    for (int i = 0; i < string.length; i++) {
        unichar ch = [string characterAtIndex:i];
        if (ch < '0' || ch > '9') {
            return NO;
        }
    }
    return YES;
}
/// 用户定义的符号可以是由字母、数字、下划线、点、美元符号、冒号组成的字符序列，但不能以数字开头
+ (BOOL)isSymbol:(NSString *)string {
    for (int i = 0; i < string.length; i++) {
        unichar ch = [string characterAtIndex:i];
        if ([NSCharacterSet.decimalDigitCharacterSet characterIsMember:ch]) {
            continue;
        }
        if ([NSCharacterSet.letterCharacterSet characterIsMember:ch]) {
            continue;
        }
        if (ch == '_' || ch == '.' || ch == '$' || ch == ':') {
            continue;
        }
        return NO;
    }
    
    unichar ch = [string characterAtIndex:0];
    return [NSCharacterSet.decimalDigitCharacterSet characterIsMember:ch] == NO;
}

/// 过滤单行类型的注释
+ (NSString *)filterNote:(NSString *)command {
    NSString *result = command;
    SInt32 index = -0xffff;
    for (int i = 0; i < command.length; i++) {
        unichar ch = [command characterAtIndex:i];
        if (ch == '/') {
            if (i == index + 1) {
                result = [command substringToIndex:index];
                break;
            }
            index = i;
        }
    }
    return [result stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@end
