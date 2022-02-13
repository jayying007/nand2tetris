//
//  VM.h
//  VM-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VM : NSObject

- (id)initWithVMFilePaths:(NSArray *)vmFilePaths asmFilePath:(NSString *)asmFilePath;
- (void)startTranslate:(void(^)(BOOL ret))completeHandler;

@property (nonatomic, copy) NSArray *vmFilePaths;
@property (nonatomic, copy) NSString *asmFilePath;

@end

NS_ASSUME_NONNULL_END
