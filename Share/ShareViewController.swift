//
//  ShareViewController.swift
//  Share
//
//  Created by paul on 2024/9/6.
//

import UIKit
import Social
import AVKit
import SafariServices

class ShareViewController: SLComposeServiceViewController {
    static let appGroupId = "group.com.paul90317.YouTube-Background"
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        // 確認 contentText
        guard let contentText = self.contentText, let _ = URL(string: contentText) else {
            return false
        }
        return true;
    }
    
    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.

        guard let contentText = self.contentText, let url = URL(string: contentText), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            print("unvalid URL")
            
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            return;
        }
        
        if url.path == "/watch", let videoId = queryItems.first(where: { $0.name == "v" })?.value, let userDefaults = UserDefaults(suiteName: ShareViewController.appGroupId) {
            userDefaults.set(videoId, forKey: "videoId")
        }
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
