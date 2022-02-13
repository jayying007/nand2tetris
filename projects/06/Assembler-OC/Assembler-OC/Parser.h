//
//  Parser.h
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/29.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt32, Command) {
    Command_A = 1,
    Command_C = 2,
    Command_L = 3,
};

@interface Parser : NSObject

- (id)initWithFilePath:(NSString *)filePath;

- (BOOL)hasMoreCommands;
/// 读取下一条命令
- (void)advance;
- (Command)commandType;

- (NSString *)symbol;
- (NSString *)dest;
- (NSString *)comp;
- (NSString *)jump;

@end

