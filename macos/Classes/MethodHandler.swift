//
//  MethodHandler.swift
//  flutter_webview_macos
//
//  Created by redstar16 on 2022/08/18.
//

import FlutterMacOS
import Foundation
import WebKit

public class FlutterMethodCallDelegate: NSObject {
  public override init() {
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

  }
}

public class InAppWebViewMacosMethodHandler: FlutterMethodCallDelegate {
  var controller: FlutterWebViewMacosController?

  init(
    controller: FlutterWebViewMacosController
  ) {
    super.init()
    self.controller = controller
  }

  public override func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]

    switch call.method {
    case "create":
      let frame = CGRect(x: 0, y: 0, width: 800, height: 600)
      controller!.create(frame: frame)
      result(true)

    case "changeSize":
    do {
    var height = 800
    var width = 600
    
    if let heightValue = arguments?["height"] as? Int {
        height = heightValue
    }
    
    if let widthValue = arguments?["width"] as? Int {
        width = widthValue
    }
    
    let frame = CGRect(x: 0, y: 0, width: width, height: height)
    controller?.changeSize(frame: frame)
    
    result(true)
} catch {
    // Handle error
    print("An error occurred: \(error)")
}

    case "dispose":
      controller!.dispose()
      result(true)

    case "loadUrl":
      let urlRequest = arguments!["urlRequest"] as! [String: Any?]
      let allowingReadAccessTo = arguments!["allowingReadAccessTo"] as? String
      var allowingReadAccessToURL: URL? = nil
      if let allowingReadAccessTo = allowingReadAccessTo {
        allowingReadAccessToURL = URL(string: allowingReadAccessTo)
      }

    // FIXME: Don't really want to sleep, but it crashes when I load it continuously.
    Thread.sleep(forTimeInterval: 1)

    controller!.webView!.loadUrl(
        urlRequest: URLRequest.init(fromPluginMap: urlRequest),
        allowingReadAccessTo: allowingReadAccessToURL)

    result(true)

    case "getUrl":
      let url = controller!.webView!.getOriginalUrl()
      result(url?.baseURL)
    case "channelName":
        if let args = arguments,
              let channelName = args["channelName"] as? String {
               // Call the function or method that requires a String argument
               controller?.webView?.channelName(channelName: channelName)
           } else {
               print("Error: channelName is not a string or arguments are not valid.")
           }
    break;
      case "script":
        if let args = arguments,
              let script = args["script"] as? String {
               // Call the function or method that requires a String argument
               controller?.webView?.runJavaScriptWithResult(script: script)
           } else {
               print("Error: script is not a string or arguments are not valid.")
           }
    break;
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func dispose() {
      controller = nil
  }

  deinit {
    dispose()
  }
}
