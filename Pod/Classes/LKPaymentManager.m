//
//  PaymentTransactionObserver.m
//  rainyday
//
//  Created by Hiroshi on 13/04/21.
//  Copyright (c) 2013年 Lakesoft. All rights reserved.
//

// TODO: UIAlertViewを外に出す。UIは持たない（別途ライブラリを用意する）
// TODO: restore中なら purchase をキャンセルする
// TODO: カスタムNSErrorを用意する
// TODO: 呼び出し元が消えてしまった場合、success/failureを呼んで良いのか？
// TODO: success/failureはstrongとcopy、どっちがいい？
// TODO: 事前 canMakePaymentsのチェック。不可の場合のエラー処理

#import "LKPaymentManager.h"
#import "LKPaymentManagerHandler.h"
#import "LKPaymentManagerHandlerQueue.h"

#define LK_PAYMENT_MANAGER_FILENAME_OF_PRODUCT_IDENTIFIERS  @"LKProductIdentifiers.plist"

//------------------------------------------
// interfaces
//------------------------------------------
@interface LKPaymentManager() <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) LKPaymentManagerHandlerQueue* handlerQueue;
@property (nonatomic, strong) UIAlertView* alertView;
@end


#pragma mark -
#pragma mark LKPaymentManagerRequestHandler
@interface LKPaymentManagerRequestHandler : LKPaymentManagerHandler
- (id)initWithProductIdentifiers:(NSSet*)productIdentifiers success:(LKPaymentManagerFetchSuccess)success failure:(LKPaymentManagerFailure)failure;
@end


#pragma mark -
#pragma mark LKPaymentManagerPurchaseHandler
@interface LKPaymentManagerPurchaseHandler : LKPaymentManagerHandler
- (id)initWithProduct:(SKProduct*)product success:(LKPaymentManagerSuccess)success failure:(LKPaymentManagerFailure)failure;
@end

#pragma mark -
#pragma mark LKPaymentMangerRestoreHandler
@interface LKPaymentManagerRestoreHandler : LKPaymentManagerHandler
- (id)initWithSuccess:(LKPaymentManagerSuccess)success failure:(LKPaymentManagerFailure)failure;
@end



//------------------------------------------
// implementations
//------------------------------------------
#pragma mark -
#pragma mark LKPaymentManager

@implementation LKPaymentManager

#pragma mark -
#pragma mark Privates (Localized)
- (NSString*)_localizedStringForKey:(NSString*)key
{
    return [NSBundle.mainBundle localizedStringForKey:key value:nil table:NSStringFromClass(self.class)];
}

#pragma mark -
#pragma mark Basics

- (id)init
{
    self = [super init];
    if (self) {
        self.handlerQueue = LKPaymentManagerHandlerQueue.new;
    }
    return self;
}


+ (LKPaymentManager*)sharedManager
{
    static LKPaymentManager* _sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = self.new;
    });
    return _sharedManager;
}

- (NSString*)description
{
    return self.handlerQueue.description;
}

#pragma mark -
#pragma mark API (Class)

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [SKPaymentQueue.defaultQueue addTransactionObserver:self.sharedManager];
    });
}

+ (NSString*)filenameOfProductIdentifiers
{
    return LK_PAYMENT_MANAGER_FILENAME_OF_PRODUCT_IDENTIFIERS;
}

