//
//  CodeWriter.h
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeWriter : NSObject

- (id)initWithPath:(NSString *)filePath;
- (void)close;
/// 引导代码，必须放在文件开头，保证最先执行，然后再调用到我们的Sys.init方法
- (void)writeInit;
- (void)writeArithmetic:(NSString *)command;
- (void)writePushWithSegment:(NSString *)segment atIndex:(SInt32)index;
- (void)writePopWithSegment:(NSString *)segment atIndex:(SInt32)index;
- (void)writeLabel:(NSString *)label;
- (void)writeGoto:(NSString *)label;
- (void)writeIf:(NSString *)label;
- (void)writeCall:(NSString *)functionName numArgs:(SInt32)numArgs;
- (void)writeReturn;
- (void)writeFunction:(NSString *)functionName numLocals:(SInt32)numLocals;

/// 当前解析的是哪个VM文件
@property (nonatomic, copy) NSString *fileName;
/// 编码输出路径
@property (nonatomic, copy) NSString *filePath;

@end

NS_ASSUME_NONNULL_END
