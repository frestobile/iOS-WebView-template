import UIKit
import StoreKit

class IPAViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    let product_id: NSString = Constants.InAppPurchAppBundleIdentifier as NSString
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        SKPaymentQueue.default().add(self)
    }
    
    @IBAction func buyNowAction(_ sender: UIButton)
    {
        if (SKPaymentQueue.canMakePayments()) {
            let productID:NSSet = NSSet(array: [self.product_id as NSString]);
            let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
            productsRequest.delegate = self;
            productsRequest.start();
            print("Fetching Products");
        } else {
            print("can't make purchases");
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        
        print(response.products)
        let count : Int = response.products.count
        if (count>0) {
            
            let validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.product_id as String) {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                //                self.buyProduct(product: validProduct)
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                
                
                
                switch trans.transactionState {
                case .purchased:
                    print("Product Purchased")
                    //Do unlocking etc stuff here in case of new purchase
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    break;
                case .failed:
                    print("Purchased Failed");
                    if let error = transaction.error as? SKError {
                        if error.code == .paymentCancelled {
                            // User cancelled the purchase
                            print("Purchase Cancelled")
                        } else {
                            // Handle other purchase errors
                            let purchaseErrorDescription = error.localizedDescription
                            print("Purchase Error: \(purchaseErrorDescription)")
                        }
                    }
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                case .restored:
                    print("Already Purchased")
                    //Do unlocking etc stuff here in case of restor
                    
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                default:
                    break;
                }
            }
        }
    }
    
    
    //If an error occurs, the code will go to this function
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        // Show some alert
    }
    
}
