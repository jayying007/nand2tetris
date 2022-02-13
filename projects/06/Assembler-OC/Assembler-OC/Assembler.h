//
//  Assembler.h
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/29.
//

#import <Foundation/Foundation.h>

@interface Assembler : NSObject

- (id)initWithAsmFilePath:(NSString *)asmFilePath hackFilePath:(NSString *)hackFilePath;

- (void)startTranslate:(void(^)(BOOL ret))completeHandler;

@property (nonatomic, copy) NSString *asmFilePath;
@property (nonatomic, copy) NSString *hackFilePath;

@end

