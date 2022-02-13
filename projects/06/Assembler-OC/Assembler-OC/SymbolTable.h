//
//  SymbolTable.h
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

@interface SymbolTable : NSObject

- (void)addEntryWithSymbol:(NSString *)symbol address:(UInt32)address;
- (BOOL)containsSymbol:(NSString *)symbol;
- (UInt32)getAddress:(NSString *)symbol;

@end
