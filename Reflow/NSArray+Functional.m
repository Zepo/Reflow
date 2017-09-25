//
//  NSArray+Functional.m
//  Example
//
//  Created by Zepo on 25/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import "NSArray+Functional.h"

@implementation NSArray (Functional)

- (NSArray *)map:(id (^)(id))block {
    NSCParameterAssert(block);
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.count];
    for (id value in self) {
        [array addObject:block(value)];
    }
    return array;
}

- (NSArray *)filter:(BOOL (^)(id))block {
    NSCParameterAssert(block);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (id value in self) {
        if (block(value)) {
            [array addObject:value];
        }
    }
    return array;
}

@end
