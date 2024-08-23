import UIKit
import StoreKit


class IPAHelper: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver{
  
    var delegate: IAPurchaceViewControllerDelegate!
    
    var transactionInProgress = false
    var selectedProductIndex: Int!
    
    var productIDs: Array<String?> = []
    
    var productsArray: Array<SKProduct?> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        selectedProductIndex = 0
        
        productIDs.append(Constants.AppBundleIdentifier)
      
         requestProductInfo()
        
        SKPaymentQueue.default().add(self as SKPaymentTransactionObserver)
    }
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = NSSet(array: productIDs as [Any])
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as Set<NSObject> as! Set<String>)
            
            productRequest.delegate = self
            productRequest.start()
        }
        else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                productsArray.append(product )
            }
            
            
        }
        else {
            print("There are no products.")
        }
    }
    
    func showActions() {
        if transactionInProgress {
            return
        }
        
        let actionSheetController = UIAlertController(title: "IAPDemo", message: "What do you want to do?", preferredStyle: UIAlertController.Style.actionSheet)
        
        let buyAction = UIAlertAction(title: "Buy", style: UIAlertAction.Style.default) { (action) -> Void in
            let payment = SKPayment(product: (self.productsArray[self.selectedProductIndex])!)
            SKPaymentQueue.default().add(payment)
            self.transactionInProgress = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action) -> Void in
            
        }
        
        actionSheetController.addAction(buyAction)
        actionSheetController.addAction(cancelAction)
        
        present(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func Acitoooo(_ sender: Any) {
        
        showActions()
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                print("Transaction completed successfully")
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                delegate.didBuyColorsCollection(collectionIndex: selectedProductIndex)

            case SKPaymentTransactionState.failed:
                print("Transaction failed");
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                
            default:
                print(transaction.transactionState.rawValue)
            }
        }
    }
    
}

