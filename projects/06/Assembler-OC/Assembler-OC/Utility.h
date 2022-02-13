//
//  Utility.h
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (BOOL)isNumber:(NSString *)string;
/// 用户定义的符号可以是由字母、数字、下划线、点、美元符号、冒号组成的字符序列，但不能以数字开头
+ (BOOL)isSymbol:(NSString *)string;

+ (NSString *)filterNote:(NSString *)command;

@end

