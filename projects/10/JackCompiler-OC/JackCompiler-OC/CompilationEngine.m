//
//  CompilationEngine.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import "CompilationEngine.h"
#import "JackTokenizer.h"

@interface CompilationEngine ()
@property (nonatomic) NSMutableString *xmlString;
@property (nonatomic) JackTokenizer *tokenizer;
@property (nonatomic) UInt32 nestLevel; // xml嵌套的层数
@end

@implementation CompilationEngine

- (id)initWithJackFilePath:(NSString *)jackFilePath xmlFilePath:(NSString *)xmlFilePath {
    self = [super init];
    if (self) {
        self.xmlString = [NSMutableString string];
        self.jackFilePath = jackFilePath;
        self.xmlFilePath = xmlFilePath;
        self.tokenizer = [[JackTokenizer alloc] initWithFilePath:self.jackFilePath];
        self.nestLevel = 0;
    }
    return self;
}
// 这里为了方便起见，假定输入的代码都是符合规范的
// 每一个compile方法遵循一个原则：进入方法时，处于上一个编译模块的结尾；离开方法时，处于当前编译模块的结尾
- (void)compileClass {
    [self _addXmlBeginNode:@"class"];
    //class关键字
    [self _tryAddKeyword:@"class"];
    //类名
    [self _tryAddIdentifier];
    //左大括号
    [self _tryAddSymbol:@"{"];
    //类变量or类方法or对象方法or对象变量
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        if (token.type == TokenType_Keyword) {
            [self.tokenizer preToken];
            if (token.keyword == Keyword_Static || token.keyword == Keyword_Field) {
                [self compileClassVarDec];
            }
            else if (token.keyword == Keyword_Constructor || token.keyword == Keyword_Method || token.keyword == Keyword_Function) {
                [self compileSubroutine];
            }
            else {
                NSLog(@"error: none of keyword static,field,constructor,method,function found here");
                exit(0);
            }
        } else {
            [self _addSymbol:@"}"];
            break;
        }
    }
    [self _addXmlEndNode:@"class"];
    [self.xmlString writeToFile:self.xmlFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

- (void)compileClassVarDec {
    [self _addXmlBeginNode:@"classVarDec"];
    //static或field关键字
    Token *token = [self.tokenizer nextToken];
    if (token.keyword == Keyword_Static) {
        [self _addKeyword:@"static"];
    } else if (token.keyword == Keyword_Field) {
        [self _addKeyword:@"field"];
    }
    
    //type
    [self _tryAddVarType];
    
    //varName
    [self _tryAddIdentifier];
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        NSAssert(token.type == TokenType_Symbol, @"expect symbol");
        if ([token.symbol isEqualToString:@";"]) {
            //结束符
            [self _addSymbol:@";"];
            break;
        } else if ([token.symbol isEqualToString:@","]) {
            [self _addSymbol:@","];
            [self _tryAddIdentifier];
        } else {
            NSLog(@"none of symbol ',' or ';' found here");
            exit(0);
        }
    }

    [self _addXmlEndNode:@"classVarDec"];
}

- (void)compileSubroutine {
    [self _addXmlBeginNode:@"subroutineDec"];
    //函数关键词
    Token *token = [self.tokenizer nextToken];
    if (token.keyword == Keyword_Constructor) {
        [self _addKeyword:@"constructor"];
    } else if (token.keyword == Keyword_Method) {
        [self _addKeyword:@"method"];
    } else if (token.keyword == Keyword_Function) {
        [self _addKeyword:@"function"];
    }
    //函数类型
    [self _tryAddVarType];
    //函数名
    [self _tryAddIdentifier];
    //参数列表
    [self compileParameterList];
    
    [self _addXmlBeginNode:@"subroutineBody"];
    [self _tryAddSymbol:@"{"];
    while ([self.tokenizer hasMoreTokens]) {
        token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if ([token isKeyword:Keyword_Var]) {
            [self compileVarDec]; //Jack语言局部变量的定义只能写在方法最前面
        } else {
            break;
        }
    }
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    [self _addXmlEndNode:@"subroutineBody"];
    [self _addXmlEndNode:@"subroutineDec"];
}

