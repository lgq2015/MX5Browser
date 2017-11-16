//
//  MX5BrowserViewController.m
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

#import "MX5BrowserViewController.h"
#import "MX5Browser.h"
#import "MX5WebView.h"
#import "MX5BrowserURLCache.h"
#import "MX5BottomToolBar.h"
#import "MX5BrowserUtils.h"

@interface MX5BrowserViewController ()<MX5WebViewDelegate,MX5BottomToolBarDelegate> {
    
    float bottomToolBarY;
    UIButton *roadLoadButton; //右边按钮
}
@property (nonatomic, strong) MX5WebView *webView;
@property (nonatomic, strong) MX5BottomToolBar *bottomToolBar;

//返回按钮
@property (nonatomic) UIBarButtonItem *customBackBarItem;
//关闭按钮
@property (nonatomic) UIBarButtonItem *closeButtonItem;
//打开链接
@property (nonatomic,copy) NSString  *webURLSring;
//本地HTML路径
@property (nonatomic,copy) NSString  *htmlPath;
//HTML代码字符串
@property (nonatomic,copy) NSString  *htmlString;
//注入js代码
@property (nonatomic, copy) NSString *injectJSCode;
//网页加载的类型
@property(nonatomic,assign) MX5WebViewType webViewType;

@end

@implementation MX5BrowserViewController

#pragma mark - 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self webViewCache];
    
    //初始化WebView
    [self setupWebView];
    //初始化视图
    [self initializeView];
    //加载
    [self webViewloadURLType];
}

- (void)webViewloadURLType {
    
    if (self.webViewType == MX5WebViewTypeWebURLString) {
        //加载webURLSring
        [self.webView loadWebURLSring:_webURLSring];
        
    }else  if (self.webViewType == MX5WebViewTypeLocalHTMLString) {
        
        //获得html内容
        NSString *html = [[NSString alloc] initWithContentsOfFile:self.htmlPath encoding:NSUTF8StringEncoding error:nil];
        //加载js
        [self.webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
        
    }else  if (self.webViewType == MX5WebViewTypeAutomaticLogin) {
        
        [self.webView loadWebURLSring:_webURLSring];
        
    }else  if (self.webViewType == MX5WebViewTypeHTMLString) {
        //加载js
        [self.webView loadHTMLString:self.htmlString baseURL:[[NSBundle mainBundle] bundleURL]];
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
     self.navigationController.navigationBarHidden = NO;
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:YES];
    
    [self.webView.wkWebView setNavigationDelegate:nil];
    [self.webView.wkWebView setUIDelegate:nil];
    self.webView = nil;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    MX5BrowserURLCache *urlCache = (MX5BrowserURLCache *)[NSURLCache sharedURLCache];
    [urlCache removeAllCachedResponses];
}

- (void)dealloc {
    
    DDLogDebug(@" MX5BrowserViewController dealloc ");
}

#pragma mark - 初始化数据

-(void)initializeView {
    
  [self navigationItemView];
    
     bottomToolBarY = KScreenHeight - KBOTTOM_TOOL_BAR_HEIGHT;
    if (iPhoneX) {
        bottomToolBarY = KScreenHeight - KBOTTOM_TOOL_BAR_HEIGHT - 20;
    }
    self.bottomToolBar = [[MX5BottomToolBar alloc] initWithFrame:CGRectMake(0, bottomToolBarY, KScreenWidth, KBOTTOM_TOOL_BAR_HEIGHT) withParentview:self.view];
    self.bottomToolBar.userInteractionEnabled = YES;
    self.bottomToolBar.delegate = self;
    [self.view addSubview:self.bottomToolBar];
    
    if (_isHideBottomToolBar == YES) {
        [self hiddenBottomToolBar];
    }else{
        [self showBottomToolBar];
        if (_menuList.count > 0) {
             [self.bottomToolBar reloadMenuView:_menuList];
        }
    }

}

/**
 显示底部导航
 */
- (void)showBottomToolBar {
    
    self.bottomToolBar.hidden = NO;
    [roadLoadButton setImage:[UIImage imageNamed:@"m_ic_sx"] forState:UIControlStateNormal];
    self.bottomToolBar.frame = CGRectMake(0, bottomToolBarY, KScreenWidth, KBOTTOM_TOOL_BAR_HEIGHT);
    self.webView.frame       = CGRectMake(0, kStatusBarHeight+kNavBarHeight, KScreenWidth, KScreenHeight-(kStatusBarHeight+kNavBarHeight) - KBOTTOM_TOOL_BAR_HEIGHT);
}

/**
 隐藏底部导航
 */
- (void)hiddenBottomToolBar {
    
    self.bottomToolBar.hidden = YES;
    [roadLoadButton setImage:[UIImage imageNamed:@"m_ic_apply"] forState:UIControlStateNormal];
    self.webView.frame       = CGRectMake(0, kStatusBarHeight+kNavBarHeight, KScreenWidth, KScreenHeight-(kStatusBarHeight+kNavBarHeight));
}

/**
 初始化WebView
 */
-(void)setupWebView {
    
    self.view.backgroundColor = [UIColor whiteColor];
    float bottomToolBarHight = (_isHideBottomToolBar == YES)?0:KBOTTOM_TOOL_BAR_HEIGHT;
    self.webView = [[MX5WebView alloc]initWithFrame:CGRectMake(0, kStatusBarHeight+kNavBarHeight, KScreenWidth, KScreenHeight-(kStatusBarHeight+kNavBarHeight) - bottomToolBarHight)];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
}

-(void)navigationItemView{
    
    //添加右边刷新按钮
    roadLoadButton = [[UIButton alloc] init];
    roadLoadButton.size = CGSizeMake(22,22);
    [roadLoadButton adjustsImageWhenHighlighted];
    [roadLoadButton adjustsImageWhenDisabled];
    [roadLoadButton setImage:[UIImage imageNamed:@"m_ic_sx"] forState:UIControlStateNormal];
    [roadLoadButton addTarget:self action:@selector(roadLoadClicked) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:roadLoadButton];
}


// 网页缓存设置
-(void) webViewCache {
    //网页缓存设置
    MX5BrowserURLCache *urlCache = [[MX5BrowserURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024
                                                                 diskCapacity:200 * 1024 * 1024
                                                                     diskPath:nil
                                                                    cacheTime:0];
    [MX5BrowserURLCache setSharedURLCache:urlCache];
    
}

#pragma mark - 点击事件

/**
 重新加载网页
 */
- (void)roadLoadClicked {
   
    //当前是内页的时候，不显示底部自定义菜单
    if (self.bottomToolBar.hidden == YES) {
#warning 当前是内页的时候，不显示底部自定义菜单
        
    }else {
        
        [self.webView reload];
    }

}

/**
 返回上一个网页
 */
- (void)customBackItemClicked{
    
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/**
 点击关闭web视图
 */
-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MX5WebViewDelegate

/**
 webView开始加载
 */
- (void)webViewDidStartLoad:(MX5WebView *)webView {
    
}
/**
 webView加载完成
 */
- (void)webViewDidFinishLoad:(MX5WebView *)webView {
    self.title = webView.title;
    [self updateNavigationItems:webView];
}
/**
 加载webView失败
 
 @param webView MX5WebView
 @param error 失败消息
 */
- (void)webView:(MX5WebView *)webView didFailLoadWithError:(NSError *)error {
    
    
}
/**
 更新导航条
 */
- (void)updateNavigationItems:(MX5WebView *)webView {
    
    UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceButtonItem.width = -6.5;
    if (webView.canGoBack) {
        
        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem,self.closeButtonItem,spaceButtonItem] animated:NO];
        [self hiddenBottomToolBar];
        
    }else{
        if (_isHideBottomToolBar) {
            [self hiddenBottomToolBar];
        }else{
            [self showBottomToolBar];
        }
       
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem,spaceButtonItem]];
    }
}
/**
 更新web视图的title
 */
