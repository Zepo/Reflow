//
//  TodoStore.m
//  Example
//
//  Created by Zepo on 22/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import "TodoStore.h"
#import "Todo.h"
#import "NSArray+Functional.h"

@interface TodoStore ()
@property (nonatomic, assign) NSInteger nextTodoId;
@property (nonatomic, copy) NSArray *todos;
@property (nonatomic, assign) VisibilityFilter filter;
@end

@implementation TodoStore

- (instancetype)init {
    self = [super init];
    if (self) {
        Todo *todo1 = [[Todo alloc] init];
        todo1.todoId = ++_nextTodoId;
        todo1.text = @"Reflow";
        
        Todo *todo2 = [[Todo alloc] init];
        todo2.todoId = ++_nextTodoId;
        todo2.text = @"Immutable";
        
        Todo *todo3 = [[Todo alloc] init];
        todo3.todoId = ++_nextTodoId;
        todo3.text = @"Functional";
        
        _todos = @[ todo1, todo2, todo3 ];
    }
    return self;
}

#pragma mark - Getters

- (NSArray *)visibleTodos {
    switch (self.filter) {
        case VisibilityFilterShowAll:
            return self.todos;
            break;
        case VisibilityFilterShowActive:
            return [self.todos filter:^BOOL(Todo *value) {
                return !value.completed;
            }];
            break;
        case VisibilityFilterShowCompleted:
            return [self.todos filter:^BOOL(Todo *value) {
                return value.completed;
            }];
            break;
        default:
            NSAssert(NO, @"Unknown filter:%ld", (long)self.filter);
            return nil;
            break;
    }
}

- (VisibilityFilter)visibilityFilter {
    return self.filter;
}

#pragma mark - Actions

- (void)actionAddTodo:(NSString *)text {
    Todo *todo = [[Todo alloc] init];
    todo.todoId = ++self.nextTodoId;
    todo.text = text;
    todo.completed = NO;
    
    self.todos = [self.todos arrayByAddingObject:todo];
}

- (void)actionToggleTodo:(NSInteger)todoId {
    self.todos = [self.todos map:^id(Todo *value) {
        if (value.todoId == todoId) {
            Todo *todo = [[Todo alloc] init];
            todo.todoId = value.todoId;
            todo.text = value.text;
            todo.completed = !value.completed;
            return todo;
        }
        return value;
    }];
}

- (void)actionSetVisibilityFilter:(VisibilityFilter)filter {
    self.filter = filter;
}

@end
