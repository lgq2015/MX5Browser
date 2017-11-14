//
//  MX5WebView.m
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

#import "MX5WebView.h"
#import "MX5Browser.h"

static void *WkwebBrowserContext = &WkwebBrowserContext;

@interface MX5BrowserProcessPool()
@property (nonatomic, strong) WKProcessPool *pool;
@end

@implementation MX5BrowserProcessPool

+ (instancetype)sharedInstance{
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance= [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.pool = [WKProcessPool new];
    }
    return self;
}

- (WKProcessPool *)defaultPool{
    return self.pool;
}

@end

@interface MX5WebView()

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, copy) NSString *title;
//设置加载进度条
@property (nonatomic,strong) UIProgressView *progressView;
//保存请求链接
@property (nonatomic) NSMutableArray* snapShotsArray;
//保存的网址链接
@property (nonatomic, copy) NSString *URLString;
//设置缓存时间（过期时间默认为一周）
@property(nonatomic,assign) NSTimeInterval timeoutInterval;

@property (nonatomic, strong) UIView *testView;
@end

@implementation MX5WebView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initWKWebView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self){
        [self initWKWebView];
    }
    return self;
}

/**
 初始化WKWebView视图
 */
-(void)initWKWebView {
    
    [self.wkWebView setFrame:self.bounds];
    [self.wkWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    //添加WKWebView
    [self addSubview:self.wkWebView];
    //添加进度条
    [self addSubview:self.progressView];
    
}

-(void)dealloc {
    
    DDLogDebug(@"MX5WebView dealloc");
    
    self.wkWebView.UIDelegate = nil;
    self.wkWebView.navigationDelegate = nil;
    [self.wkWebView scrollView].delegate = nil;
    
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [self.wkWebView removeObserver:self forKeyPath:@"title"];
    
    [self.wkWebView stopLoading];
    [self.wkWebView  removeFromSuperview];
    self.wkWebView = nil;
}

#pragma mark - 对外接口

-(UIScrollView *)scrollView {
    return [self scrollView];
}

#pragma mark - 自定义返回/关闭按钮
-(void)updateNavigationItems{
  
    if(_delegate && [_delegate respondsToSelector:@selector(updateNavigationItems:)]){
        [self.delegate updateNavigationItems:self];
    }
}

#pragma mark - 私有方法

- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self findTopViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self findTopViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)findTopViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self findTopViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self findTopViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request{
    DDLogDebug(@"push with request %@",request);
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject] objectForKey:@"request"];
    
    //如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        DDLogDebug(@"about blank!! return");
        return;
    }
    
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    UIView* currentSnapShotView = [self.wkWebView snapshotViewAfterScreenUpdates:YES];
    [self.snapShotsArray addObject:
     @{@"request":request,@"snapShotView":currentSnapShotView}];
}

#pragma mark - KVO监听事件
//KVO监听进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
                
            }];
        }
    }else if ([keyPath isEqualToString:@"title"]) {
        _title = self.wkWebView.title;
        
        if(_delegate && [_delegate respondsToSelector:@selector(updateWebViewTitle:)]){
            [self.delegate updateWebViewTitle:self];
        }
        
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 委托方法
#pragma mark - WKNavigationDelegate

//这个是网页加载完成，导航的变化
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    DDLogDebug(@"页面加载完成");

    // 获取加载网页的标题
    self.title = self.wkWebView.title;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
    
     if(_delegate && [_delegate respondsToSelector:@selector(webViewDidFinishLoad:)]){
        [self.delegate webViewDidFinishLoad:self];
    }
}

//开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    //开始加载的时候，让加载进度条显示
    self.progressView.hidden = NO;
    DDLogDebug(@"页面开始加载");
    NSString *metaJScript = @"document.getElementsByTagName('html')[0].setAttribute('manifest','demo_html.appcache');";
    [self.wkWebView evaluateJavaScript:metaJScript completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        DDLogDebug(@"value: %@ error: %@", response, error);
    }];
    
    if(_delegate && [_delegate respondsToSelector:@selector(webViewDidStartLoad:)]){
        [self.delegate webViewDidStartLoad:self];
    }
    
}
// 加载内容
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    DDLogDebug(@"内容正在加载当中");
}

//接收到服务器重新配置请求之后再执行(接收到服务器跳转请求之后调用)
-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    DDLogDebug(@"接收到服务器重新配置请求之后再执行");
}

//API是根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转（在发送请求之前，决定是否跳转）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    DDLogDebug(@"API是根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转");

    
    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeFormSubmitted: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        case WKNavigationTypeBackForward: {
            break;
        }
        case WKNavigationTypeReload: {
            
            break;
        }
        case WKNavigationTypeFormResubmitted: {
            break;
        }
        case WKNavigationTypeOther: {
            [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
            break;
        }
        default: {
            break;
        }
    }
    [self updateNavigationItems];
    //允许跳转
    decisionHandler(WKNavigationActionPolicyAllow);
    //不允许跳转
    //decisionHandler(WKNavigationActionPolicyCancel);
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    DDLogDebug(@"decidePolicyForNavigationResponse   ====    %@", navigationResponse);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

// 加载 HTTPS 的链接，需要权限认证时调用  \  如果 HTTPS 是用的证书在信任列表中这不要此代理方法
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}

