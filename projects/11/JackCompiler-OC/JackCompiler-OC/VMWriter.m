//
//  VMWriter.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/6.
//

#import "VMWriter.h"

@interface VMWriter () {
    NSString *opArray[20];
}
@property (nonatomic) NSMutableString *vmString;
@property (nonatomic) NSString *filePath;
@end

@implementation VMWriter

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.vmString = [NSMutableString string];
        self.filePath = filePath;
        
        opArray[Op_Lt] = @"lt";
        opArray[Op_Eq] = @"eq";
        opArray[Op_Gt] = @"gt";
        opArray[Op_Add] = @"add";
        opArray[Op_Sub] = @"sub";
        opArray[Op_And] = @"and";
        opArray[Op_Or] = @"or";
        opArray[Op_Not] = @"not";
        opArray[Op_Neg] = @"neg";
    }
    return self;
}

- (void)close {
    [self.vmString writeToFile:self.filePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

- (void)writePush:(VM_Segment)segment atIndex:(SInt32)index {
    NSString *string = [self _getSegmentStr:segment];
    [self.vmString appendFormat:@"push %@ %d\n", string, index];
}

- (void)writePop:(VM_Segment)segment atIndex:(SInt32)index {
    NSString *string = [self _getSegmentStr:segment];
    [self.vmString appendFormat:@"pop %@ %d\n", string, index];
}

- (NSString *)_getSegmentStr:(VM_Segment)segment {
    switch (segment) {
        case VM_Segment_Arg:
            return @"argument";
        case VM_Segment_Const:
            return @"constant";
        case VM_Segment_This:
            return @"this";
        case VM_Segment_That:
            return @"that";
        case VM_Segment_Local:
            return @"local";
        case VM_Segment_Temp:
            return @"temp";
        case VM_Segment_Static:
            return @"static";
        case VM_Segment_Pointer:
            return @"pointer";
        default:
            NSAssert(NO, @"invalid segment");
            return @"";
    }
}

- (void)writeArithmetic:(Op)op {
    if (opArray[op] == nil) {
        NSAssert(NO, @"invalid op");
    }
    [self.vmString appendFormat:@"%@\n", opArray[op]];
}

- (void)writeLabel:(NSString *)label {
    [self.vmString appendFormat:@"label %@\n", label];
}

- (void)writeGoto:(NSString *)label {
    [self.vmString appendFormat:@"goto %@\n", label];
}

- (void)writeIf:(NSString *)label {
    [self.vmString appendFormat:@"if-goto %@\n", label];
}

- (void)writeCall:(NSString *)name nArgs:(SInt32)nArgs {
    [self.vmString appendFormat:@"call %@ %d\n", name, nArgs];
}

- (void)writeFunction:(NSString *)name nArgs:(SInt32)nArgs {
    [self.vmString appendFormat:@"function %@ %d\n", name, nArgs];
}

- (void)writeReturn {
    [self.vmString appendFormat:@"return\n"];
}

@end
