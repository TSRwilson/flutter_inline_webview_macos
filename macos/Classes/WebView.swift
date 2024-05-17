//
//  WebView.swift
//  flutter_webview_macos
//
//  Created by redstar16 on 2022/08/18.
//

import FlutterMacOS
import Foundation
import WebKit

public class InAppWebViewMacos: WKWebView
, WKUIDelegate, WKNavigationDelegate,
  WKScriptMessageHandler
{

   @objc(userContentController:didReceiveScriptMessage:)
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        channel?.invokeMethod("onReceivedData", arguments: message.body as! String)
    }

  var windowId: Int64?
  var windowCreated = false
  var channel: FlutterMethodChannel?
  var currentOriginalUrl: URL?

init(frame: CGRect, configuration: WKWebViewConfiguration, channel: FlutterMethodChannel?) {
        super.init(frame: frame, configuration: configuration)
        self.channel = channel
         self.navigationDelegate = self // Assigning self as the navigation delegate
    }

  required public init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }

  public func goBackOrForward(steps: Int) {
    if canGoBackOrForward(steps: steps) {
      if steps > 0 {
        let index = steps - 1
        go(to: self.backForwardList.forwardList[index])
      } else if steps < 0 {
        let backListLength = self.backForwardList.backList.count
        let index = backListLength + steps
        go(to: self.backForwardList.backList[index])
      }
    }
  }
    
    

  public func canGoBackOrForward(steps: Int) -> Bool {
    let currentIndex = self.backForwardList.backList.count
    return (steps >= 0)
      ? steps <= self.backForwardList.forwardList.count
      : currentIndex + steps >= 0
  }

  public func loadUrl(urlRequest: URLRequest, allowingReadAccessTo: URL?) {
      let url = urlRequest.url!

         // Print the URL before loading
         print("Loading URL: \(url.absoluteString)")

         if #available(iOS 9.0, *), let allowingReadAccessTo = allowingReadAccessTo,
             url.scheme == "file", allowingReadAccessTo.scheme == "file"
         {
             loadFileURL(url, allowingReadAccessTo: allowingReadAccessTo)
         } else {
             load(urlRequest)
         }
  }

  public func loadData(
    data: String, mimeType: String, encoding: String, baseUrl: URL, allowingReadAccessTo: URL?
  ) {
    if #available(iOS 9.0, *), let allowingReadAccessTo = allowingReadAccessTo,
      baseUrl.scheme == "file", allowingReadAccessTo.scheme == "file"
    {
      loadFileURL(baseUrl, allowingReadAccessTo: allowingReadAccessTo)
    }

    if #available(iOS 9.0, *) {
      load(
        data.data(using: .utf8)!, mimeType: mimeType, characterEncodingName: encoding,
        baseURL: baseUrl)
    } else {
      loadHTMLString(data, baseURL: baseUrl)
    }
  }

  public func clearCache() {
    if #available(iOS 9.0, *) {
      //let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
      let date = NSDate(timeIntervalSince1970: 0)
      WKWebsiteDataStore.default().removeData(
        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: date as Date,
        completionHandler: {})
    } else {
      var libraryPath = NSSearchPathForDirectoriesInDomains(
        FileManager.SearchPathDirectory.libraryDirectory,
        FileManager.SearchPathDomainMask.userDomainMask, false
      ).first!
      libraryPath += "/Cookies"

      do {
        try FileManager.default.removeItem(atPath: libraryPath)
      } catch {
      }
      URLCache.shared.removeAllCachedResponses()
    }
  }

 public func webView(
    _ webView: WKWebView, 
    didStartProvisionalNavigation navigation: WKNavigation!
) {
    onLoadStart(url: webView.url?.absoluteString as String?)
}
public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if let url = webView.url {
        print("load finish URL: \(url.absoluteString)")
          onLoadStop(url: url.absoluteString)
    } else {
        print("URL is nil")
    }
}

 public func webView(
    _ view: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
) {
    print("Failed to load URL: \(view.url?.absoluteString ?? "Unknown")")
       print("Error: \(error.localizedDescription)")
    onLoadError(url: view.url?.absoluteString, error: error)
}
    
    public  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed during loading: \(error.localizedDescription)")
        onLoadError(url: webView.url?.absoluteString, error: error)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            let description = httpResponse.description
            print("HTTP Status Code: \(statusCode)")
            if (statusCode != 200) {
                onLoadHttpError(url: webView.url?.absoluteString, statusCode: statusCode, description: description)
            }
            decisionHandler(.allow)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, webContentProcessDidTerminate webContentView: WKWebView) {
        print("Web content process terminated. Reloading...")
        webView.reload()
    }

  public func webViewDidClose(_ webView: WKWebView) {
    let arguments: [String: Any?] = [:]
    channel?.invokeMethod("onCloseWindow", arguments: arguments)
  }

  public func onLoadStart(url: String?) {
    let arguments: [String: Any?] = ["url": url]
    channel?.invokeMethod("onLoadStart", arguments: arguments)
  }

  public func onLoadStop(url: String?) {
    let arguments: [String: Any?] = ["url": url]
    channel?.invokeMethod("onLoadStop", arguments: arguments)
      
     
  }

  

  public func onLoadError(url: String?, error: Error) {
    let arguments: [String: Any?] = [
      "url": url, "code": error._code, "message": error.localizedDescription,
    ]
    channel?.invokeMethod("onLoadError", arguments: arguments)
  }

  public func onLoadHttpError(url: String?, statusCode: Int, description: String) {
    let arguments: [String: Any?] = [
      "url": url, "statusCode": statusCode, "description": description,
    ]
    channel?.invokeMethod("onLoadHttpError", arguments: arguments)
  }
    
    public func channelName (channelName : String?) {
        configuration.userContentController.add(self, name: channelName!)
    }

    public func runJavaScriptWithResult (script : String?) {
       evaluateJavaScript(script!, completionHandler: { (result, error) in
          if let error = error {
              print("Error evaluating JavaScript: \(error.localizedDescription)")
          } else {
              print("JavaScript result: \(String(describing: result))")
          }
      })
    }
  

  public func getOriginalUrl() -> URL? {
    return currentOriginalUrl
  }

  public func dispose() {
    channel = nil
    // removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    // removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
    // removeObserver(self, forKeyPath: #keyPath(WKWebView.title))

//    stopLoading()

//    NotificationCenter.default.removeObserver(self)
//    uiDelegate = nil
//    navigationDelegate = nil
    super.removeFromSuperview()
  }

  deinit {
    dispose()
  }
}
