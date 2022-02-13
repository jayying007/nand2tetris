//
//  VMWriter.h
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(SInt32, VM_Segment) {
    VM_Segment_Const = 1,
    VM_Segment_Arg = 2,
    VM_Segment_Local = 3,
    VM_Segment_Static = 4,
    VM_Segment_This = 5,
    VM_Segment_That = 6,
    VM_Segment_Pointer = 7,
    VM_Segment_Temp = 8
};

typedef NS_ENUM(SInt32, Op) {
    Op_Lt = 1,
    Op_Eq = 2,
    Op_Gt = 3,
    Op_Add = 4,
    Op_Sub = 5,
    Op_And = 6,
    Op_Or = 7,
    Op_Not = 8,
    Op_Neg = 9
};

@interface VMWriter : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;
- (void)close;

- (void)writePush:(VM_Segment)segment atIndex:(SInt32)index;
- (void)writePop:(VM_Segment)segment atIndex:(SInt32)index;
- (void)writeArithmetic:(Op)op;
- (void)writeLabel:(NSString *)label;
- (void)writeGoto:(NSString *)label;
- (void)writeIf:(NSString *)label;
- (void)writeCall:(NSString *)name nArgs:(SInt32)nArgs;
- (void)writeFunction:(NSString *)name nArgs:(SInt32)nArgs;
- (void)writeReturn;

@end

NS_ASSUME_NONNULL_END
