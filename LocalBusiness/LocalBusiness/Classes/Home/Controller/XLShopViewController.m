//
//  XLShopViewController.m
//  LocalBusiness
//
//  Created by Jason on 15/8/15.
//  Copyright (c) 2015年 Jason. All rights reserved.
//

#import "XLShopViewController.h"
#import "XLShopHeaderView.h"
#import "XLShopFooterView.h"
#import "XLShopGoodsViewCell.h"
#import "XLShopCommentViewCell.h"
#import "XLHeaderView.h"
#import "XLShopModel.h"
#import "XLShopLocationViewController.h"
#import "UMSocial.h"
#import "XLLoginViewController.h"

@interface XLShopViewController () <UITableViewDataSource,XLShopHeaderViewDelegate,XLShopFooterViewDelegate,UMSocialUIDelegate,UIActionSheetDelegate>
/**
 *  商家模型
 */
@property (nonatomic, strong) XLShopModel *shopModel;
/**
 *  tableView头
 */
@property (nonatomic, strong) XLShopHeaderView *headerView;
/**
 *  tableViewFooter
 */
@property (nonatomic, strong) XLShopFooterView *footerView;
/**
 *  商家显示商品的个数
 */
@property (nonatomic, assign) int produceCount;
/**
 *  提示框
 */
@property (nonatomic, strong) UIActionSheet *actionSheet;
/**
 *  webView
 */
@property (nonatomic, strong) UIWebView *webVIew;

@end

@implementation XLShopViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setTitle:@"商家详情"];
    [self requestShopData];
    // 设置默认商品数量
    self.produceCount = 2;
    // 设置tableView HeaderView
    self.tableView.tableHeaderView = self.headerView;
    // 设置tableview FooterView
    self.tableView.tableFooterView = self.footerView;
    // 禁用系统分割线
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    
//    动态计算cell高度
//    self.tableView.estimatedRowHeight = 30;
//    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - XLShopHeaderViewDelegate

- (void)shopHeaderView:(XLShopHeaderView *)headerView locationButtonDidClickWithModel:(XLShopModel *)shopModel {
    XLShopLocationViewController *vc = [[XLShopLocationViewController alloc] init];
    [vc.parameter setValue:[NSString stringWithFormat:@"%lf",shopModel.lat] forKey:@"lat"];
    [vc.parameter setValue:[NSString stringWithFormat:@"%lf",shopModel.lon] forKey:@"lon"];
    [vc.parameter setObject:shopModel.address forKey:@"address"];
    [vc.parameter setObject:shopModel.name forKey:@"name"];
    
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)shopHeaderView:(XLShopHeaderView *)headerView phoneButtonDidClickWithModel:(XLShopModel *)shopModel {
    
    // webVIew打电话,记得webView不能定义局部变量
//    [self.webVIew loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",shopModel.phone]]]];
    
    [self.actionSheet setTitle:shopModel.phone];
    [self.actionSheet showInView:self.view];

}

- (void)shopHeaderView:(XLShopHeaderView *)headerView shareButtonDidClickWithModel:(XLShopModel *)shopModel {
    [UMSocialSnsService presentSnsIconSheetView:self
                                          appKey:UMEN_APP_KEY
                                      shareText:[NSString stringWithFormat:@"%@这家店真是太牛逼啦,大家都来啊,地址:%@",shopModel.name,shopModel.address]
                                      shareImage:[UIImage imageNamed:@"icon.png"]
                                 shareToSnsNames:[NSArray arrayWithObjects:UMShareToSina,UMShareToTencent,UMShareToRenren,UMShareToDouban,nil]
                                        delegate:self];
}

#pragma mark - XLShopFooterViewDelegate
/**
 *  发表评论
 */
