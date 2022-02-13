//
//  CompilationEngine.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import "CompilationEngine.h"
#import "JackTokenizer.h"
#import "SymbolTable.h"
#import "VMWriter.h"

#define FUNCTION_NAME [NSString stringWithFormat:@"%@.%@", className, functionName]

@interface CompilationEngine () {
    //当前类名
    NSString *className;
    //当前所在方法名
    NSString *functionName;
    //方法与参数个数的映射
    NSMutableDictionary<NSString *, NSNumber *> *functionParamDict;
    //用了多少if了，用来生成唯一的label
    UInt32 ifIndex;
    //用了多少while了，用来生成唯一的label
    UInt32 whileIndex;
    //在method方法内部
    BOOL bInMethod;
}
@property (nonatomic) JackTokenizer *tokenizer;
@property (nonatomic) SymbolTable *symbolTable;
@property (nonatomic) VMWriter *vmWriter;
@end

@implementation CompilationEngine

- (id)initWithJackFilePath:(NSString *)jackFilePath vmFilePath:(NSString *)vmFilePath {
    self = [super init];
    if (self) {
        self.tokenizer = [[JackTokenizer alloc] initWithFilePath:jackFilePath];
        self.vmWriter = [[VMWriter alloc] initWithFilePath:vmFilePath];
        self.symbolTable = [SymbolTable new];
        functionParamDict = @{}.mutableCopy;
    }
    return self;
}
// 每一个compile方法遵循一个原则：进入方法时，处于上一个编译模块的token结尾；离开方法时，处于当前编译模块的token结尾

// 类：'class' className '{' classVarDec* subroutineDec* '}'
- (void)compileClass {
    //class关键字
    [self _tryAddKeyword:@"class"];
    //类名
    className = [[self.tokenizer nextToken] identifier];
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
                [self.symbolTable startSubroutine];
                ifIndex = 0;
                whileIndex = 0;
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
    [self.vmWriter close];
}
// classVarDec: ('static'|'field') type varName (',' varName)* ';'
- (void)compileClassVarDec {
    //static或field关键字
    Token *token1 = [self.tokenizer nextToken];
    //type
    Token *token2 = [self.tokenizer nextToken];
    //varName
    Token *token3 = [self.tokenizer nextToken];
    NSMutableArray *varNames = @[ token3.identifier ].mutableCopy;
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        if ([token isSymbol:@";"]) {
            break;
        } else if ([token isSymbol:@","]) {
            [varNames addObject:[self.tokenizer nextToken].identifier];
        } else {
            NSLog(@"none of symbol ',' or ';' found here");
            exit(0);
        }
    }
    
    NSString *type = @"";
    SymbolKind kind = SymbolKind_Unknown;
    if (token1.keyword == Keyword_Static) {
        kind = SymbolKind_Static;
    } else if (token1.keyword == Keyword_Field) {
        kind = SymbolKind_Field;
    }
    if (token2.type == TokenType_Keyword) {
        type = token2.keywordVal;
    } else if (token2.type == TokenType_Identifier) {
        type = token2.identifier;
    }
    for (NSString *name in varNames) {
        [self.symbolTable defineSymbol:name type:type kind:kind];
    }
}
// subroutineDec: ('constructor'|'function'|'method') ('void'|type) subroutineName '('parameterList')' subroutineBody
// subroutineBody: '{' varDec* statements '}'
- (void)compileSubroutine {
    //函数关键词
    Token *token = [self.tokenizer nextToken];
    //函数类型
    [self _tryAddVarType];
    //函数名
    functionName = [[self.tokenizer nextToken] identifier];
    //参数列表
    [self compileParameterList];
    functionParamDict[FUNCTION_NAME] = @([self.symbolTable varCountForKind:SymbolKind_Arg]);
    //subroutineBody
    [self _tryAddSymbol:@"{"];
    while ([self.tokenizer hasMoreTokens]) {
        Token *token2 = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if ([token2 isKeyword:Keyword_Var]) {
            [self compileVarDec]; //Jack语言局部变量的定义只能写在方法最前面
        } else {
            break;
        }
    }
    
    [self.vmWriter writeFunction:FUNCTION_NAME nArgs:[self.symbolTable varCountForKind:SymbolKind_Var]];
    if (token.keyword == Keyword_Constructor) {
        [self.vmWriter writePush:VM_Segment_Const atIndex:[self.symbolTable varCountForKind:SymbolKind_Field]];
        [self.vmWriter writeCall:@"Memory.alloc" nArgs:1];
        [self.vmWriter writePop:VM_Segment_Pointer atIndex:0];
    } else if (token.keyword == Keyword_Method) {
        //把第一个参数（对象方法是this指针）放到Pointer寄存器上
        [self.vmWriter writePush:VM_Segment_Arg atIndex:0];
        [self.vmWriter writePop:VM_Segment_Pointer atIndex:0];
        bInMethod = YES;
    }
    
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    functionName = @"";
    bInMethod = NO;
}
// parameterList: ((type varName)(',' type VarName)*)?
- (void)compileParameterList {
    [self _tryAddSymbol:@"("];
    Token *token = [self.tokenizer nextToken];
    if ([token isSymbol:@")"] == NO) {
        Token *token2 = [self.tokenizer nextToken];
        if (token.type == TokenType_Keyword) {
            [self.symbolTable defineSymbol:token2.identifier type:token.keywordVal kind:SymbolKind_Arg];
        } else if (token.type == TokenType_Identifier) {
            [self.symbolTable defineSymbol:token2.identifier type:token.identifier kind:SymbolKind_Arg];
        }
        
        while ([self.tokenizer hasMoreTokens]) {
            token = [self.tokenizer nextToken];
            if ([token isSymbol:@","]) {
                [self _addSymbol:@","];
                Token *token3 = [self.tokenizer nextToken];
                Token *token4 = [self.tokenizer nextToken];
                if (token3.type == TokenType_Keyword) {
                    [self.symbolTable defineSymbol:token4.identifier type:token3.keywordVal kind:SymbolKind_Arg];
                } else if (token.type == TokenType_Identifier) {
                    [self.symbolTable defineSymbol:token4.identifier type:token3.identifier kind:SymbolKind_Arg];
                }
            } else {
                break;
            }
        }
    }
    [self _addSymbol:@")"];
}
// varDec: 'var' type varName(',' varName)*';'
- (void)compileVarDec {
    [self _tryAddKeyword:@"var"];
    //varType
    Token *token1 = [self.tokenizer nextToken];
    //varName
    Token *token2 = [self.tokenizer nextToken];
    NSMutableArray *varNames = @[ token2.identifier ].mutableCopy;
    while ([self.tokenizer hasMoreTokens]) {
        Token *token = [self.tokenizer nextToken];
        if ([token isSymbol:@","]) {
            [varNames addObject:[self.tokenizer nextToken].identifier];
        } else if ([token isSymbol:@";"]) {
            break;
        } else {
            assert(NO);
        }
    }
    
    for (NSString *name in varNames) {
        if (token1.type == TokenType_Keyword) {
            [self.symbolTable defineSymbol:name type:token1.keywordVal kind:SymbolKind_Var];
        } else if (token1.type == TokenType_Identifier) {
            [self.symbolTable defineSymbol:name type:token1.identifier kind:SymbolKind_Var];
        }
    }
}