// 内容加载失败时候调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    DDLogDebug(@"页面加载超时");
     if(_delegate && [_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]){
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
     if(_delegate && [_delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]){
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

//进度条
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
    
}

#pragma mark - WKUIDelegate

// 获取js 里面的提示
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    UIViewController *tpVCL = [self topViewController];
    [tpVCL presentViewController:alert animated:YES completion:NULL];
}

// js 信息的交流
-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    UIViewController *tpVCL = [self topViewController];
    [tpVCL presentViewController:alert animated:YES completion:NULL];
}

// runJavaScriptTextInput
// 要求用户输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS 大家注意这个回调的completionHandler参数是字符串
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入框" message:prompt preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor blackColor];
        textField.placeholder = defaultText;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
    }]];
    UIViewController *tpVCL = [self topViewController];
    [tpVCL presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
}

#pragma mark - 懒加载

- (WKWebView *)wkWebView{
    if (!_wkWebView) {
        
        //设置网页的配置文件
        WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];
        //这个值决定了从这个页面是否可以Air Play
        if (@available(iOS 9.0, *)) {
            Configuration.allowsAirPlayForMediaPlayback = YES;
            // 在iPhone和iPad上默认使YES。这个值决定了HTML5视频可以自动播放还是需要用户去启动播放
            Configuration.requiresUserActionForMediaPlayback = NO;
        }
        // 允许在线播放 ,默认使NO。这个值决定了用内嵌HTML5播放视频还是用本地的全屏控制。为了内嵌视频播放，不仅仅需要在这个页面上设置这个属性，还必须的是在HTML中的video元素必须包含webkit-playsinline属性。
        if (@available(iOS 11.0, *)) {
            Configuration.allowsInlineMediaPlayback = YES;
        }else{
            Configuration.allowsInlineMediaPlayback = NO;
        }
        Configuration.allowsInlineMediaPlayback = YES;
        // 创建设置对象
        WKPreferences *preference = [[WKPreferences alloc]init];
        // 设置字体大小(最小的字体大小)
        //preference.minimumFontSize = self.minimumFontSize;
        // 设置偏好设置对象
        Configuration.preferences = preference;
        
        // 允许可以与网页交互，选择视图
        Configuration.selectionGranularity = YES;
        // web内容处理池
        Configuration.processPool = [[MX5BrowserProcessPool sharedInstance] defaultPool];
        
        //自定义配置,一般用于 js调用oc方法(OC拦截URL中的数据做自定义操作)
        WKUserContentController * UserContentController = [[WKUserContentController alloc]init];
        // 添加消息处理，注意：self指代的对象需要遵守WKScriptMessageHandler协议，结束时需要移除
        //[UserContentController addScriptMessageHandler:(id)self.ocjsHelper name:KWebGetDeviceID];
        
        // 是否支持记忆读取
        Configuration.suppressesIncrementalRendering = YES;
        // 允许用户更改网页的设置
        Configuration.userContentController = UserContentController;
        
        
        _wkWebView = [[WKWebView alloc] initWithFrame:self.bounds configuration:Configuration];
        _wkWebView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];
        // 设置代理
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
        _wkWebView.scrollView.delegate = self;
        
        NSKeyValueObservingOptions observingOptions = NSKeyValueObservingOptionNew;
        // KVO 监听属性，除了下面列举的两个，还有其他的一些属性，具体参考 WKWebView 的头文件
        //kvo 添加进度监控
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:observingOptions context:WkwebBrowserContext];
        [_wkWebView addObserver:self forKeyPath:@"title" options:observingOptions context:nil];
        
        //开启手势触摸
        _wkWebView.allowsBackForwardNavigationGestures = YES;
        
        // 设置 可以前进 和 后退
        //适应你设定的尺寸
        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}

- (UIProgressView *)progressView{
    
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , 3);
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}

-(NSMutableArray*)snapShotsArray{
    if (!_snapShotsArray) {
        _snapShotsArray = [NSMutableArray array];
    }
    return _snapShotsArray;
}

-(NSTimeInterval )timeoutInterval {
    if (!_timeoutInterval) {
        _timeoutInterval = 1000 * 60 * 60 * 24 * 7;  //默认缓存时间为1周的时间
    }
    return _timeoutInterval;
}

#pragma mark - 初始化URL/对外扩展方法

- (void)loadWebURLSring:(NSString *)urlString{
    
    self.URLString  = urlString;
    //创建一个NSURLRequest 的对象,加入缓存机制，缓存时间为默认为一周
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:self.timeoutInterval];
    //加载网页
    [self.wkWebView loadRequest:urlRequest];
}

-(BOOL)isLoading{
    return [self.wkWebView isLoading];
}

-(BOOL)canGoBack{
    return [self.wkWebView canGoBack];
}

-(BOOL)canGoForward{
    return [self.wkWebView canGoForward];
}

- (id)goBack{
   return [self.wkWebView goBack];
}

- (id)goForward{
    return [self.wkWebView goForward];
}

- (id)reload{
    return [self.wkWebView reload];
}

- (id)reloadFromOrigin{
    return [self.wkWebView reloadFromOrigin];
}

- (void)stopLoading{
    [self.wkWebView stopLoading];
}

+ (void)removeCache {
  
    
}


@end