- (void)shopFooter:(XLShopFooterView *)shopFooterView sendCommentButtonDidClickWith:(ShopCommentModel *)commentModel {
    NSLog(@"%@",commentModel);
    // 将评论添加到模型数组
    [self.shopModel.comment_list insertObject:commentModel atIndex:0];
    // 设置请求参数
    NSString *res_name = @"shop";
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    [para setObject:[NSString stringWithFormat:@"%d",commentModel.user_id] forKey:@"user_id"];
    [para setObject:res_name forKey:@"res_name"];
    [para setObject:[NSString stringWithFormat:@"%d",self.shopModel.id] forKey:@"res_id"];
    [para setObject:commentModel.content forKey:@"cont"];
    [para setObject:[NSString stringWithFormat:@"%d",commentModel.score] forKey:@"score"];
    [para setObject:[XLFunction getTimeStamp] forKey:@"time"];
    NSArray *paraArray = @[APP_ID,para[@"user_id"],para[@"res_name"],para[@"res_id"],para[@"score"],para[@"time"],APP_KEY];
    [para setObject:[XLFunction MD5SignWithParaArray:paraArray] forKey:@"sign"];
    [para setObject:APP_ID forKey:@"app_id"];
   
    
    /**
     *  发送请求
     */
    [self showActivityHUD];
    [XLNewtWorkManager XLPOST:@"api/1/comment/commit_comment" parameters:para success:^(id responseObject) {
        NSLog(@"%@",responseObject);
        [self hideActivityHUD];
        [self showSuccessMessage:@"评论成功!"];
        NSIndexPath *index = [NSIndexPath indexPathForRow:0 inSection:1];
        [self.tableView insertRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationRight];
        
        
    } error:^(id error) {
        NSLog(@"%@",error);
        [self hideActivityHUD];
    } failure:^(NSError *error) {
        NSLog(@"%@",error);
        [self hideActivityHUD];
    }];

}

- (void)pushLoginViewController {
    [self.navigationController pushViewController:[[XLLoginViewController alloc] init] animated:YES];
}

#pragma mark - UMSocialUIDelegate

/**
 *  友盟分享回调方法
 */
- (void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response {

    if (response.responseCode == 200) {
        [self showSuccessMessage:@"分享成功"];
    }
    if (response.responseCode == 5052) {
        [self showErrorMessage:@"取消分享"];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",actionSheet.title]]];
    }
}

#pragma mark - UITableViewDatasource

/**
 *  返回分组数
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


/**
 *  返回分组对应的行数
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) { // 商品
        return self.produceCount + 1;
    }else { // 用户评价
        return self.shopModel.comment_list.count + 1;
    }
}

/**
 *  返回对应indexPath的cell的高度
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { // 第一组,商品信息
        if (indexPath.row == self.produceCount) { //  第一组最后一个cell为"更多"
            return 40;
        }
        return 100;
    }else if (indexPath.section == 1) { // 第二组,用户评价
        if (indexPath.row == self.shopModel.comment_list.count) { //  第二组最后一个cell为查看更多评论
            return 40;
        }
        if (self.shopModel.comment_list.count){
            XLShopCommentViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XLShopCommentViewCell"];
            if (!cell) {
                cell = [[[NSBundle mainBundle] loadNibNamed:@"XLShopCommentViewCell" owner:nil options:nil] lastObject];
            }
//            NSLog(@"%zd",self.shopModel.comment_list.count);
            cell.model = self.shopModel.comment_list[indexPath.row];
//            NSLog(@"%lf",[cell updateCellHeight]);
            return [cell updateCellHeight];
        }
        return 100;
    }
    return 100;
}

/**
 *  返回对应indexPath的cell
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == 0) { // 商品cell
        if (indexPath.row == self.produceCount) { // 商品组最后一行为"更多"按钮
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            XLBarButton *button = button = [XLFactory buttonWithTitle:@"更多" image:nil type:XLButtonTypeNormal];
            button.backgroundColor = [UIColor whiteColor];
            [button setTitleColor:COLOR_RGBA(57, 173, 246, 1) forState:UIControlStateNormal];
            button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
            [cell.contentView addSubview:button];
            // 添加点击事件
            [button addTarget:self action:@selector(morInfoButtonClick) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
        
        XLShopGoodsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XLShopGoodsViewCell"];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XLShopGoodsViewCell" owner:nil options:nil] lastObject];
        }
        /**
         *  第一个之后隐藏顶部分隔线
         */
        if (indexPath.row != 0) {
            cell.topSepLine.hidden = YES;
        }
        /**
         *  设置模型
         */
        NSMutableDictionary *goods = [NSMutableDictionary dictionary];
        [goods setObject:@"卡布奇诺+提拉米苏" forKey:@"goodsName"];
        [goods setObject:@"温馨下午茶,享受每一个下午" forKey:@"goodsAdver"];
        [goods setObject:@"45" forKey:@"goodsPrice"];
        cell.goods = goods;
        return cell;
    }else  { // 评论cell
        // 如果是最后一行
        if (indexPath.row == self.shopModel.comment_list.count) { // 评论组最后一行为"查看更多评论"按钮
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            XLBarButton *button = [XLFactory buttonWithTitle:@"查看更多评论" image:nil type:XLButtonTypeNormal];
            button.backgroundColor = [UIColor whiteColor];
            [button setTitleColor:COLOR_RGBA(57, 173, 246, 1) forState:UIControlStateNormal];
            button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
            // 添加点击事件
            [button addTarget:self action:@selector(moreCommentButtonClick) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:button];
            return cell;
        }
        XLShopCommentViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XLShopCommentViewCell"];
        if (!cell) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"XLShopCommentViewCell" owner:nil options:nil] lastObject];
        }
        if (indexPath.row != 0) {
            cell.topSepLine.hidden = YES;
        }
        /**
         *  第一个之后隐藏顶部分隔线
         */
        cell.model = self.shopModel.comment_list[indexPath.row];
        return cell;
    }
    return nil;
}

