//
//  RFStore.m
//  Reflow
//
//  Created by Zepo on 19/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import "RFStore.h"
#import "RFAspects.h"
#import <objc/runtime.h>

static const void * const kListernersKey = &kListernersKey;

@interface RFAction ()

- (instancetype)initWithObject:(id)object selector:(SEL)selector arguments:(NSArray *)arguments;

@end

@interface RFSubscription ()
@property (nonatomic, weak) id object;
@property (nonatomic, strong) void (^block)(RFAction *);
@end

#pragma mark - RFStore

@implementation RFStore

#pragma mark - Public

+ (RFSubscription *)subscribeToAllStores:(void (^)(RFAction *))listener {
    NSCParameterAssert(listener);
    
    @autoreleasepool {
        Class class = [RFStore class];
        static const void * const kHasHookedKey = &kHasHookedKey;
        @synchronized(class) {
            id hasHooked = objc_getAssociatedObject(class, kHasHookedKey);
            if (!hasHooked) {
                NSArray *subclasses = [RFStore subclassesOfClass:class];
                for (Class subclass in subclasses) {
                    [RFStore hookActionMethodsIfNeededForClass:subclass];
                    [RFStore hookActionMethodsIfNeededForClass:object_getClass(subclass)];
                }
                objc_setAssociatedObject(class, kHasHookedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
        
        return [RFStore subscriptionWithObject:class listener:listener];
    }
}

+ (RFSubscription *)subscribe:(void (^)(RFAction *))listener {
    NSCParameterAssert(listener);
    
    if (self == [RFStore class]) {
        NSAssert(NO, @"Should be called on subclasses.");
        return nil;
    }
    
    @autoreleasepool {
        return [RFStore subscribeToObject:self listener:listener];
    }
}

- (RFSubscription *)subscribe:(void (^)(RFAction *))listener {
    NSCParameterAssert(listener);
    
    if ([self class] == [RFStore class]) {
        NSAssert(NO, @"Should be called on instances of subclasses.");
        return nil;
    }
    @autoreleasepool {
        return [RFStore subscribeToObject:self listener:listener];
    }
}

#pragma mark - Private

+ (NSArray *)subclassesOfClass:(Class)parentClass {
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < numClasses; ++i) {
        Class superClass = classes[i];
        do {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil) {
            continue;
        }
        
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}

+ (void)hookActionMethodsIfNeededForClass:(Class)class {
    static const void * const kHasHookedKey = &kHasHookedKey;
    @synchronized(class) {
        id hasHooked = objc_getAssociatedObject(class, kHasHookedKey);
        if (!hasHooked) {
            unsigned int outCount = 0;
            Method *methods = class_copyMethodList(class, &outCount);
            for (unsigned int i = 0; i < outCount; ++i) {
                Method method = methods[i];
                SEL selector = method_getName(method);
                NSString *methodName = NSStringFromSelector(selector);
                if (![methodName hasPrefix:@"action"]) {
                    continue;
                }
                
                [RFStore registerActionForClass:class selector:selector];
            }
            objc_setAssociatedObject(class, kHasHookedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

+ (void)registerActionForClass:(Class)class selector:(SEL)selector {
    [class rfaspect_hookSelector:selector
                     withOptions:AspectPositionAfter
                      usingBlock:^(id<RFAspectInfo> aspectInfo) {
                          RFAction *action = [[RFAction alloc] initWithObject:aspectInfo.instance
                                                                     selector:selector
                                                                    arguments:aspectInfo.arguments];
                          
                          NSArray *globalListeners = [objc_getAssociatedObject([RFStore class], kListernersKey) allObjects];
                          NSArray *listeners = [objc_getAssociatedObject(action.object, kListernersKey) allObjects];
                          dispatch_async(dispatch_get_main_queue(), ^{
                              for (RFSubscription *subscription in globalListeners) {
                                  subscription.block(action);
                              }
                              for (RFSubscription *subscription in listeners) {
                                  subscription.block(action);
                              }
                          });
                      }
                           error:nil];
}

+ (RFSubscription *)subscriptionWithObject:(id)object listener:(void (^)(RFAction *))listener {
    RFSubscription *subscription = [[RFSubscription alloc] init];
    subscription.object = object;
    subscription.block = listener;
    [RFStore associateObject:object withSubscription:subscription];
    return subscription;
}

+ (void)associateObject:(id)object withSubscription:(RFSubscription *)subscription {
    @synchronized(object) {
        NSPointerArray *listeners = objc_getAssociatedObject(object, kListernersKey);
        if (!listeners) {
            listeners = [NSPointerArray weakObjectsPointerArray];
            objc_setAssociatedObject(object, kListernersKey, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [listeners compact];
        [listeners addPointer:(void *)subscription];
    }
}

+ (RFSubscription *)subscribeToObject:(id)object listener:(void (^)(RFAction *))listener {
    [RFStore hookActionMethodsIfNeededForClass:object_getClass(object)];
    
    return [RFStore subscriptionWithObject:object listener:listener];
}

@end

#pragma mark - RFAction

@implementation RFAction

- (instancetype)initWithObject:(id)object selector:(SEL)selector arguments:(NSArray *)arguments {
    self = [super init];
    if (self) {
        _object = object;
        _selector = selector;
        _arguments = arguments;
    }
    return self;
}

@end

#pragma mark - RFSubscription

@implementation RFSubscription

- (void)unsubscribe {
    id object = self.object;
    if (object) {
        @synchronized(object) {
            NSPointerArray *listeners = objc_getAssociatedObject(object, kListernersKey);
            NSInteger index = 0;
            for (RFSubscription *subscription in listeners) {
                if (subscription == self) {
                    break;
                }
                ++index;
            }
            [listeners removePointerAtIndex:index];
        }
    }
}

@end