- (void)_showAlertWithMessageKey:(NSString*)messageKey
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self _localizedStringForKey:@"LKPaymentManager.Title"]
                                                    message:[self _localizedStringForKey:messageKey]
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction* transaction in transactions) {
        
        LKPaymentManagerHandler* handler = nil;
        
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchased:
                [queue finishTransaction:transaction];
                handler = [self.handlerQueue handlerForModel:transaction.payment];
                if (handler) {
                    handler.state = LKPaymentManagerHandlerStateSuccess;
                    [self _showAlertWithMessageKey:@"LKPaymentManager.Result01"];
                    ((LKPaymentManagerSuccess)handler.success)();
                    [self.handlerQueue removeHandler:handler];
                }
                break;
                
            case SKPaymentTransactionStateFailed:
                [queue finishTransaction:transaction];
                handler = [self.handlerQueue handlerForModel:transaction.payment];
                if (handler) {
                    handler.state = LKPaymentManagerHandlerStateFailure;
                    if (transaction.error == nil) {
                        [self _showAlertWithMessageKey:@"LKPaymentManager.Result03"];
                    }
                    ((LKPaymentManagerFailure)handler.failure)(transaction.error.code == SKErrorPaymentCancelled, transaction.error);
                    [self.handlerQueue removeHandler:handler];
                }
                break;
                
            case SKPaymentTransactionStateRestored:
//                NSLog(@"%s|SKPaymentTransactionStateRestored", __PRETTY_FUNCTION__);    // DEBUG
                [queue finishTransaction:transaction];
                handler = [self.handlerQueue handlerForModel:LKPaymentManagerRestoreHandler.class];
                if (handler) {
                    [self _showAlertWithMessageKey:@"LKPaymentManager.Result02"];
                    handler.state = LKPaymentManagerHandlerStateSuccess;
                    ((LKPaymentManagerSuccess)handler.success)();
                }
                break;
                
            case SKPaymentTransactionStatePurchasing:
                break;
                
            default:
                break;
        }
    }
}


- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (self.alertView) {
        [self.alertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    
    LKPaymentManagerHandler* handler = [self.handlerQueue handlerForModel:LKPaymentManagerRestoreHandler.class];
    if (handler) {
        ((LKPaymentManagerFailure)handler.failure)(error.code == SKErrorPaymentCancelled, error);
        [self.handlerQueue removeHandler:handler];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if (self.alertView) {
        [self.alertView dismissWithClickedButtonIndex:0 animated:YES];
    }

    LKPaymentManagerHandler* handler = [self.handlerQueue handlerForModel:LKPaymentManagerRestoreHandler.class];
    if (handler) {
        if (handler.state != LKPaymentManagerHandlerStateSuccess) {
            ((LKPaymentManagerFailure)handler.failure)(NO, nil);
        }
        [self.handlerQueue removeHandler:handler];
    }
}


#pragma mark -
#pragma mark SKProductRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    LKPaymentManagerRequestHandler* handler = (LKPaymentManagerRequestHandler*)[self.handlerQueue handlerForModel:request];
    LKPaymentManagerFetchSuccess success = handler.success;
    if (success) {
        success(response.products, response.invalidProductIdentifiers);
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    [self.handlerQueue removeHandlerForModel:request];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    LKPaymentManagerRequestHandler* handler = (LKPaymentManagerRequestHandler*)[self.handlerQueue handlerForModel:request];
    LKPaymentManagerFailure failure = handler.failure;
    if (failure) {
        failure(NO, error);
    }
}




#pragma mark -
#pragma mark API
- (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)fetchProductsWithIdentifiers:(NSSet*)productIdentifiers
                             success:(LKPaymentManagerFetchSuccess)success
                             failure:(LKPaymentManagerFailure)failure
{
    LKPaymentManagerRequestHandler* handler = [[LKPaymentManagerRequestHandler alloc]
                                               initWithProductIdentifiers:productIdentifiers
                                               success:success
                                               failure:failure];
    [self.handlerQueue addHandler:handler];
    [handler start];
    
    // --> SKPaymentProductRequestDelegate (async)
}

- (void)fetchProductsSuccess:(LKPaymentManagerFetchSuccess)success
                     failure:(LKPaymentManagerFailure)failure
{
    NSString* path = [NSBundle.mainBundle pathForResource:self.class.filenameOfProductIdentifiers ofType:nil];
    NSArray* array = [NSArray arrayWithContentsOfFile:path];
    
    if (array) {
        NSSet* set = [NSSet setWithArray:array];
        [self fetchProductsWithIdentifiers:set success:success failure:failure];
    } else {
        NSLog(@"%s|Can't read '%@'.", __PRETTY_FUNCTION__, self.class.filenameOfProductIdentifiers);
        failure(NO, nil);
    }
}

- (void)purchaseProductIdentifier:(NSString*)productIdentifer
                          success:(LKPaymentManagerSuccess)success
                          failure:(LKPaymentManagerFailure)failure
{
    if (!self.canMakePayments) {
        [self _showAlertWithMessageKey:@"LKPaymentManager.Message.Availability"];
        return; // abort
    }

    [self fetchProductsWithIdentifiers:[NSSet setWithObject:productIdentifer]
                               success:^(NSArray* products, NSArray* invalidIdentifiers) {
                                   if (products.count) {
                                       SKProduct* product = [products objectAtIndex:0];
                                       LKPaymentManagerPurchaseHandler* handler = [[LKPaymentManagerPurchaseHandler alloc]
                                                                                   initWithProduct:product
                                                                                   success:success
                                                                                   failure:failure];
                                       [self.handlerQueue addHandler:handler];
                                       [handler start];
                                   } else {
                                       NSLog(@"%s|'%@' is not available.", __PRETTY_FUNCTION__, productIdentifer);
                                       failure(NO, nil);    // TODO: custom NSError
                                   }
                               }
                               failure:^(BOOL canceledByUser, NSError* error) {
                                   failure(NO, error);
                               }];
    
}


- (void)restoreSuccess:(LKPaymentManagerSuccess)success
               failure:(LKPaymentManagerFailure)failure
{
    if ([self.handlerQueue hasHandlerForModel:LKPaymentManagerRestoreHandler.class]) {
        failure(NO, nil);   // TODO: original error
        
    } else {
        LKPaymentManagerRestoreHandler* handler = [[LKPaymentManagerRestoreHandler alloc] initWithSuccess:success
                                                                                                  failure:failure];
        [self.handlerQueue addHandler:handler];
        [handler start];
        
        self.alertView = [[UIAlertView alloc] initWithTitle:[self _localizedStringForKey:@"LKPaymentManager.Restore.Title"]
                                                    message:[self _localizedStringForKey:@"LKPaymentManager.Restore.Processing"]
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
        [self.alertView show];
    }
}


- (NSString*)descriptionOfProduct:(SKProduct*)product
{
    return [NSString stringWithFormat:@"\n%@\n\t%@\n\t%@\n\t%@",
            product.localizedTitle,
            product.localizedDescription,
            product.price,
            product.priceLocale];
}

@end


//--------------------------------------
#pragma mark -
#pragma mark PaymentManagerRequestHandler

//
// mode <SKProductRequest>
//
@implementation LKPaymentManagerRequestHandler

- (id)initWithProductIdentifiers:(NSSet*)productIdentifiers success:(LKPaymentManagerFetchSuccess)success failure:(LKPaymentManagerFailure)failure
{
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self = [super initWithModel:request success:success failure:failure];
    request.delegate = LKPaymentManager.sharedManager;
    if (self) {
        
    }
    
    return self;
}

- (void)start
{
    [(SKProductsRequest*)self.model start];
}

@end


//------------------------------------------
#pragma mark -
#pragma mark PaymentManagerPurchaseHandler

//
// model <SKPayment>
//
@implementation LKPaymentManagerPurchaseHandler
- (id)initWithProduct:(SKProduct*)product success:(LKPaymentManagerSuccess)success failure:(LKPaymentManagerFailure)failure
{
    SKPayment* payment = [SKPayment paymentWithProduct:product];
    self = [super initWithModel:payment
                        success:success
                        failure:failure];
    if (self) {
    }
    return self;
}

- (void)start
{
    SKPayment* payment = (SKPayment*)self.model;
    [SKPaymentQueue.defaultQueue addPayment:payment];
    
    // --> SKPaymentTransactionObserver
}

- (BOOL)isEqualWithModel:(id)model
{
    SKPayment* payment1 = (SKPayment*)self.model;
    SKPayment* payment2;
    if ([model isKindOfClass:SKPayment.class]) {
        payment2 = (SKPayment*)model;
    }
    
    // easy checking
    // TODO: ??
    return ([payment1.productIdentifier isEqualToString:payment2.productIdentifier] &&
            (payment1.quantity == payment2.quantity));
}

@end


//------------------------------------------
#pragma mark -
#pragma mark PaymentManagerRestoreHandler

@implementation LKPaymentManagerRestoreHandler

- (id)initWithSuccess:(LKPaymentManagerSuccess)success failure:(LKPaymentManagerFailure)failure
{
    self = [super initWithModel:LKPaymentManagerRestoreHandler.class success:success failure:failure];
    if (self) {
        
    }
    return self;
}

- (void)start
{
    [SKPaymentQueue.defaultQueue restoreCompletedTransactions];
}

@end
