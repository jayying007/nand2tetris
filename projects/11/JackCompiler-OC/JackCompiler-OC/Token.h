//
//  Token.h
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(SInt32, TokenType) {
    TokenType_Keyword = 1,
    TokenType_Symbol = 2,
    TokenType_Identifier = 3,
    TokenType_Int_Const = 4,
    TokenType_String_Const = 5
};

typedef NS_ENUM(SInt32, Keyword) {
    Keyword_Class = 1,
    Keyword_Method = 2,
    Keyword_Int = 3,
    Keyword_Function,
    Keyword_Boolean,
    Keyword_Constructor,
    Keyword_Char,
    Keyword_Void,
    Keyword_Var,
    Keyword_Static,
    Keyword_Field,
    Keyword_Let,
    Keyword_Do,
    Keyword_If,
    Keyword_Else,
    Keyword_While,
    Keyword_Return,
    Keyword_True,
    Keyword_False,
    Keyword_Null,
    Keyword_This
};

@interface Token : NSObject

- (id)initWithType:(TokenType)type value:(NSString *)value;
@property (nonatomic) TokenType type;
@property (nonatomic) NSString *value;
@property (nonatomic) Keyword keyword;

- (NSString *)keywordVal;
- (NSString *)symbol;
- (NSString *)identifier;
- (SInt32)intVal;
- (NSString *)stringVal;

- (BOOL)isSymbol:(NSString *)symbol;
- (BOOL)isKeyword:(Keyword)keyword;

@end