/**
 *  返回每一个分组头高度
 */
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 || section == 1) {
        return 40;
    }
    return 0;
}

/**
 *  分组头
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (section == 0) { // 商品
        XLHeaderView *view = [XLHeaderView headerViewWithTitle:@"商品" color:COLOR_RGBA(241, 97, 100, 1)];
//        view.backgroundColor = Random_COLOR;
        return view;
    }else if (section == 1) { // 用户评价
        XLHeaderView *view = [XLHeaderView headerViewWithTitle:@"用户评价" color:COLOR_RGBA(240, 112, 171, 1)];
//        view.backgroundColor = Random_COLOR;
        return view;
    }
    return nil;
}


// 将section FooterView改成每组最后一个cell,优化显示效果

///**
// *  返回分组底部的view高度
// */
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
//    if (section == 0) {
//        return 40;
//    }
//    return 0;
//}
//
///**
// *  分组底部的view
// */
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    XLBarButton *button = nil;
//    if (section == 0) {
//        button = [XLFactory buttonWithTitle:@"更多" image:nil type:XLButtonTypeNormal];
//        button.backgroundColor = [UIColor whiteColor];
//        [button setTitleColor:COLOR_RGBA(57, 173, 246, 1) forState:UIControlStateNormal];
//        button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
//    }
//    }else {
//        button = [XLFactory buttonWithTitle:@"查看更多评论" image:nil type:XLButtonTypeNormal];
//        button.backgroundColor = [UIColor whiteColor];
//        [button setTitleColor:COLOR_RGBA(57, 173, 246, 1) forState:UIControlStateNormal];
//        button.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
//    }
//    return button;
//}


#pragma mark - UITableViewDelegate


#pragma mark - Action

- (void)morInfoButtonClick {
    self.produceCount += 2;
    [self showActivityHUD];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideActivityHUD];
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.produceCount - 1 inSection:0];
        NSIndexPath *path1 = [NSIndexPath indexPathForRow:self.produceCount - 2 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[path,path1] withRowAnimation:UITableViewRowAnimationTop];
    });
}

