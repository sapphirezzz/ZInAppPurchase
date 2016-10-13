//
//  ZInAppPurchase.swift
//  Meijiabang
//
//  Created by Zack on 16/5/26.
//  Copyright © 2016年 Double. All rights reserved.
//

import Foundation
import StoreKit

enum ZInAppPurchaseError: String {

    case ProductIdNil
    case ProductInfoRequestFailed
    case ProductNotExisited
    case PurchaseWasForbidden
    
    case ErrorUnknown
    case ClientInvalid
    case PaymentCancelled
    case PaymentInvalid
    case PaymentNotAllowed
    case StoreProductNotAvailable
}

class ZInAppPurchase: NSObject {

    static let sharedInstance = ZInAppPurchase()
    private override init() {super.init()}
    var successAction: ((receipt: String)->Void)?
    var failureAction: ((error: ZInAppPurchaseError)->Void)?

    func purchaseProduct(productId: String?, successAction: ((receipt: String)->Void)? = nil, failureAction: ((error: ZInAppPurchaseError)->Void)? = nil) {
        
        self.successAction = successAction
        self.failureAction = failureAction

        guard let productId = productId else {
            failureAction?(error: ZInAppPurchaseError.ProductIdNil)
            return
        }
        let productRequest = SKProductsRequest(productIdentifiers: Set<String>(arrayLiteral: productId))
        productRequest.delegate = self
        productRequest.start()
    }
}

extension ZInAppPurchase: SKProductsRequestDelegate {

    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {

        if let product = response.products.first {
            if SKPaymentQueue.canMakePayments() {
                let payment = SKPayment(product: product)
                SKPaymentQueue.defaultQueue().addTransactionObserver(self)
                SKPaymentQueue.defaultQueue().addPayment(payment)
            }else {
                failureAction?(error: ZInAppPurchaseError.PurchaseWasForbidden)
            }
        }else {
            failureAction?(error: ZInAppPurchaseError.ProductNotExisited)
        }
    }
    
    func requestDidFinish(request: SKRequest) {
        print("ZInAppPurchase request requestDidFinish")
    }
    
    func request(request: SKRequest, didFailWithError error: NSError) {
        print("ZInAppPurchase request didFailWithError error = ", error)
        failureAction?(error: ZInAppPurchaseError.ProductInfoRequestFailed)
    }
}

extension ZInAppPurchase: SKPaymentTransactionObserver {

    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    
        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchased: // Transaction is in queue, user has been charged.  Client should complete the transaction.
                
                if let receiptUrl = NSBundle.mainBundle().appStoreReceiptURL, let receiptData = NSData(contentsOfURL: receiptUrl) {
                    let receiptString = receiptData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                    successAction?(receipt: receiptString)
                }else {
                    failureAction?(error: ZInAppPurchaseError.ErrorUnknown)
                }
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                
            case .Failed: // Transaction was cancelled or failed before being added to the server queue.
                
                if let code = transaction.error?.code , let errorCode = SKErrorCode(rawValue: code)  {
                
                    switch errorCode {
                    case SKErrorCode.Unknown:
                        failureAction?(error: ZInAppPurchaseError.ErrorUnknown)
                    case SKErrorCode.ClientInvalid:
                        failureAction?(error: ZInAppPurchaseError.ClientInvalid)
                    case SKErrorCode.PaymentCancelled:
                        failureAction?(error: ZInAppPurchaseError.PaymentCancelled)
                    case SKErrorCode.PaymentInvalid:
                        failureAction?(error: ZInAppPurchaseError.PaymentInvalid)
                    case SKErrorCode.PaymentNotAllowed:
                        failureAction?(error: ZInAppPurchaseError.PaymentNotAllowed)
                    case SKErrorCode.StoreProductNotAvailable:
                        failureAction?(error: ZInAppPurchaseError.StoreProductNotAvailable)
                    default:
                        failureAction?(error: ZInAppPurchaseError.ErrorUnknown)
                    }
                }else {
                    failureAction?(error: ZInAppPurchaseError.ErrorUnknown)
                }
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}
