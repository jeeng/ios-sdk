//
//  JeengView.swift
//  JeengSdkIOS
//
//  Created by jeeng on 22/05/2019.
//  Copyright © 2019 jeeng. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications

public class JeengView: UIView, WKNavigationDelegate, UNUserNotificationCenterDelegate{

    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var waitIcon: UIActivityIndicatorView!
    var action: String = "placeHolder"
    
    let nibName = "JeengView"
    var contentView: UIView!
    
    public override init(frame: CGRect) {
        // For use in code
        super.init(frame: frame)
        setUpView(frame:frame)
    }
    public required init?(coder aDecoder: NSCoder) {
        // For use in Interface Builder
        super.init(coder: aDecoder)
        setUpView(frame:frame)
    }
    //clicked 'X'
    @IBAction func click(_ sender: Any) {
        DispatchQueue.main.async {
            DispatchQueue.main.async {
                self.removeFromSuperview()
            }
        }
    }
    //after finished loading the webpage
    public func webView(_ webView: WKWebView,
                        didFinish navigation: WKNavigation!) {
        self.waitIcon.stopAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
            self.btn.isHidden=false
        })
    }
    // init the components
    private func setUpView(frame: CGRect) {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        self.contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        contentView.frame.size.width = frame.width
        contentView.frame.size.height = frame.height
        webView.frame.size.width = frame.width
        webView.frame.size.height = frame.height
        addSubview(contentView)
        contentView.center = self.center
        contentView.autoresizingMask = []
        contentView.translatesAutoresizingMaskIntoConstraints = true
        self.waitIcon.startAnimating()
        self.contentView.isHidden=true
    }
    
    //making api request and sending local notification
    public func getAd(DOMAIN_ID:String)
    {
        let URL_HEROES = "https://jeeng-server.azurewebsites.net/api/push-monetization?domain_id="+DOMAIN_ID+"&user_id=1234567890";        //creating a NSURL
        let urli = NSURL(string: URL_HEROES)
        
        //fetching the data from the url
        URLSession.shared.dataTask(with: (urli as? URL)!, completionHandler: {(data, response, error) -> Void in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary {
                self.action = jsonObj.value(forKey: "click_action") as? String ?? "www.ynet.co.il"
                let content = UNMutableNotificationContent()
                content.title =  jsonObj.value(forKey: "title") as? String ?? "error"
                content.subtitle = ""
                content.body =  jsonObj.value(forKey: "body") as? String ?? "error"
                content.badge = 1
                content.sound = nil
                let identifier = ProcessInfo.processInfo.globallyUniqueString
                let url = NSURL(string: jsonObj.value(forKey: "image") as? String ?? "error")
                let data = NSData(contentsOf : url! as URL)
                let myImage = UIImage(data : data! as Data)
                if let attachment = UNNotificationAttachment.create(identifier: identifier, image: myImage!, options: nil) {
                    content.attachments = [attachment]
                }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let requestIdentifier = "notification"
                let request =   UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().delegate = self
                UNUserNotificationCenter.current().add(request, withCompletionHandler:{error in})
                let aurl = URL (string:  self.action);
                let arequest = URLRequest(url: aurl!)
                DispatchQueue.main.async {
                    self.webView.navigationDelegate = self
                    self.webView.load(arequest);
                }
            }
        }).resume()
    }
    
    //this allow the notification to show while the app is in foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    //detect user clicked notification to show the webview in the application
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("notification tapped here")
        self.contentView.isHidden=false
        
    }}

extension UNNotificationAttachment {
    //incharge of creating the image from the notification
    static func create(identifier: String, image: UIImage, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let tmpSubFolderName = ProcessInfo.processInfo.globallyUniqueString
        let tmpSubFolderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpSubFolderName, isDirectory: true)
        do {
            try fileManager.createDirectory(at: tmpSubFolderURL, withIntermediateDirectories: true, attributes: nil)
            let imageFileIdentifier = identifier+".png"
            let fileURL = tmpSubFolderURL.appendingPathComponent(imageFileIdentifier)
            guard let imageData = image.pngData() else {
                return nil
            }
            try imageData.write(to: fileURL)
            let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
            return imageAttachment
        } catch {
            print("error " + error.localizedDescription)
        }
        return nil
    }
}
