//
//  Parser.h
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt32, Command) {
    Command_Arithmetic = 1,
    Command_Push = 2,
    Command_Pop = 3,
    Command_Label = 4,
    Command_Goto = 5,
    Command_If = 6,
    Command_Function = 7,
    Command_Return = 8,
    Command_Call = 9,
};

@interface Parser : NSObject

- (id)initWithVMFilePaths:(NSArray *)vmFilePaths;
- (NSString *)currentFileName;
/// 输入当中是否还有命令
- (BOOL)hasMoreCommands;
/// 读取下一条命令
- (void)advance;

- (Command)commandType;
- (NSString *)arg1;
/// 命令的第二个参数，当命令为push、pop、function、call时有效
- (SInt32)arg2;

@end

