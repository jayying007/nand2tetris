//
//  SymbolTable.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/6.
//

#import "SymbolTable.h"

UInt32 symbolIndex[5];

@interface Symbol : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic) SymbolKind kind;
@property (nonatomic) UInt32 index; //该类型下第几个
@end
@implementation Symbol
- (id)initWithName:(NSString *)name type:(NSString *)type kind:(SymbolKind)kind {
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
        self.kind = kind;
        self.index = symbolIndex[kind];
    }
    return self;
}

- (BOOL)isEqual:(Symbol *)symbol {
    if (self == symbol) {
        return YES;
    }
    return [self.name isEqualToString:symbol.name];
}
@end


@interface SymbolTable ()
@property (nonatomic) NSMutableArray<NSMutableDictionary *> *symbolArray;
@end

@implementation SymbolTable

- (id)init {
    self = [super init];
    if (self) {
        self.symbolArray = [NSMutableArray arrayWithCapacity:5];
        for (int i = 0; i <= 4; i++) {
            self.symbolArray[i] = @{}.mutableCopy;
            symbolIndex[SymbolKind_Field] = 0;
            symbolIndex[SymbolKind_Static] = 0;
        }
    }
    return self;
}

- (void)startSubroutine {
    self.symbolArray[SymbolKind_Arg] = @{}.mutableCopy;
    symbolIndex[SymbolKind_Arg] = 0;
    
    self.symbolArray[SymbolKind_Var] = @{}.mutableCopy;
    symbolIndex[SymbolKind_Var] = 0;
}

- (void)defineSymbol:(NSString *)name type:(NSString *)type kind:(SymbolKind)kind {
    NSMutableDictionary *dict = self.symbolArray[kind];
    if (dict == nil) {
        NSAssert(NO, @"unknown symbol kind:%d", kind);
        return;
    }
    
    if ([dict objectForKey:name] != nil) {
        NSAssert(NO, @"duplicate define symbol:%@", name);
        return;
    }
    
    Symbol *symbol = [[Symbol alloc] initWithName:name type:type kind:kind];
    symbolIndex[kind]++;
    dict[name] = symbol;
}

- (UInt32)varCountForKind:(SymbolKind)kind {
    return symbolIndex[kind];
}

- (SymbolKind)kindOfSymbol:(NSString *)name {
    NSMutableDictionary *dict = self.symbolArray[SymbolKind_Var];
    if ([dict objectForKey:name] != nil) {
        return SymbolKind_Var;
    }
    
    dict = self.symbolArray[SymbolKind_Arg];
    if ([dict objectForKey:name] != nil) {
        return SymbolKind_Arg;
    }
    
    dict = self.symbolArray[SymbolKind_Field];
    if ([dict objectForKey:name] != nil) {
        return SymbolKind_Field;
    }
    
    dict = self.symbolArray[SymbolKind_Static];
    if ([dict objectForKey:name] != nil) {
        return SymbolKind_Static;
    }
    
    return SymbolKind_Unknown;
}

- (NSString *)typeOfSymbol:(NSString *)name {
    SymbolKind kind = [self kindOfSymbol:name];
    NSMutableDictionary *dict = self.symbolArray[kind];
    Symbol *symbol = dict[name];
    
    return symbol.type;
}

- (UInt32)indexOfSymbol:(NSString *)name {
    SymbolKind kind = [self kindOfSymbol:name];
    NSMutableDictionary *dict = self.symbolArray[kind];
    Symbol *symbol = dict[name];
    
    return symbol.index;
}
@end
