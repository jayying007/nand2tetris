//
//  main.m
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/29.
//

#import <Foundation/Foundation.h>
#import "Assembler.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printf("usage: ./xxx/Assembler ./xxx/filepath.asm\n");
            return 0;
        }
              
        NSString *asmFilePath = [NSString stringWithUTF8String:argv[1]];
        NSString *hackFilePath = [[asmFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"hack"];
        NSLog(@"asmFilePath: %@", asmFilePath);
        NSLog(@"hackFilePath: %@", hackFilePath);
        Assembler *assembler = [[Assembler alloc] initWithAsmFilePath:asmFilePath hackFilePath:hackFilePath];
        [assembler startTranslate:^(BOOL ret) {
            printf("translate result:%d\n", ret);
        }];
    }
    return 0;
}