- (void)compileParameterList {
    [self _tryAddSymbol:@"("];
    [self _addXmlBeginNode:@"parameterList"];
    Token *token = [self.tokenizer nextToken];
    if ([token isSymbol:@")"] == NO) {
        [self _addVarType];
        [self _tryAddIdentifier];
        while ([self.tokenizer hasMoreTokens]) {
            token = [self.tokenizer nextToken];
            if ([token isSymbol:@","]) {
                [self _addSymbol:@","];
                [self _tryAddVarType];
                [self _tryAddIdentifier];
            } else {
                break;
            }
        }
    }
    [self _addXmlEndNode:@"parameterList"];
    [self _addSymbol:@")"];
}

- (void)compileVarDec {
    [self _addXmlBeginNode:@"varDec"];
    [self _tryAddKeyword:@"var"];
    [self _tryAddVarType];
    [self _tryAddIdentifier];
    
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        if ([token isSymbol:@","]) {
            [self _addSymbol:@","];
            [self _tryAddIdentifier];
        } else if ([token isSymbol:@";"]) {
            [self _addSymbol:@";"];
            break;
        } else {
            assert(NO);
        }
    }
    
    [self _addXmlEndNode:@"varDec"];
}

- (void)compileStatements {
    [self _addXmlBeginNode:@"statements"];
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        
        if (token.type != TokenType_Keyword) {
            break;
        }
        if (token.keyword == Keyword_Let) {
            [self compileLet];
        } else if (token.keyword == Keyword_If) {
            [self compileIf];
        } else if (token.keyword == Keyword_While) {
            [self compileWhile];
        } else if (token.keyword == Keyword_Do) {
            [self compileDo];
        } else if (token.keyword == Keyword_Return) {
            [self compileReturn];
        }
    }
    [self _addXmlEndNode:@"statements"];
}

- (void)compileDo {
    [self _addXmlBeginNode:@"doStatement"];
    
    [self _tryAddKeyword:@"do"];
    [self _compileSubroutineCall];
    [self _tryAddSymbol:@";"];
    
    [self _addXmlEndNode:@"doStatement"];
}
/*
 SubroutineCall有两种方式：
 1.  function(arg1, arg2);
 2.  className.function(arg1);
 */
//subroutineCall: subroutineName'('expressionList')' | (className | varName)'.'subroutineName'('expressionList')'
- (void)_compileSubroutineCall {
    [self.tokenizer nextToken];
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token isSymbol:@"("]) {
        [self _addIdentifier];
        [self _tryAddSymbol:@"("];
        [self compileExpressionList];
        [self _tryAddSymbol:@")"];
    } else if ([token isSymbol:@"."]) {
        [self _addIdentifier];
        [self _tryAddSymbol:@"."];
        [self _tryAddIdentifier];
        [self _tryAddSymbol:@"("];
        [self compileExpressionList];
        [self _tryAddSymbol:@")"];
    }
}

- (void)compileLet {
    [self _addXmlBeginNode:@"letStatement"];
    
    [self _tryAddKeyword:@"let"];
    [self _tryAddIdentifier];
    
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token isSymbol:@"["]) {
        [self _tryAddSymbol:@"["];
        [self compileExpression];
        [self _tryAddSymbol:@"]"];
    }
    [self _tryAddSymbol:@"="];
    [self compileExpression];
    [self _tryAddSymbol:@";"];

    [self _addXmlEndNode:@"letStatement"];
}

- (void)compileWhile {
    [self _addXmlBeginNode:@"whileStatement"];
    
    [self _tryAddKeyword:@"while"];
    [self _tryAddSymbol:@"("];
    [self compileExpression];
    [self _tryAddSymbol:@")"];
    
    [self _tryAddSymbol:@"{"];
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    
    [self _addXmlEndNode:@"whileStatement"];
}

- (void)compileReturn {
    [self _addXmlBeginNode:@"returnStatement"];
    
    [self _tryAddKeyword:@"return"];
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token.symbol isEqualToString:@";"] == NO) {
        [self compileExpression];
    }
    [self _tryAddSymbol:@";"];
    [self _addXmlEndNode:@"returnStatement"];
}