- (void)compileStatements {;
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
}
// doStatement: 'do' subroutineCall';'
- (void)compileDo {
    [self _tryAddKeyword:@"do"];
    [self _compileSubroutineCall:YES];
    [self _tryAddSymbol:@";"];
}
/*
 SubroutineCall有两种方式：
 1.  function(arg1, arg2);
 2.  className.function(arg1);
 */
/*
 subroutineCall: subroutineName'('expressionList')' |
                (className | varName)'.'subroutineName'('expressionList')'
 */
- (void)_compileSubroutineCall:(BOOL)popStack {
    //要看到第二个token才知道是哪种形式
    [self.tokenizer nextToken];
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token isSymbol:@"("]) {
        NSString *subroutineName = [self.tokenizer currentToken].identifier;
        NSString *functionName = [NSString stringWithFormat:@"%@.%@", className, subroutineName];
        
        [self _addIdentifier];
        [self _tryAddSymbol:@"("];
        [self.vmWriter writePush:VM_Segment_Pointer atIndex:0]; //把this指针作为第一个参数
        [self compileExpressionList:functionName];
        [self _tryAddSymbol:@")"];
        [self.vmWriter writeCall:functionName nArgs:functionParamDict[functionName].intValue + 1];
    } else if ([token isSymbol:@"."]) {
        //为className，调用类方法不用传递this指针
        if ([self _isClassName:[self.tokenizer currentToken].identifier]) {
            NSString *className = [self.tokenizer currentToken].identifier;
            [self _addIdentifier];
            [self _tryAddSymbol:@"."];
            [self _tryAddIdentifier];
            NSString *functionName = [NSString stringWithFormat:@"%@.%@", className, [self.tokenizer currentToken].identifier];
            [self _tryAddSymbol:@"("];
            [self compileExpressionList:functionName];
            [self _tryAddSymbol:@")"];
            [self.vmWriter writeCall:functionName nArgs:functionParamDict[functionName].intValue];
        } else {
            NSString *varName = [self.tokenizer currentToken].identifier;
            //push这个对象的指针作为第一参数
            switch ([self.symbolTable kindOfSymbol:varName]) {
                case SymbolKind_Arg:
                    [self.vmWriter writePush:VM_Segment_Arg atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                case SymbolKind_Var:
                    [self.vmWriter writePush:VM_Segment_Local atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                case SymbolKind_Field:
                    [self.vmWriter writePush:VM_Segment_This atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                case SymbolKind_Static:
                    [self.vmWriter writePush:VM_Segment_Static atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                default:
                    break;
            }
            
            [self _addIdentifier];
            [self _tryAddSymbol:@"."];
            [self _tryAddIdentifier];
            NSString *functionName = [NSString stringWithFormat:@"%@.%@", [self.symbolTable typeOfSymbol:varName], [self.tokenizer currentToken].identifier];
            [self _tryAddSymbol:@"("];
            [self compileExpressionList:functionName];
            [self _tryAddSymbol:@")"];
            [self.vmWriter writeCall:functionName nArgs:functionParamDict[functionName].intValue + 1];
        }
    } else {
        assert(NO);
    }
    //栈顶无用的返回值弹走
    if (popStack) {
        [self.vmWriter writePop:VM_Segment_Temp atIndex:0];
    }
}
// letStatement: 'let' varName('['expression']')? '=' expression';'
- (void)compileLet {
    [self _tryAddKeyword:@"let"];
    NSString *varName = [self.tokenizer nextToken].identifier;
    
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token isSymbol:@"["]) {
        [self _tryAddSymbol:@"["];
        [self compileExpression];
        
        [self _writePushVarName:varName];
        [self.vmWriter writeArithmetic:Op_Add];
        
        [self _tryAddSymbol:@"]"];
        [self _tryAddSymbol:@"="];
        [self compileExpression];
        
        [self.vmWriter writePop:VM_Segment_Temp atIndex:0];
        [self.vmWriter writePop:VM_Segment_Pointer atIndex:1];
        [self.vmWriter writePush:VM_Segment_Temp atIndex:0];
        [self.vmWriter writePop:VM_Segment_That atIndex:0];
    } else {
        [self _tryAddSymbol:@"="];
        [self compileExpression];
        
        switch ([self.symbolTable kindOfSymbol:varName]) {
            case SymbolKind_Arg:
                [self.vmWriter writePop:VM_Segment_Arg atIndex:[self.symbolTable indexOfSymbol:varName]];
                break;
            case SymbolKind_Var:
                [self.vmWriter writePop:VM_Segment_Local atIndex:[self.symbolTable indexOfSymbol:varName]];
                break;
            case SymbolKind_Field:
                [self.vmWriter writePop:VM_Segment_This atIndex:[self.symbolTable indexOfSymbol:varName]];
                break;
            case SymbolKind_Static:
                [self.vmWriter writePop:VM_Segment_Static atIndex:[self.symbolTable indexOfSymbol:varName]];
                break;
            default:
                break;
        }
    }
    [self _tryAddSymbol:@";"];
}
// whileStatement: 'while''('expression')' '{' statements '}'
- (void)compileWhile {
    UInt32 index = whileIndex++;
    NSString *loopLabel = [NSString stringWithFormat:@"WHILE_EXP%u", index];
    NSString *endLabel = [NSString stringWithFormat:@"WHILE_END%u", index];
    
    [self _tryAddKeyword:@"while"];
    [self _tryAddSymbol:@"("];
    [self.vmWriter writeLabel:loopLabel];
    [self compileExpression];
    [self.vmWriter writeArithmetic:Op_Not];
    [self.vmWriter writeIf:endLabel];
    [self _tryAddSymbol:@")"];
    
    [self _tryAddSymbol:@"{"];
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    [self.vmWriter writeGoto:loopLabel];
    [self.vmWriter writeLabel:endLabel];
}
// returnStatement 'return' expression?';'
- (void)compileReturn {
    [self _tryAddKeyword:@"return"];
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token.symbol isEqualToString:@";"] == NO) {
        [self compileExpression];
    } else {
        //return时一定要在栈顶有个ret值
        [self.vmWriter writePush:VM_Segment_Const atIndex:0];
    }
    [self.vmWriter writeReturn];
    [self _tryAddSymbol:@";"];
}
// ifStatement 'if''('expression')' '{' statements '}' ('else' '{' statements '}')?
- (void)compileIf {
    UInt32 index = ifIndex++;
    NSString *trueLabel = [NSString stringWithFormat:@"IF_TRUE%u", index];
    NSString *falseLabel = [NSString stringWithFormat:@"IF_FALSE%u", index];
    NSString *endLabel = [NSString stringWithFormat:@"IF_END%u", index];
    
    [self _tryAddKeyword:@"if"];
    [self _tryAddSymbol:@"("];
    [self compileExpression];
    [self.vmWriter writeIf:trueLabel]; //如果栈顶非0，跳转到Label
    [self.vmWriter writeGoto:falseLabel];
    [self _tryAddSymbol:@")"];
    
    [self _tryAddSymbol:@"{"];
    [self.vmWriter writeLabel:trueLabel];
    [self compileStatements];
    [self _tryAddSymbol:@"}"];
    
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if (token.type == TokenType_Keyword && token.keyword == Keyword_Else) {
        [self.vmWriter writeGoto:endLabel];
        [self.vmWriter writeLabel:falseLabel];
        [self _tryAddKeyword:@"else"];
        [self _tryAddSymbol:@"{"];
        [self compileStatements];
        [self _tryAddSymbol:@"}"];
        [self.vmWriter writeLabel:endLabel];
    } else {
        [self.vmWriter writeLabel:falseLabel];
    }
}
// expression: term (op term)*
- (void)compileExpression {
    /**
     没有运算符优先级的判断，比如 age = 1 + 2 * 3 = 9
     */
    [self compileTerm];
    while (true) {
        Token *token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if (token.type == TokenType_Symbol && [self isOp:token.symbol]) {
            [self _tryAddSymbol:token.symbol];
            [self compileTerm];
            if ([token.symbol isEqualToString:@"<"]) {
                [self.vmWriter writeArithmetic:Op_Lt];
            }
            else if ([token.symbol isEqualToString:@">"]) {
                [self.vmWriter writeArithmetic:Op_Gt];
            }
            else if ([token.symbol isEqualToString:@"="]) {
                [self.vmWriter writeArithmetic:Op_Eq];
            }
            else if ([token.symbol isEqualToString:@"&"]) {
                [self.vmWriter writeArithmetic:Op_And];
            }
            else if ([token.symbol isEqualToString:@"|"]) {
                [self.vmWriter writeArithmetic:Op_Or];
            }
            else if ([token.symbol isEqualToString:@"+"]) {
                [self.vmWriter writeArithmetic:Op_Add];
            }
            else if ([token.symbol isEqualToString:@"-"]) {
                [self.vmWriter writeArithmetic:Op_Sub];
            }
            else if ([token.symbol isEqualToString:@"*"]) {
                [self.vmWriter writeCall:@"Math.multiply" nArgs:2];
            }
            else if ([token.symbol isEqualToString:@"/"]) {
                [self.vmWriter writeCall:@"Math.divide" nArgs:2];
            }
        } else {
            break;
        }
    }
}
// term: integerConstant | stringConstant | keywordConstant | varName | varName'['expression']' |
//       subroutineCall | '('expression')' | unaryOp term
- (void)compileTerm {
    Token *token = [self.tokenizer nextToken];
    //integerConstant
    if (token.type == TokenType_Int_Const) {
        [self.vmWriter writePush:VM_Segment_Const atIndex:token.intVal];
    }
    //stringConstant
    else if (token.type == TokenType_String_Const) {
        NSString *string = token.stringVal;
        [self.vmWriter writePush:VM_Segment_Const atIndex:string.length];
        [self.vmWriter writeCall:@"String.new" nArgs:1];
        for (int i = 0; i < string.length; i++) {
            unichar ch = [string characterAtIndex:i];
            [self.vmWriter writePush:VM_Segment_Const atIndex:ch];
            [self.vmWriter writeCall:@"String.appendChar" nArgs:2]; //返回自身指针
        }
    }
    //keywordConstant
    else if (token.type == TokenType_Keyword) {
        NSAssert([self isKeywordConstant:token.keyword], @"should be keywordConstant");
        if (token.keyword == Keyword_True) {
            [self.vmWriter writePush:VM_Segment_Const atIndex:0];
            [self.vmWriter writeArithmetic:Op_Not];
        } else if (token.keyword == Keyword_False || token.keyword == Keyword_Null) {
            [self.vmWriter writePush:VM_Segment_Const atIndex:0];
        } else if (token.keyword == Keyword_This) {
            [self.vmWriter writePush:VM_Segment_Pointer atIndex:0];
        }
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
        if ([token.symbol isEqualToString:@"-"]) {
            [self.vmWriter writeArithmetic:Op_Neg];
        } else if ([token.symbol isEqualToString:@"~"]) {
            [self.vmWriter writeArithmetic:Op_Not];
        }
    } else {
        //varName'['expression']'
        token = [self.tokenizer nextToken];
        [self.tokenizer preToken];
        if ([token.symbol isEqualToString:@"["]) {
            NSString *varName = [self.tokenizer currentToken].identifier;
            [self _addIdentifier];
            [self _tryAddSymbol:@"["];
            [self compileExpression];
            [self _tryAddSymbol:@"]"];
            
            [self _writePushVarName:varName];
            [self.vmWriter writeArithmetic:Op_Add];
            [self.vmWriter writePop:VM_Segment_Pointer atIndex:1];
            [self.vmWriter writePush:VM_Segment_That atIndex:0];
        }
        //subroutineCall
        else if ([token.symbol isEqualToString:@"("] || [token.symbol isEqualToString:@"."]) {
            [self.tokenizer preToken];
            [self _compileSubroutineCall:NO];
        }
        //varName
        else {
            NSString *varName = [self.tokenizer currentToken].identifier;
            [self _addIdentifier];
            switch ([self.symbolTable kindOfSymbol:varName]) {
                case SymbolKind_Arg:
                    if (bInMethod) {
                        [self.vmWriter writePush:VM_Segment_Arg atIndex:[self.symbolTable indexOfSymbol:varName] + 1];
                    } else {
                        [self.vmWriter writePush:VM_Segment_Arg atIndex:[self.symbolTable indexOfSymbol:varName]];
                    }
                    break;
                case SymbolKind_Var:
                    [self.vmWriter writePush:VM_Segment_Local atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                case SymbolKind_Field:
                    [self.vmWriter writePush:VM_Segment_This atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                case SymbolKind_Static:
                    [self.vmWriter writePush:VM_Segment_Static atIndex:[self.symbolTable indexOfSymbol:varName]];
                    break;
                default:
                    break;
            }
        }
    }
}
// expressionList: (expression(',' expression)*)?
- (void)compileExpressionList:(NSString *)functionName {
    int paramCount = 0;
    Token *token = [self.tokenizer nextToken];
    [self.tokenizer preToken];
    if ([token.symbol isEqualToString:@")"] == NO) {
        [self compileExpression];
        paramCount++;
        while ([self.tokenizer hasMoreTokens]) {
            token = [self.tokenizer nextToken];
            [self.tokenizer preToken];
            if ([token.symbol isEqualToString:@","]) {
                [self _tryAddSymbol:@","];
                [self compileExpression];
                paramCount++;
            } else {
                break;
            }
        }
    }
    functionParamDict[functionName] = @(paramCount);
}
#pragma mark -
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
}

- (void)_tryAddKeyword:(NSString *)keyword {
    Token *token = [self.tokenizer nextToken];
    if (token.type != TokenType_Keyword) {
        NSLog(@"error: expect keyword here");
        exit(0);
    }
}

- (void)_addIdentifier {
    Token *token = [self.tokenizer currentToken];
    NSAssert(token.type == TokenType_Identifier, @"error: expect identifier");
}

- (void)_tryAddIdentifier {
    Token *token = [self.tokenizer nextToken];
    NSAssert(token.type == TokenType_Identifier, @"error: expect identifier");
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
}

- (void)_tryAddSymbol:(NSString *)symbol {
    Token *token = [self.tokenizer nextToken];
    if (token.type != TokenType_Symbol) {
        NSLog(@"error: expect symbol here");
        exit(0);
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

- (BOOL)_isClassName:(NSString *)string {
    return [self.symbolTable kindOfSymbol:string] == SymbolKind_Unknown;
}

- (void)_writePushVarName:(NSString *)varName {
    switch ([self.symbolTable kindOfSymbol:varName]) {
        case SymbolKind_Arg:
            [self.vmWriter writePush:VM_Segment_Arg atIndex:[self.symbolTable indexOfSymbol:varName]];
            break;
        case SymbolKind_Var:
            [self.vmWriter writePush:VM_Segment_Local atIndex:[self.symbolTable indexOfSymbol:varName]];
            break;
        case SymbolKind_Field:
            [self.vmWriter writePush:VM_Segment_This atIndex:[self.symbolTable indexOfSymbol:varName]];
            break;
        case SymbolKind_Static:
            [self.vmWriter writePush:VM_Segment_Static atIndex:[self.symbolTable indexOfSymbol:varName]];
            break;
        default:
            break;
    }
}
@end
