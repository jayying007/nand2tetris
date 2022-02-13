//
//  JackTokenizer.h
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import <Foundation/Foundation.h>
#import "Token.h"

/// Jack语言的词法分析器
@interface JackTokenizer : NSObject

- (id)initWithFilePath:(NSString *)filePath;

- (BOOL)hasMoreTokens;
/// 后退一步
- (Token *)preToken;
/// 当前位置
- (Token *)currentToken;
/// 前进一步
- (Token *)nextToken;

@end
