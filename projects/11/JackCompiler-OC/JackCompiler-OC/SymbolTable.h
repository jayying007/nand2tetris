//
//  SymbolTable.h
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/6.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(SInt32, SymbolKind) {
    SymbolKind_Unknown = 0,
    SymbolKind_Static = 1,
    SymbolKind_Field = 2,
    SymbolKind_Arg = 3,
    SymbolKind_Var = 4
};

@interface SymbolTable : NSObject

/// 进入新的方法，重置局部符号表
- (void)startSubroutine;
- (void)defineSymbol:(NSString *)name type:(NSString *)type kind:(SymbolKind)kind;
- (UInt32)varCountForKind:(SymbolKind)kind;

/// 符号的类型，比如为对象的变量or方法的变量，同时有定义时，根据就近原则
/// @param name 符号名
- (SymbolKind)kindOfSymbol:(NSString *)name;
- (NSString *)typeOfSymbol:(NSString *)name;
- (UInt32)indexOfSymbol:(NSString *)name;

@end

