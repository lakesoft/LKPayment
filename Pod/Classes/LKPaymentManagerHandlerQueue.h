//
//  LKPaymentManagerHandlerArray.h
//  rainyday
//
//  Created by Hiroshi on 13/04/22.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LKPaymentManagerHandler;

@interface LKPaymentManagerHandlerQueue : NSObject

@property (nonatomic, strong) NSMutableArray* handlers;

- (LKPaymentManagerHandler*)handlerForModel:(id)model;
- (void)removeHandlerForModel:(id)model;
- (void)removeHandler:(LKPaymentManagerHandler*)handler;
- (void)addHandler:(LKPaymentManagerHandler*)handler;
- (BOOL)hasHandlerForModel:(id)model;

@end
