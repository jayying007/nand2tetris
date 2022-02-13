//
//  main.m
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>
#import "VM.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"usage: ./xxx/VM.o ./xxx/filepath.vm");
            NSLog(@"       ./xxx/VM.o ./xxx/vm_files_directory");
            return 0;
        }
        //检查是文件夹还是单个文件
        NSString *vmFilePath = [NSString stringWithUTF8String:argv[1]];
//        NSString *vmFilePath = @"/Users/jane/Desktop/project/nand2tetris/projects/08/FunctionCalls/FibonacciElement";
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDirectory;
        if ([fm fileExistsAtPath:vmFilePath isDirectory:&isDirectory] == NO) {
            NSLog(@"filepath no exist");
            return 0;
        }
        //获取输入、输出路径
        NSArray *vmFilePaths;
        NSString *asmFilePath;
        if (isDirectory) {
            NSArray *filePaths = [fm contentsOfDirectoryAtPath:vmFilePath error:nil];
            NSMutableArray *array = @[].mutableCopy;
            for (NSString *filePath in filePaths) {
                if ([[filePath pathExtension] isEqualToString:@"vm"]) {
                    [array addObject:[vmFilePath stringByAppendingPathComponent:filePath]];
                }
            }
            vmFilePaths = [array copy];
            NSString *fileName = [[vmFilePath lastPathComponent] stringByAppendingPathExtension:@"asm"];
            asmFilePath = [vmFilePath stringByAppendingPathComponent:fileName];
        } else {
            vmFilePaths = @[ vmFilePath ];
            asmFilePath = [[vmFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"asm"];
        }
        //开始翻译
        NSLog(@"asmFilePath: %@", asmFilePath);
        NSLog(@"vmFilePaths: %@", vmFilePaths);
        VM *vm = [[VM alloc] initWithVMFilePaths:vmFilePaths asmFilePath:asmFilePath];
        [vm startTranslate:^(BOOL ret) {
            printf("translate result:%d\n", ret);
        }];
    }
    return 0;
}
