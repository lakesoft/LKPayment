//
//  LKPaymentManagerHandler.m
//  rainyday
//
//  Created by Hiroshi on 13/04/22.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//

#import "LKPaymentManagerHandler.h"

@interface LKPaymentManagerHandler()

@property (nonatomic, strong) id model;
@property (nonatomic, strong) id success;
@property (nonatomic, strong) id failure;

@end


@implementation LKPaymentManagerHandler

- (id)initWithModel:(id)model success:(id)success failure:(id)failure
{
    self = [super init];
    if (self) {
        self.model = model;
        self.success = success;
        self.failure = failure;
    }
    return self;
}

- (void)start
{
    // not implemented
}

- (BOOL)isEqualWithModel:(id)model
{
    return (self.model == model);
}


@end
