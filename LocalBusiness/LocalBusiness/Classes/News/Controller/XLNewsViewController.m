//
//  XLNewsViewController.m
//  0810电商项目
//
//  Created by Jason on 15/8/10.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "XLNewsViewController.h"

@interface XLNewsViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation XLNewsViewController

- (void)loadView {
    self.view = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.webView = (UIWebView *)self.view;
    self.webView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView.scalesPageToFit = YES;
    NSURL *url = [NSURL URLWithString:@"http://www.qd-life.com/news&src=webview"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate 

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self showActivityHUD];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self hideActivityHUD];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
