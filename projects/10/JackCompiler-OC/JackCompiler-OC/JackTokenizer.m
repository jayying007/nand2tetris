//
//  JackTokenizer.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import "JackTokenizer.h"
#import "Utility.h"

@interface JackTokenizer ()
@property (nonatomic) NSMutableArray<Token *> *tokens;
@property (nonatomic) SInt32 currentIndex;
@property (nonatomic) NSDictionary *keywordDict;
@end

@implementation JackTokenizer

- (id)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.tokens = @[].mutableCopy;
        self.keywordDict = @{
            @"class"        : @(Keyword_Class),
            @"method"       : @(Keyword_Method),
            @"int"          : @(Keyword_Int),
            @"function"     : @(Keyword_Function),
            @"boolean"      : @(Keyword_Boolean),
            @"constructor"  : @(Keyword_Constructor),
            @"char"         : @(Keyword_Char),
            @"void"         : @(Keyword_Void),
            @"var"          : @(Keyword_Var),
            @"static"       : @(Keyword_Static),
            @"field"        : @(Keyword_Field),
            @"let"          : @(Keyword_Let),
            @"do"           : @(Keyword_Do),
            @"if"           : @(Keyword_If),
            @"else"         : @(Keyword_Else),
            @"while"        : @(Keyword_While),
            @"return"       : @(Keyword_Return),
            @"true"         : @(Keyword_True),
            @"false"        : @(Keyword_False),
            @"null"         : @(Keyword_Null),
            @"this"         : @(Keyword_This),
        };
        Utility *util = [Utility new];
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [content enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            NSString *command = [util filterNote:line];
            if (command.length > 0) {
                [self _parserStringToTokens:command];
            }
        }];
        self.currentIndex = -1;
    }
    return self;
}

- (BOOL)hasMoreTokens {
    return self.currentIndex + 1 < self.tokens.count;
}

- (Token *)preToken {
    self.currentIndex--;
    return self.tokens[self.currentIndex];
}

- (Token *)currentToken {
    return self.tokens[self.currentIndex];
}

- (Token *)nextToken {
    self.currentIndex++;
    return self.tokens[self.currentIndex];
}
#pragma mark -
- (void)_parserStringToTokens:(NSString *)string {
    NSCharacterSet *symbolSet = [NSCharacterSet characterSetWithCharactersInString:@"{}()[],.;<>=+-*/&|~"];
    
    for (int pos = 0; pos < string.length; pos++) {
        unichar ch = [string characterAtIndex:pos];
        if ([symbolSet characterIsMember:ch]) {
            Token *token = [[Token alloc] initWithType:TokenType_Symbol value:[string substringWithRange:NSMakeRange(pos, 1)]];
            [self.tokens addObject:token];
            continue;
        }
        if (ch == ' ') {
            continue;
        }
        if (ch == '"') {
            SInt32 startQuote = pos;
            do {
                pos++;
            } while ([string characterAtIndex:pos] != '"');
            SInt32 endQuote = pos;

            Token *token = [[Token alloc] initWithType:TokenType_String_Const value:[string substringWithRange:NSMakeRange(startQuote, endQuote - startQuote + 1)]];
            [self.tokens addObject:token];
            continue;
        }
        if (ch >= '0' && ch <= '9') {
            SInt32 startNum = pos;
            do {
                pos++;
            } while ([string characterAtIndex:pos] >= '0' && [string characterAtIndex:pos] <= '9');
            pos--;
            SInt32 endNum = pos;

            Token *token = [[Token alloc] initWithType:TokenType_Int_Const value:[string substringWithRange:NSMakeRange(startNum, endNum - startNum + 1)]];
            [self.tokens addObject:token];
            continue;
        }
        
        SInt32 startPos = pos;
        do {
            pos++;
        } while ([string characterAtIndex:pos] != ' ' && [symbolSet characterIsMember:[string characterAtIndex:pos]] == NO);
        pos--;
        SInt32 endPos = pos;
        
        NSString *str = [string substringWithRange:NSMakeRange(startPos, endPos - startPos + 1)];
        if ([self.keywordDict objectForKey:str] != nil) {
            Token *token = [[Token alloc] initWithType:TokenType_Keyword value:str];
            token.keyword = (Keyword)[[self.keywordDict objectForKey:str] intValue];
            [self.tokens addObject:token];
        } else {
            Token *token = [[Token alloc] initWithType:TokenType_Identifier value:str];
            [self.tokens addObject:token];
        }
    }
}
@end
