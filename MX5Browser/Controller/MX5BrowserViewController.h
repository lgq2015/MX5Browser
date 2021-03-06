//
//  MX5BrowserViewController.h
//  MX5BrowserOC
//
//  Created by kingly on 2017/11/10.
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
#import "MX5WebView.h"

NS_ASSUME_NONNULL_BEGIN


/**
 注入带填写对象
 */

@protocol MX5InjectionModel <NSObject>

@end

@interface MX5InjectionModel : NSObject

@property (nonatomic,copy) NSString *shareId;       //分享ID
@property (nonatomic,copy) NSString *shareUrl;      //分享地址

@property (nonatomic,copy) NSString *cookieId;      //cookieId
@property (nonatomic,copy) NSString *cookies;       //cookie内容

@property (nonatomic,copy) NSString *fillinJsCode;  //带填写脚本
@property (nonatomic,copy) NSString *username;      //登录名
@property (nonatomic,copy) NSString *password;      //密码



@end

/**
 请求方式
 
 - MX5WebViewTypeWebURLString: 请求网路链接
 - MX5WebViewTypeLocalHTMLString: 请求本地html文件
 - MX5WebViewTypeAutomaticLogin: 请求带填登录
 - MX5WebViewTypeAutomaticLoginCookie: 请求带填登录(注入Cookie)
 - MX5WebViewTypeHTMLString: 请求html字符串或本地html字符串
 */
typedef NS_ENUM(NSUInteger, MX5WebViewType){
  MX5WebViewTypeWebURLString = 0,
  MX5WebViewTypeLocalHTMLString = 1,
  MX5WebViewTypeAutomaticLogin = 2,
  MX5WebViewTypeAutomaticLoginCookie = 3,
  MX5WebViewTypeHTMLString= 4
};


@class MX5WebView;

@protocol MX5BrowserViewControllerDelegate <NSObject>
@optional

/**
 点击收藏
 
 @param webView MX5WebView
 */
-(void)browserViewControllerWithCollection:(MX5WebView *)webView;

@end

/**
 整个浏览器的主框架
 */
@interface MX5BrowserViewController : UIViewController

@property (nonatomic) BOOL isHideBottomToolBar;     //是否隐藏底部导航条
@property (nonatomic,strong) NSArray *menuList;     //底部菜单数组
@property(nonatomic,assign) BOOL needInjectJS;      //是否需要注入js代码
@property(nonatomic,assign) BOOL tabBarHidden;      //是否隐藏tabBar
@property(nonatomic,assign) BOOL navigationBarHidden;      //是否隐藏tabBar
@property(nonatomic,weak)id<MX5BrowserViewControllerDelegate> delegate;
@property(nonatomic,assign) BOOL hiddenCollectionButtonItem;      //隐藏导航条上的收藏按钮
@property(nonatomic,assign) BOOL hiddenRightButtonItem;           //隐藏导航条上的右边按钮
@property(nonatomic,assign) BOOL isDeleteHTTPCookie;              //是否删除HTTPCookie

/**
 加载底部菜单
 @param menuList 菜单列表
 */
- (void)loadMenuView:(NSArray *)menuList;
/**
 加载纯外部链接网页
 
 @param urlString URL地址
 */
- (void)loadWebURLSring:(NSString *)urlString;

/**
 加载本地html
 @param htmlPath html的文件路径地址
 */
- (void)loadLocalHTMLStringWithHtmlPath:(NSString *)htmlPath;
/**
 自动带填登录
 
 @param urlString 需要带填的URL地址
 @param JSCode 注入js
 */
- (void)loadAutomaticLogin:(NSString *)urlString injectJSCode:(NSString *)JSCode;
/**
 自动带填登录（目前支持 爱奇艺，腾讯视频，芒果TV，优酷的代填功能）
 
 @param urlString urlString 需要带填的URL地址
 @param JSCode  注入js
 @param username 用户名
 @param pwd 密码
 */
- (void)loadAutomaticLogin:(NSString *)urlString injectJSCode:(NSString *)JSCode withUserName:(NSString *)username withPwd:(NSString *)pwd;
/**
 自动带填登录（目前支持 爱奇艺) 注入cookie
 
 @param urlString 需要注入的网址
 @param JSCode  注入js带填登录
 @param cookie 注入cookie
 @param username 用户名
 @param pwd 密码
 */
- (void)loadAutomaticLogin:(NSString *)urlString
              injectJSCode:(NSString *)JSCode
                withCookie:(NSString *)cookie
              withUserName:(NSString *)username
                   withPwd:(NSString *)pwd;

/**
  自动带填登录（目前支持 爱奇艺) 注入cookie

 @param injectionModel 注入cookie对象
 */
- (void)loadAutomaticLogin:(MX5InjectionModel *)injectionModel;
/**
 加载带有HTML字符串
 @param htmlString 带有HTML字符串
 */
- (void)loadHTMLString:(NSString *)htmlString;
/**
 点击收藏对外
 @param webView MX5WebView
 */
-(void)browserViewClickCollection:(MX5WebView *)webView;
/**
 对外接受js反射对象
 
 @param webView 当前浏览器
 @param receiveScriptMessage js接受对象
 */
- (void)currWebView:(MX5WebView *)webView didReceiveScriptMessage:(NSDictionary *)receiveScriptMessage;
/**
 点击返回按钮对外
 @param webView MX5WebView
 */
-(void)browserViewOnClickCustomBackItem:(MX5WebView *)webView;
/**
 点击关闭web视图
 */
-(void)closeItemClicked;
/**
 删除HTTPCookie
 */
- (void)deleteHTTPCookie;

NS_ASSUME_NONNULL_END

@end