- (void)moreCommentButtonClick {
    static  int pageNum = 1;
    pageNum ++;
    NSMutableDictionary *prarm = [NSMutableDictionary dictionary];
    
    NSString *pageStr = [NSString stringWithFormat:@"%zd",pageNum];
    //参数
    [prarm setObject:@"shop" forKey:@"res_name"];
    [prarm setObject:[XLFunction getTimeStamp] forKey:@"time"];
    [prarm setObject:[NSString stringWithFormat:@"%d",self.shopModel.id] forKey:@"res_id"];
    [prarm setObject:pageStr forKey:@"page"];
    NSArray *arr = @[APP_ID,prarm[@"res_name"],prarm[@"res_id"],prarm[@"page"],prarm[@"time"],APP_KEY];
    [prarm setObject:[XLFunction MD5SignWithParaArray:arr] forKey:@"sign"];
    
    [prarm setObject:APP_ID forKey:@"app_id"];
    
    [self showActivityHUD];
    [XLNewtWorkManager XLPOST:@"api/1/comment/get_comment_list" parameters:prarm success:^(id responseObject) {
        for (NSDictionary *dict in ((NSDictionary *)responseObject)[@"list"]) {
            [self hideActivityHUD];
            ShopCommentModel *commentModel = [[ShopCommentModel alloc] initWithDictionary:dict error:nil];
            //            NSLog(@"%@",comModel);
            [self.shopModel.comment_list addObject:commentModel];
        }
        [self.tableView reloadData];
    } error:^(id error) {
        [self hideActivityHUD];
    } failure:^(NSError *error) {
        [self hideActivityHUD];
    }];
}


#pragma mark - Private Function

- (void)setShopModel:(XLShopModel *)shopModel {
    _shopModel = shopModel;
    self.headerView.shopModel = shopModel;
    // 更新HeaderView的高度,先取出,修改frame之后再次赋值
    XLShopHeaderView *view = self.headerView;
    // 调用updateFrame方法动态计算高度
    view.frame = [self.headerView updateFrame];
    self.tableView.tableHeaderView = view;
}

/**
 *  请求商家详情数据
 */
- (void)requestShopData {
    // 设置请求参数
    NSMutableDictionary *para = [NSMutableDictionary dictionary];
    [para setObject:self.parameter[@"shop_id"] forKey:@"shop_id"];
    [para setObject:[XLFunction getTimeStamp] forKey:@"time"];
    NSArray *paraArray = @[APP_ID,para[@"shop_id"],para[@"time"],APP_KEY];
    [para setObject:[XLFunction MD5SignWithParaArray:paraArray] forKey:@"sign"];
    [para setObject:APP_ID forKey:@"app_id"];
    // 显示进度
    [self showActivityHUD];
    // POST请求
    [XLNewtWorkManager XLPOST:kShopInfo parameters:para success:^(id responseObject) {
        // 请求成功,关闭进度
        [self hideActivityHUD];
        // 初始化模型数据
        self.shopModel = [[XLShopModel alloc] initWithDictionary:responseObject error:NULL];
        [self.tableView reloadData];
    } error:^(id error) {
        [self hideActivityHUD];
        NSLog(@"%@",error);
    } failure:^(NSError *error) {
        [self hideActivityHUD];
        NSLog(@"%@",error);
    }];
}


#pragma mark - Getter & Setter

- (XLShopHeaderView *)headerView {
    if (!_headerView) {
        self.headerView = [XLShopHeaderView shopHeaderView];
        self.headerView.delegate = self;
    }
    return _headerView;
}

- (XLShopFooterView *)footerView {
    if (!_footerView) {
        self.footerView = [XLShopFooterView shopFooterView];
        self.footerView.delegate = self;
        self.footerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 200);
    }
    return _footerView;
}

- (UIActionSheet *)actionSheet {
    if (!_actionSheet) {
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"拨打电话" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"拨打" otherButtonTitles: nil];
    }
    return _actionSheet;
}

- (UIWebView *)webVIew {
    if (!_webVIew) {
        self.webVIew = [[UIWebView alloc] init];
    }
    return _webVIew;
}

@end




