//
//  LKPaymentManagerHandler.h
//  rainyday
//
//  Created by Hiroshi on 13/04/22.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LKPaymentManagerHandlerState) {
    LKPaymentManagerHandlerStateUnkown = 0,     // default
    LKPaymentManagerHandlerStateSuccess,
    LKPaymentManagerHandlerStateFailure
};


@interface LKPaymentManagerHandler : NSObject

@property (nonatomic, strong, readonly) id model;
@property (nonatomic, strong, readonly) id success;
@property (nonatomic, strong, readonly) id failure;
@property (nonatomic, assign) LKPaymentManagerHandlerState state;

- (id)initWithModel:(id)model success:(id)success failure:(id)failure;
- (void)start;
- (BOOL)isEqualWithModel:(id)model;

@end

