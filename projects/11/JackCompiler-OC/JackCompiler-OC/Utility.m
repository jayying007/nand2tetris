//
//  Utility.m
//  JackCompiler-OC
//
//  Created by janezhuang on 2022/2/3.
//

#import "Utility.h"

@interface Utility ()
/// 已读到注释开始的标记 --> /*
@property (nonatomic) BOOL foundDocNoteStart;
@end

@implementation Utility

- (NSString *)filterNote:(NSString *)command {
    return [[self _filterNote:command] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

- (NSString *)_filterNote:(NSString *)command {
    if (self.foundDocNoteStart) {
        NSRange docNoteEndRange = [command rangeOfString:@"*/"];
        if (docNoteEndRange.location == NSNotFound) {
            return @"";
        } else {
            self.foundDocNoteStart = NO;
            return [self _filterNote:[command substringFromIndex:NSMaxRange(docNoteEndRange)]];
        }
    } else {
        NSRange lineNoteRange = [command rangeOfString:@"//"];
        NSRange docNoteStartRange = [command rangeOfString:@"/*"];
        NSRange docNoteEndRange = [command rangeOfString:@"*/"];
        
        if (lineNoteRange.location == NSNotFound && docNoteStartRange.location == NSNotFound) {
            return command;
        }
        else if (lineNoteRange.location == NSNotFound) {
            return [self _filterDocNote:command startRange:docNoteStartRange endRange:docNoteEndRange];
        }
        else if (docNoteStartRange.location == NSNotFound) {
            return [self _filterLineNote:command range:lineNoteRange];
        }
        //两种类型的注释都找到了，选最先的那个
        else {
            if (lineNoteRange.location < docNoteStartRange.location) {
                return [self _filterLineNote:command range:lineNoteRange];
            } else {
                return [self _filterDocNote:command startRange:docNoteStartRange endRange:docNoteEndRange];
            }
        }
    }
}

- (NSString *)_filterLineNote:(NSString *)command range:(NSRange)lineNoteRange {
    return [command substringToIndex:lineNoteRange.location];
}

- (NSString *)_filterDocNote:(NSString *)command startRange:(NSRange)docNoteStartRange endRange:(NSRange)docNoteEndRange {
    self.foundDocNoteStart = YES;
    //case1:文档类型的注释，开头和结尾不在同一行
    if (docNoteEndRange.location == NSNotFound) {
        return [command substringToIndex:docNoteStartRange.location];
    }
    //在同一行，过滤完这部分注释，再来过滤一遍
    else {
        self.foundDocNoteStart = NO;
        return [self _filterNote:[NSString stringWithFormat:@"%@%@", [command substringToIndex:docNoteStartRange.location], [command substringFromIndex:NSMaxRange(docNoteEndRange)]]];
    }
}

@end