- (void)compileIf {
    [self _addXmlBeginNode:@"ifStatement"];
    
    [self _tryAddKeyword:@"if"];
    [self _tryAddSymbol:@"("];
    [self compileExpression];
    [self _tryAddSymbol:@")"];
    
    [self _tryAddSymbol:@"{"];
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if (token.type == TokenType_Keyword && token.keyword == Keyword_Else) {
        [self _tryAddKeyword:@"else"];
        [self _tryAddSymbol:@"{"];
        [self compileStatements];
        [self _tryAddSymbol:@"}"];
    }
    [self _addXmlEndNode:@"ifStatement"];
}
// expression: term (op term)*
- (void)compileExpression {
    [self _addXmlBeginNode:@"expression"];
    
    [self compileTerm];
    while (true) {
        Token *token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if (token.type == TokenType_Symbol && [self isOp:token.symbol]) {
            [self _tryAddSymbol:token.symbol];
            [self compileTerm];
        } else {
            break;
        }
    }

    [self _addXmlEndNode:@"expression"];
}
// term: integerConstant | stringConstant | keywordConstant | varName | varName'['expression']' |
//       subroutineCall | '('expression')' | unaryOp term
- (void)compileTerm {
    [self _addXmlBeginNode:@"term"];
    
    Token *token = [self.tokenizer nextToken];
    //integerConstant
    if (token.type == TokenType_Int_Const) {
        [self.xmlString appendFormat:@"%@<integerConstant> %d </integerConstant>\n", self.spaceString, token.intVal];
    }
    //stringConstant
    else if (token.type == TokenType_String_Const) {
        [self.xmlString appendFormat:@"%@<stringConstant> %@ </stringConstant>\n", self.spaceString, token.stringVal];
    }
    //keywordConstant
    else if (token.type == TokenType_Keyword) {
        NSAssert([self isKeywordConstant:token.keyword], @"should be keywordConstant");
        [self _addKeyword];
    }
    //'('expression')'
    else if ([token.symbol isEqualToString:@"("]) {
        [self _addSymbol:@"("];
        [self compileExpression];
        [self _tryAddSymbol:@")"];
    }
    //unaryOp term
    else if ([self isUnaryOp:token.symbol]) {
        [self _addSymbol];
        [self compileTerm];
    } else {
        //varName'['expression']'
        token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if ([token.symbol isEqualToString:@"["]) {
            [self _addIdentifier];
            [self _tryAddSymbol:@"["];
            [self compileExpression];
            [self _tryAddSymbol:@"]"];
        }
        //subroutineCall
        else if ([token.symbol isEqualToString:@"("] || [token.symbol isEqualToString:@"."]) {
            [self.tokenizer preToken];
            [self _compileSubroutineCall];
        }
        //varName
        else {
            [self _addIdentifier];
        }
    }
    
    [self _addXmlEndNode:@"term"];
}
// expressionList: (expression(',' expression)*)?
- (void)compileExpressionList {
    [self _addXmlBeginNode:@"expressionList"];
    
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token.symbol isEqualToString:@")"] == NO) {
        [self compileExpression];
        while ([self.tokenizer hasMoreTokens]) {
            token = [self.tokenizer nextToken];
            [self.tokenizer preToken];
            if ([token.symbol isEqualToString:@","]) {
                [self _tryAddSymbol:@","];
                [self compileExpression];
            } else {
                break;
            }
        }
    }
    
    [self _addXmlEndNode:@"expressionList"];
}
#pragma mark -
- (NSString *)spaceString {
    NSMutableString *string = @"".mutableCopy;
    for (int i = 0; i < self.nestLevel; i++) {
        [string appendString:@"  "];
    }
    return [string copy];
}

- (void)_addXmlBeginNode:(NSString *)name {
    [self.xmlString appendFormat:@"%@<%@>\n", self.spaceString, name];
    self.nestLevel++;
}

- (void)_addXmlEndNode:(NSString *)name {
    self.nestLevel--;
    [self.xmlString appendFormat:@"%@</%@>\n", self.spaceString, name];
}

- (void)_addKeyword {
    Token *token = [self.tokenizer currentToken];
    [self _addKeyword:token.keywordVal];
}

- (void)_addKeyword:(NSString *)keyword {
    Token *token = [self.tokenizer currentToken];
    if (token.type != TokenType_Keyword) {
        NSLog(@"error: expect keyword here");
        exit(0);
    }
    if ([token.keywordVal isEqualToString:keyword] == NO) {
        NSLog(@"error: expect keyword %@, found %@", keyword, token.keywordVal);
        exit(0);
    }
    [self.xmlString appendFormat:@"%@<keyword> %@ </keyword>\n", self.spaceString, token.keywordVal];
}

- (void)_tryAddKeyword:(NSString *)keyword {
    Token *token = [self.tokenizer nextToken];
    if (token.type != TokenType_Keyword) {
        NSLog(@"error: expect keyword here");
        exit(0);
    }
    if ([token.keywordVal isEqualToString:keyword] == NO) {
        NSLog(@"error: expect keyword %@, found %@", keyword, token.keywordVal);
        exit(0);
    }
    [self.xmlString appendFormat:@"%@<keyword> %@ </keyword>\n", self.spaceString, token.keywordVal];
}

