//
//  NSArray+Functional.h
//  Example
//
//  Created by Zepo on 25/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Functional)

- (NSArray *)map:(id (^)(id value))block;
- (NSArray *)filter:(BOOL (^)(id value))block;

@end
