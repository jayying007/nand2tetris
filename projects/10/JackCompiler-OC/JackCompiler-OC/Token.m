//
//  Token.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import "Token.h"

@interface Token ()

@end

@implementation Token

- (id)initWithType:(TokenType)type value:(NSString *)value {
    self = [super init];
    if (self) {
        self.type = type;
        self.value = [value copy];
        
    }
    return self;
}

- (NSString *)keywordVal {
    return self.value;
}

- (NSString *)symbol {
    return self.value;
}

- (NSString *)identifier {
    return self.value;
}

- (SInt32)intVal {
    return [self.value intValue];
}

- (NSString *)stringVal {
    //去除双引号
    return [self.value substringWithRange:NSMakeRange(1, self.value.length - 2)];
}

- (BOOL)isSymbol:(NSString *)symbol {
    return self.type == TokenType_Symbol && [self.symbol isEqualToString:symbol];
}

- (BOOL)isKeyword:(Keyword)keyword {
    return self.type == TokenType_Keyword && self.keyword == keyword;
}
@end
