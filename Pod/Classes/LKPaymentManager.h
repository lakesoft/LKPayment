//
//  PaymentTransactionObserver.h
//  rainyday
//
//  Created by Hiroshi on 13/04/21.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//
#import <StoreKit/StoreKit.h>

#import <Foundation/Foundation.h>

typedef void (^LKPaymentManagerFetchSuccess)(NSArray* products, NSArray* invalidIdentifiers);
typedef void (^LKPaymentManagerSuccess)(void);
typedef void (^LKPaymentManagerFailure)(BOOL canceledByUser, NSError* error);

@interface LKPaymentManager : NSObject

+ (LKPaymentManager*)sharedManager;
+ (NSString*)filenameOfProductIdentifiers;

- (BOOL)canMakePayments;

- (void)fetchProductsWithIdentifiers:(NSSet*)productIdentifiers
                             success:(LKPaymentManagerFetchSuccess)success
                             failure:(LKPaymentManagerFailure)failure;

// NOTE: get productIdentifiers from "LKProductIdentifiers.plist"
- (void)fetchProductsSuccess:(LKPaymentManagerFetchSuccess)success
                     failure:(LKPaymentManagerFailure)failure;

- (void)purchaseProductIdentifier:(NSString*)productIdentifer
                          success:(LKPaymentManagerSuccess)success
                          failure:(LKPaymentManagerFailure)failure;

- (void)restoreSuccess:(LKPaymentManagerSuccess)success
               failure:(LKPaymentManagerFailure)failure;

// debug
- (NSString*)descriptionOfProduct:(SKProduct*)product;

@end
