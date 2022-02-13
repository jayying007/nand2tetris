//
//  Utility.m
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "Utility.h"

@implementation Utility

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
