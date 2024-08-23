//  OnlineAppCreator.com
//  WebViewGold for iOS // webviewgold.com

/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */
/* PLEASE CHECK CONFIG.SWIFT FOR CONFIGURATION */

import UIKit
import SwiftyGif

class SplashscreenVC: UIViewController {

    @IBOutlet weak var imageview: UIImageView!
    var gameTimer: Timer?
    @IBOutlet var mainbackview: UIView!
    
    @IBOutlet weak var loadingSign: UIActivityIndicatorView!
    
    @IBOutlet weak var splashWidthRatio: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (splashScreenEnabled) {
            loadingSign.isHidden = true
            self.view.backgroundColor = Constants.splashscreencolor
            do {
                // this splash acts a entrypoint while the next VC is created
                // and transitioned to in `fireTimer()`. It is only on screen
                // for a short duration as another splash begins playing in
                // `WebViewController` instead
                let gif = try UIImage(gifName: "splash",levelOfIntegrity: 1)
                let gifManager = SwiftyGifManager(memoryLimit:100)
                imageview.delegate = self
                imageview.setGifImage(gif, manager: gifManager, loopCount: -1)
            } catch {
                print(error)
            }
        } else{
            if (useLoadingSign) {
                loadingSign.isHidden = false
                loadingSign.startAnimating()
                loadingSign.color = loadingIndicatorColor
            } else{
                loadingSign.isHidden = true
            }
            self.view.backgroundColor = Constants.splashscreencolor
        }
        
        if (!splashScreenEnabled) {
            gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        }
        
        // Splash Screen Scaling
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        splashWidthRatio.constant = screenWidth <= screenHeight ? screenWidth * (CGFloat(scaleSplashImage) / 100.0) : screenHeight * (CGFloat(scaleSplashImage) / 100.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // moved from delegate as `fireTimer()` was being called before the VC was fully in the window hierachy
        fireTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    @objc func fireTimer() {
        print("Timer fired!")
        
        if #available(iOS 13.0, *) {
            let ncv = self.storyboard?.instantiateViewController(identifier: "homenavigation") as! UINavigationController
            self.present(ncv, animated: false, completion: nil)
        } else {
            // Fallback on earlier versions
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "homenavigation") as! UINavigationController
            self.present(vc, animated: false, completion: nil)
        }
        
    }

}
extension SplashscreenVC : SwiftyGifDelegate {

    func gifURLDidFinish(sender: UIImageView) {
        print("gifURLDidFinish")
    }

    func gifURLDidFail(sender: UIImageView) {
        print("gifURLDidFail")
    }

    func gifDidStart(sender: UIImageView) {
        print("gifDidStart")
    }
    
    func gifDidLoop(sender: UIImageView) {
        print("gifDidLoop")
    }
    
    func gifDidStop(sender: UIImageView) {
        print("gifDidStop")
    }
}
