//
//  LKPaymentManagerHandlerArray.m
//  rainyday
//
//  Created by Hiroshi on 13/04/22.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//

#import "LKPaymentManagerHandlerQueue.h"
#import "LKPaymentManagerHandler.h"

@implementation LKPaymentManagerHandlerQueue
- (id)init
{
    self = [super init];
    if (self) {
        self.handlers = @[].mutableCopy;
    }
    return self;
}

- (LKPaymentManagerHandler*)handlerForModel:(id)model
{
    @synchronized (self.handlers) {
        for (LKPaymentManagerHandler* handler in self.handlers) {
            if ([handler isEqualWithModel:model]) {
                return handler;
            }
        }
    }
    return nil;
}

- (void)removeHandlerForModel:(id)model
{
    @synchronized (self.handlers) {
        for (LKPaymentManagerHandler* handler in self.handlers) {
            if ([handler isEqualWithModel:model]) {
                [self.handlers removeObject:handler];
                return;
            }
        }
    }
}

- (void)removeHandler:(LKPaymentManagerHandler*)handler
{
    @synchronized (self.handlers) {
        [self.handlers removeObject:handler];
    }
}

- (void)addHandler:(LKPaymentManagerHandler*)handler
{
    @synchronized (self.handlers) {
        [self.handlers addObject:handler];
    }
}

- (BOOL)hasHandlerForModel:(id)model
{
    return [self handlerForModel:model]!=nil ? YES : NO;
}

- (NSString*)description
{
    return self.handlers.description;
}

@end
