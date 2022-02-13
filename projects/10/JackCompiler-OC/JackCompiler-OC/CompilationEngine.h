//
//  CompilationEngine.h
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CompilationEngine : NSObject

- (id)initWithJackFilePath:(NSString *)jackFilePath xmlFilePath:(NSString *)xmlFilePath;

- (void)compileClass;
- (void)compileClassVarDec;
- (void)compileSubroutine;
- (void)compileParameterList;
- (void)compileVarDec;
- (void)compileStatements;
- (void)compileDo;
- (void)compileLet;
- (void)compileWhile;
- (void)compileReturn;
- (void)compileIf;
- (void)compileExpression;
- (void)compileTerm;
- (void)compileExpressionList;

@property (nonatomic) NSString *jackFilePath;
@property (nonatomic) NSString *xmlFilePath;

@end

NS_ASSUME_NONNULL_END
