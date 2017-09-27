# Reflow
A unidirectional data flow framework for Objective-C inspired by Flux, Redux and Vue.

## Motivation

When writing Objective-C code, we are used to defining properties of models as `nonatomic`. However, doing this may lead to crash in multithread environment. For example, calling the method `methodA` below the app will crash with a `EXC_BAD_ACCESS` exception.

```objective-c
// TodoStore.h
@interface TodoStore : NSObject
@property (nonatomic, copy) NSArray *todos;
@end

// xxx.m
- (void)methodA
{
    TodoStore *todoStore = [[TodoStore alloc] init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            todoStore.todos = [[NSArray alloc] initWithObjects:@1, @2, @3, nil];
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (1) {
            NSLog(@"%@", todoStore.todos);
        }
    });
}
```

A simple approach to the crash here might be defining the properties as `atomic`. However this approach doesn't solve other issues like race condition.

Another danger is not keeping views up to date since propeties are mutable and we can change them any where throughout the app. If the `todos` property from the above example is binding to the cells of a table view, adding or removing a todo item and forgetting to notify the table view to do `reloadData` will cause another crash with a `NSInternalInconsistencyException` in the table view.

## Core Concepts

Reflow solves the above problems by imposing a more principled architecture, with the following concepts.

### Store

Like Redux, the state of your whole application is stored in a certain layer, **store**, and you concentrate your model update logic in the store too. Note that store in Reflow is an abstract concept. The state in the store can be in a database or in memory or both. What really concerns is that we only have a single source of truth.

As our application grows in scale, the whole state can get really bloated. Reflow allows us to divide our store into modules to help with that. Each store module is a subclass of `RFStore`.

```objective-c
@interface TodoStore : RFStore

#pragma mark - Getters

- (NSArray *)visibleTodos;
- (VisibilityFilter)visibilityFilter;

#pragma mark - Actions

- (void)actionAddTodo:(NSString *)text;
- (void)actionToggleTodo:(NSInteger)todoId;

- (void)actionSetVisibilityFilter:(VisibilityFilter)filter;

@end
```

### Actions

Actions are defined as normal methods on store modules, except with a name prefix "action". Reflow will do some magic tricks with that.

```objective-c
@implementation TodoStore

...

#pragma mark - Actions

- (void)actionAddTodo:(NSString *)text {
    Todo *todo = ...
    
    self.todos = [self.todos arrayByAddingObject:todo];
}

- (void)actionToggleTodo:(NSInteger)todoId {
    self.todos = [self.todos map:^id(Todo *value) {
        if (value.todoId == todoId) {
            Todo *todo = ...
            return todo;
        }
        return value;
    }];
}

- (void)actionSetVisibilityFilter:(VisibilityFilter)filter {
    self.filter = filter;
}

@end
```

### Subscriptions

When subclassing `RFStore`, we can subscribe to all actions on a store module.

```objective-c
@implementation TodoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.todoStore = [[TodoStore alloc] init];
    self.todos = [self.todoStore visibleTodos];
    self.filterButton.title = [self stringFromVisibilityFilter:[self.todoStore visibilityFilter]];
    
    self.subscription = [self.todoStore subscribe:^(RFAction *action) {
        if (action.selector == @selector(actionSetVisibilityFilter:)) {
            self.filterButton.title = [self stringFromVisibilityFilter:[self.todoStore visibilityFilter]];
        }
        self.todos = [self.todoStore visibleTodos];
        [self.tableView reloadData];
    }];
}

...
@end
```

On completion of each call of a action method, a store module will execute the block passed in `subscribe:`, passing in an instance of `RFAction` as a parameter of the block. Each instance of `RFAction` contains infomation like the `object` that the action method is sent to, the `selector` of the action method and the `arguments` that are passed in to the action method.

```objective-c
@interface RFAction : NSObject

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) NSArray *arguments;

@end
```

Note that we should retain the returned `subscription` when calling `subscribe:`. Reflow will not retain it internally and when all strong references to the `subscription` are gone, the `subscription` will call `unsubscribe` automatically.

We can subscribe to a single store module multiple times and we can subcribe to all actions of all store modules.
```objective-c
[RFStore subscribeToAllStores:xxx];
```

## Principles

Reflow is more of a pattern rather than a formal framework. It can be described in the following principles:

* Immutable model
* Single source of truth
* Centralized model update

## Installation

Just copy the source files into your project.

Required
* RFAspects.h/m
* RFStore.h/m

Optional
* NSArray+Functional.h/m