- (void)updateWebViewTitle:(MX5WebView *)webView {
     self.title = webView.title;
}

#pragma mark - MX5BottomToolBarDelegate
/**
 点击自定义的一级菜单
 
 @param buttonModel 一级菜单对象
 */
-(void)onClickBottomToolBarWithMemubutton:(MX5ButtonModel *)buttonModel {
    
}
/**
 点击自定义的二级菜单
 @param buttonModel 二级菜单对象
 */
-(void)onClickBottomToolBarWithSubMemubutton:(MX5SubButtonModel *)buttonModel {
    
    if ([MX5BrowserUtils isURL:buttonModel.url]) {
        MX5BrowserViewController *browserViewController = [[MX5BrowserViewController alloc] init];
        browserViewController.menuList = _menuList;
        browserViewController.isHideBottomToolBar = YES;
        [browserViewController loadWebURLSring:buttonModel.url];
        [self.navigationController pushViewController:browserViewController animated:YES];
    
    }else {
        
    }
}

#pragma mark - 初始化URL/对外扩展方法

- (void)loadWebURLSring:(NSString *)urlString {
   
    _webURLSring = urlString;
    
    self.webViewType  = MX5WebViewTypeWebURLString;
}

/**
 加载本地html
 @param htmlPath html的文件路径地址
 */
- (void)loadLocalHTMLStringWithHtmlPath:(NSString *)htmlPath {
    
    self.webViewType  = MX5WebViewTypeLocalHTMLString;
    self.htmlPath     = htmlPath;
}
/**
 自动带填登录
 
 @param urlString 需要带填的URL地址
 @param JSCode 注入js
 */
- (void)loadAutomaticLogin:(NSString *)urlString injectJSCode:(NSString *)JSCode {
    
    _webURLSring = urlString;
    _injectJSCode = JSCode;
    self.webViewType  = MX5WebViewTypeAutomaticLogin;
}
/**
 加载带有HTML字符串
 @param htmlString 带有HTML字符串
 */
- (void)loadHTMLString:(NSString *)htmlString {
    
    self.htmlString   = htmlString;
    self.webViewType  = MX5WebViewTypeHTMLString;
}

#pragma mark - setter and getter 方法
#pragma mark - 懒加载


-(UIBarButtonItem *)customBackBarItem{
    if (!_customBackBarItem) {
        
//        UIImage* backItemImage = [[UIImage imageNamed:@"m_ic_left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//        UIImage* backItemHlImage = [[UIImage imageNamed:@"m_ic_left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//
        UIButton* backButton = [[UIButton alloc] init];
        [backButton adjustsImageWhenHighlighted];
        [backButton adjustsImageWhenDisabled];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor colorWithHexStr:@"#101010"] forState:UIControlStateNormal];
//        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
//        [backButton setImage:backItemImage forState:UIControlStateNormal];
//        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

-(UIBarButtonItem *)closeButtonItem{
    if (!_closeButtonItem) {
        
        UIButton* closeButton = [[UIButton alloc] init];
        [closeButton adjustsImageWhenHighlighted];
        [closeButton adjustsImageWhenDisabled];
        [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
        [closeButton setTitleColor:[UIColor colorWithHexStr:@"#101010"] forState:UIControlStateNormal];
//        [closeButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
//        [closeButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [closeButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
  
        [closeButton addTarget:self action:@selector(closeItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    }
    return _closeButtonItem;
}

@end
