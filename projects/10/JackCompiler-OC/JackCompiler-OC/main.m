//
//  main.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import <Foundation/Foundation.h>
#import "CompilationEngine.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"usage: ./xxx/JackCompiler.o ./xxx/filepath.jack");
            NSLog(@"       ./xxx/JackCompiler.o ./xxx/jac_files_directory");
            return 0;
        }
        //检查是文件夹还是单个文件
        NSString *jackFilePath = [NSString stringWithUTF8String:argv[1]];
//        NSString *jackFilePath = @"/Users/jane/Desktop/project/nand2tetris/projects/10/ExpressionLessSquare";
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
                    NSString *xmlFilePath = [jackFilePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@2.xml", [filePath stringByDeletingPathExtension]]];
                    CompilationEngine *engine = [[CompilationEngine alloc] initWithJackFilePath:[jackFilePath stringByAppendingPathComponent:filePath] xmlFilePath:xmlFilePath];
                    NSLog(@"compile: %@", filePath);
                    [engine compileClass];
                }
            }
        } else {
            NSString *xmlFilePath = [[jackFilePath stringByDeletingPathExtension] stringByAppendingFormat:@"2.xml"];
            CompilationEngine *engine = [[CompilationEngine alloc] initWithJackFilePath:jackFilePath xmlFilePath:xmlFilePath];
            NSLog(@"compile: %@", jackFilePath);
            [engine compileClass];
        }
    }
    return 0;
}
