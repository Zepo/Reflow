//
//  RFStore.h
//  Reflow
//
//  Created by Zepo on 19/09/2017.
//  Copyright © 2017 Zepo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFAction : NSObject

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) NSArray *arguments;

@end

@interface RFSubscription : NSObject

- (void)unsubscribe;

@end

@interface RFStore : NSObject

/**
 * Subscribe to all actions of all stores, including both class and instance methods.
 *
 * @param listener The block to execute after an action being performed.
 *
 * @return You must retain the returned subscription.
 * Calling this method will NOT retain the returned subscription internally and
 * once there is no strong reference to it, it will unsubscribe automatically.
 */
+ (RFSubscription *)subscribeToAllStores:(void (^)(RFAction *action))listener;

/**
 * Subscribe to actions that are class methods.
 *
 * @param listener The block to execute after an action being performed.
 *
 * @return You must retain the returned subscription.
 * Calling this method will NOT retain the returned subscription internally and
 * once there is no strong reference to it, it will unsubscribe automatically.
 */
+ (RFSubscription *)subscribe:(void (^)(RFAction *action))listener;

/**
 * Subscribe to actions that are instance methods.
 *
 * @param listener The block to execute after an action being performed.
 *
 * @return You must retain the returned subscription.
 * Calling this method will NOT retain the returned subscription internally and
 * once there is no strong reference to it, it will unsubscribe automatically.
 */
- (RFSubscription *)subscribe:(void (^)(RFAction *action))listener;

@end
