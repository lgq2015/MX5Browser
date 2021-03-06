//
//  MX5WebViewJavascriptBridge.h
//  MX5BrowserOC
//
//  Created by kingly on 2017/12/4.
//  Copyright © 2017年 MX5Browser Software https://github.com/kingly09/MX5Browser  by kingly inc.  

//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#define KWebGetDeviceID @"epass"      //把一个名为 epass 的 ScriptMessageHandler 注册到我们的 wk。

@protocol MX5WebViewJavascriptBridgeDelegate <NSObject>

/**
 收到js发送过来的消息

 @param receiveScriptMessage  字典类型的消息体
 */
-(void)MX5WebViewJavascriptBridgeDidReceiveScriptMessage:(NSDictionary *)receiveScriptMessage;

@end

@interface MX5WebViewJavascriptBridge : NSObject<WKScriptMessageHandler>
@property (nonatomic, weak) id<MX5WebViewJavascriptBridgeDelegate> delegate;
@property (nonatomic, weak) WKWebView *webView;
//消息对象key值
@property (nonatomic, copy) NSString *scriptMessageHandlerName;
/**
 指定初始化方法
 
 @param delegate 代理
 @param vc 实现WebView的VC
 @return 返回自身实例
 */
- (instancetype)initWithDelegate:(id<MX5WebViewJavascriptBridgeDelegate>)delegate vc:(UIViewController *)vc;
@end
