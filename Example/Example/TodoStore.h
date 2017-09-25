//
//  TodoStore.h
//  Example
//
//  Created by Zepo on 22/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import "RFStore.h"

typedef NS_ENUM(NSInteger, VisibilityFilter) {
    VisibilityFilterShowAll,
    VisibilityFilterShowActive,
    VisibilityFilterShowCompleted
};

@interface TodoStore : RFStore

#pragma mark - Getters

- (NSArray *)visibleTodos;
- (VisibilityFilter)visibilityFilter;

#pragma mark - Actions

- (void)actionAddTodo:(NSString *)text;
- (void)actionToggleTodo:(NSInteger)todoId;

- (void)actionSetVisibilityFilter:(VisibilityFilter)filter;

@end
