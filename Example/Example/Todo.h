//
//  Todo.h
//  Example
//
//  Created by Zepo on 22/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Todo : NSObject

@property (nonatomic, assign) NSInteger todoId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL completed;

@end