- (void)_addIdentifier {
    Token *token = [self.tokenizer currentToken];
    NSAssert(token.type == TokenType_Identifier, @"error: expect identifier");
    [self.xmlString appendFormat:@"%@<identifier> %@ </identifier>\n", self.spaceString, token.identifier];
}

- (void)_tryAddIdentifier {
    Token *token = [self.tokenizer nextToken];
    NSAssert(token.type == TokenType_Identifier, @"error: expect identifier");
    [self.xmlString appendFormat:@"%@<identifier> %@ </identifier>\n", self.spaceString, token.identifier];
}

- (void)_addSymbol {
    Token *token = [self.tokenizer currentToken];
    [self _addSymbol:token.symbol];
}

- (void)_addSymbol:(NSString *)symbol {
    Token *token = [self.tokenizer currentToken];
    if (token.type != TokenType_Symbol) {
        NSLog(@"error: expect symbol here");
        exit(0);
    }
    if ([token.symbol isEqualToString:symbol] == NO) {
        NSLog(@"error: expect symbol %@, found %@", symbol, token.symbol);
        exit(0);
    }
    
    if ([token.symbol isEqualToString:@"<"]) {
        [self.xmlString appendFormat:@"%@<symbol> &lt; </symbol>\n", self.spaceString];
    } else if ([token.symbol isEqualToString:@"&"]) {
        [self.xmlString appendFormat:@"%@<symbol> &amp; </symbol>\n", self.spaceString];
    } else if ([token.symbol isEqualToString:@">"]) {
        [self.xmlString appendFormat:@"%@<symbol> &gt; </symbol>\n", self.spaceString];
    } else {
        [self.xmlString appendFormat:@"%@<symbol> %@ </symbol>\n", self.spaceString, token.symbol];
    }
}

- (void)_tryAddSymbol:(NSString *)symbol {
    Token *token = [self.tokenizer nextToken];
    if (token.type != TokenType_Symbol) {
        NSLog(@"error: expect symbol here");
        exit(0);
    }
    if ([token.symbol isEqualToString:symbol] == NO) {
        NSLog(@"error: expect symbol %@, found %@", symbol, token.symbol);
        exit(0);
    }
    
    if ([token.symbol isEqualToString:@"<"]) {
        [self.xmlString appendFormat:@"%@<symbol> &lt; </symbol>\n", self.spaceString];
    } else if ([token.symbol isEqualToString:@"&"]) {
        [self.xmlString appendFormat:@"%@<symbol> &amp; </symbol>\n", self.spaceString];
    } else if ([token.symbol isEqualToString:@">"]) {
        [self.xmlString appendFormat:@"%@<symbol> &gt; </symbol>\n", self.spaceString];
    } else {
        [self.xmlString appendFormat:@"%@<symbol> %@ </symbol>\n", self.spaceString, token.symbol];
    }
}
    
- (void)_addVarType {
    Token *token = [self.tokenizer currentToken];
    if (token.type == TokenType_Keyword) {
        [self _addKeyword];
    } else if (token.type == TokenType_Identifier) {
        [self _addIdentifier];
    } else {
        NSLog(@"error: expect var type");
        exit(0);
    }
}
//1.数据类型为基本数据类型
//2.数据类型为类名
- (void)_tryAddVarType {
    Token *token = [self.tokenizer nextToken];
    if (token.type == TokenType_Keyword) {
        [self _addKeyword];
    } else if (token.type == TokenType_Identifier) {
        [self _addIdentifier];
    } else {
        NSLog(@"error: expect var type");
        exit(0);
    }
}

- (BOOL)isOp:(NSString *)string {
    static NSString *op = @"+-*/&|<>=";
    return [op containsString:string];
}

- (BOOL)isUnaryOp:(NSString *)string {
    static NSString *unaryOp = @"-~";
    return [unaryOp containsString:string];
}

- (BOOL)isKeywordConstant:(Keyword)keyword {
    if (keyword == Keyword_True) {
        return YES;
    }
    if (keyword == Keyword_False) {
        return YES;
    }
    if (keyword == Keyword_Null) {
        return YES;
    }
    if (keyword == Keyword_This) {
        return YES;
    }
    return NO;
}
@end
