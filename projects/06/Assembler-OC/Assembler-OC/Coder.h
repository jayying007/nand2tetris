//
//  Coder.h
//  Assembler-OC
//
//  Created by janezhuang on 2022/1/30.
//

#import <Foundation/Foundation.h>

@interface Coder : NSObject

- (NSString *)destTo3Bits:(NSString *)dest;
- (NSString *)compTo7Bits:(NSString *)comp;
- (NSString *)jumpTo3Bits:(NSString *)jump;

+ (NSString *)intValueTo16Bits:(SInt16)value;

@end
