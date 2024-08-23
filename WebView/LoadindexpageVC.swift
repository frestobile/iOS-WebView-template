//  OnlineAppCreator.com
//  WebViewGold for iOS // webviewgold.com

/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */

import UIKit
import WebKit
class LoadindexpageVC: UIViewController {

    @IBOutlet weak var webviewWV: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "index", withExtension:"html")
        let request = URLRequest(url: url!)
        webviewWV.load(request) //loadRequest(request)
    }
    

}
