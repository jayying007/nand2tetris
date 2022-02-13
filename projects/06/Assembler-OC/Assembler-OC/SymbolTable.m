//
//  SymbolTable.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import "SymbolTable.h"

@interface SymbolTable ()
@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *table;
@end


@implementation SymbolTable

- (instancetype)init {
    self = [super init];
    if (self) {
        self.table = @{
            @"SP" : @(0),
            @"LCL" : @(1),
            @"ARG" : @(2),
            @"THIS" : @(3),
            @"THAT" : @(4),
            @"R0" : @(0),
            @"R1" : @(1),
            @"R2" : @(2),
            @"R3" : @(3),
            @"R4" : @(4),
            @"R5" : @(5),
            @"R6" : @(6),
            @"R7" : @(7),
            @"R8" : @(8),
            @"R9" : @(9),
            @"R10" : @(10),
            @"R11" : @(11),
            @"R12" : @(12),
            @"R13" : @(13),
            @"R14" : @(14),
            @"R15" : @(15),
            @"SCREEN" : @(0x4000),
            @"KBD" : @(0x6000),
        }.mutableCopy;
    }
    return self;
}

- (void)addEntryWithSymbol:(NSString *)symbol address:(UInt32)address {
    self.table[symbol] = @(address);
}

- (BOOL)containsSymbol:(NSString *)symbol {
    NSNumber *number = [self.table objectForKey:symbol];
    return number != nil;
}

- (UInt32)getAddress:(NSString *)symbol {
    NSNumber *number = [self.table objectForKey:symbol];
    return [number unsignedIntValue];
}

@end
