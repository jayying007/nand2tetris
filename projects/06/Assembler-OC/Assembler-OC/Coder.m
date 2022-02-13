//
//  Coder.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "Coder.h"

@interface Coder ()
@property (nonatomic) NSDictionary *destDict;
@property (nonatomic) NSDictionary *compDict;
@property (nonatomic) NSDictionary *jumpDict;
@end


@implementation Coder

- (id)init {
    self = [super init];
    if (self) {
        self.destDict = @{
            @""    : @"000",
            @"M"   : @"001",
            @"D"   : @"010",
            @"MD"  : @"011",
            @"A"   : @"100",
            @"AM"  : @"101",
            @"AD"  : @"110",
            @"AMD" : @"111",
        };
        self.compDict = @{
            @"0" : @"0101010",
            @"1" : @"0111111",
            @"-1" : @"0111010",
            @"D" : @"0001100",
            @"A" : @"0110000",
            @"!D" : @"0001101",
            @"!A" : @"0110001",
            @"-D" : @"0001111",
            @"-A" : @"0110011",
            @"D+1" : @"0011111",
            @"A+1" : @"0110111",
            @"D-1" : @"0001110",
            @"A-1" : @"0110010",
            @"D+A" : @"0000010",
            @"D-A" : @"0010011",
            @"A-D" : @"0000111",
            @"D&A" : @"0000000",
            @"D|A" : @"0010101",
            @"M" : @"1110000",
            @"!M" : @"1110001",
            @"-M" : @"1110011",
            @"M+1" : @"1110111",
            @"M-1" : @"1110010",
            @"D+M" : @"1000010",
            @"D-M" : @"1010011",
            @"M-D" : @"1000111",
            @"D&M" : @"1000000",
            @"D|M" : @"1010101",
        };
        self.jumpDict = @{
            @""    : @"000",
            @"JGT"   : @"001",
            @"JEQ"   : @"010",
            @"JGE"  : @"011",
            @"JLT"   : @"100",
            @"JNE"  : @"101",
            @"JLE"  : @"110",
            @"JMP" : @"111",
        };
    }
    return self;
}

- (NSString *)destTo3Bits:(NSString *)dest {
    if ([self.destDict objectForKey:dest]) {
        return self.destDict[dest];
    }
    return @"000";
}

- (NSString *)compTo7Bits:(NSString *)comp {
    if ([self.compDict objectForKey:comp]) {
        return self.compDict[comp];
    }
    return @"0000000";
}

- (NSString *)jumpTo3Bits:(NSString *)jump {
    if ([self.jumpDict objectForKey:jump]) {
        return self.jumpDict[jump];
    }
    return @"000";
}

+ (NSString *)intValueTo16Bits:(SInt16)value {
    NSMutableString *string = [NSMutableString string];
    //符号位
    if (value >= 0) {
        [string appendString:@"0"];
    } else {
        [string appendString:@"1"];
    }
    //避免逻辑右移和算术右移的问题
    for (int i = 14; i >= 0; i--) {
        [string appendFormat:@"%d", (value >> i) & 1];
    }
    return [string copy];
}
@end
