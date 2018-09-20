//
//  PaymentHighwayServiceSpec.swift
//  PaymentHighwayTests
//
//  Copyright © 2018 Payment Highway Oy. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import PaymentHighway
import Alamofire

// swiftlint:disable function_body_length
class PaymentHighwayServiceSpec: QuickSpec {
    
    override func spec() {
        let merchantId = MerchantId(id: "test_merchantId")
        let accountId = AccountId(id: "test")
        let cardTest = CardData(pan: "4153013999700024", cvc: "024", expiryDate: ExpiryDate(month: "11", year: "2023")!)

        var backendAdapter: BackendAdapterExample!
        var paymentHighwayService: PaymentHighwayService!
        
        beforeEach {
            backendAdapter = BackendAdapterExample()
            paymentHighwayService = PaymentHighwayService(merchantId: merchantId, accountId: accountId)
        }
        
        describe("with BackendAdapter and PaymentHighwayService") {
            it("we should get TransactionId") {
                var receivedTransactionId: TransactionId = TransactionId(id: "")
                
                backendAdapter.getTransactionId { (transactionIdResult) in
                    if case .success(let transactionId) = transactionIdResult {
                        receivedTransactionId  = transactionId
                        return
                    }
                    fail("Transaction id not received")
                }
                
                expect(receivedTransactionId.id).toEventually(contain("-"), timeout: 5)
            }
            
            it("we should get Transaction Key") {
                var receivedEncryptionKey: EncryptionKey = EncryptionKey(key: "")
                
                backendAdapter.getTransactionId { (transactionIdResult) in
                    if case .success(let transactionId) = transactionIdResult {
                        paymentHighwayService.encryptionKey(transactionId: transactionId) { (encryptionKeyResult) in
                            if case .success(let encryptionKey) = encryptionKeyResult {
                                receivedEncryptionKey = encryptionKey
                                return
                            }
                            fail("Transaction key not received")
                        }
                    }
                }
                
                expect(receivedEncryptionKey.key).toEventually(contain("MII"), timeout: 5)
            }
            
            it("we should tokenize") {
                var success: Bool = false
                backendAdapter.getTransactionId { (transactionIdResult) in
                    if case .success(let transactionId) = transactionIdResult {
                        paymentHighwayService.encryptionKey(transactionId: transactionId) { (encryptionKeyResult) in
                            if case .success(let encryptionKey) = encryptionKeyResult {
                                paymentHighwayService.tokenizeTransaction(transactionId: transactionId,
                                                                          cardData: cardTest,
                                                                          encryptionKey: encryptionKey) { (tokenizeTransactionResult) in
                                    if case .success = tokenizeTransactionResult {
                                        success = true
                                        return
                                    }
                                    fail("Tokenize Failed")
                                }
                            }
                        }
                    }
                }
                
                expect(success).toEventually(equal(true), timeout: 5)
            }
            
            it("we should get token") {
                var receivedTransactionToken = TransactionToken(token: "",
                                                                card: TransactionCard(cardType: "",
                                                                                      partialPan: "",
                                                                                      expireMonth: "",
                                                                                      expireYear: ""))
                backendAdapter.getTransactionId { (transactionIdResult) in
                    if case .success(let transactionId) = transactionIdResult {
                        paymentHighwayService.encryptionKey(transactionId: transactionId) { (encryptionKeyResult) in
                            if case .success(let encryptionKey) = encryptionKeyResult {
                                paymentHighwayService.tokenizeTransaction(transactionId: transactionId,
                                                                          cardData: cardTest,
                                                                          encryptionKey: encryptionKey) { (tokenizeTransactionResult) in
                                    if case .success = tokenizeTransactionResult {
                                        backendAdapter.addCardCompleted(transactionId: transactionId) { (cardAddedResult) in
                                            if case .success(let transactionToken) = cardAddedResult {
                                                receivedTransactionToken = transactionToken
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                expect(receivedTransactionToken.token).toEventually(contain("-"), timeout: 5)
                expect(receivedTransactionToken.card.cardType).to(equal("Visa"))
                expect(receivedTransactionToken.card.partialPan).to(equal("0024"))
                expect(receivedTransactionToken.card.expireMonth).to(equal("11"))
                expect(receivedTransactionToken.card.expireYear).to(equal("2023"))
            }
        }
    }
}
