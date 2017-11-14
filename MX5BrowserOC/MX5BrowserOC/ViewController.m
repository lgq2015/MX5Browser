//
//  ViewController.m
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

#import "ViewController.h"
#import "MX5Browser.h"
#import "MX5WebView.h"

@interface ViewController ()<MX5WebViewDelegate>
@property (nonatomic, strong) MX5WebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"测试MX5";
    
    self.webView = [[MX5WebView alloc]initWithFrame:CGRectMake(0, kStatusBarHeight+kNavBarHeight, KScreenWidth, KScreenHeight-(kStatusBarHeight+kNavBarHeight))];
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    [self.webView loadWebURLSring:@"http://www.baidu.com/"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 点击测试MX5Browser
 */
- (IBAction)onClickTestBrowser:(id)sender {
    
//    MX5BrowserViewController *browserViewController = [[MX5BrowserViewController alloc] init];
//    [self.navigationController pushViewController:browserViewController animated:YES];
    
    
}

@end
