//
//  main.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/6.
//

#import <Foundation/Foundation.h>
#import "CompilationEngine.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"usage: ./xxx/JackCompiler.o ./xxx/filepath.jack");
            NSLog(@"       ./xxx/JackCompiler.o ./xxx/jack_files_directory");
            return 0;
        }
        //检查是文件夹还是单个文件
        NSString *jackFilePath = [NSString stringWithUTF8String:argv[1]];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDirectory;
        if ([fm fileExistsAtPath:jackFilePath isDirectory:&isDirectory] == NO) {
            NSLog(@"filepath no exist");
            return 0;
        }

        if (isDirectory) {
            NSArray *filePaths = [fm contentsOfDirectoryAtPath:jackFilePath error:nil];
            for (NSString *filePath in filePaths) {
                if ([[filePath pathExtension] isEqualToString:@"jack"]) {
                    NSString *vmFilePath = [jackFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.vm", [filePath stringByDeletingPathExtension]]];
                    CompilationEngine *engine = [[CompilationEngine alloc] initWithJackFilePath:[jackFilePath stringByAppendingPathComponent:filePath] vmFilePath:vmFilePath];
                    NSLog(@"compile: %@", filePath);
                    [engine compileClass];
                }
            }
        } else {
            NSString *vmFilePath = [[jackFilePath stringByDeletingPathExtension] stringByAppendingFormat:@".vm"];
            CompilationEngine *engine = [[CompilationEngine alloc] initWithJackFilePath:jackFilePath vmFilePath:vmFilePath];
            NSLog(@"compile: %@", jackFilePath);
            [engine compileClass];
        }
    }
    return 0;
}
