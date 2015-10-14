//
//  HomeViewController.m
//  MyOne
//
//  Created by HelloWorld on 7/27/15.
//  Copyright (c) 2015 melody. All rights reserved.
//

#import "HomeViewController.h"
#import "RightPullToRefreshView.h"
#import "HomeEntity.h"
#import <MJExtension/MJExtension.h>
#import "HomeView.h"
#import "HTTPTool.h"

@interface HomeViewController () <RightPullToRefreshViewDelegate, RightPullToRefreshViewDataSource>

@property (nonatomic, strong) RightPullToRefreshView *rightPullToRefreshView;

@end

@implementation HomeViewController {
	// 当前一共有多少篇文章，默认为3篇
	NSInteger numberOfItems;
	// 保存当前查看过的数据
	NSMutableDictionary *readItems;
	// 最后展示的 item 的下标
	NSInteger lastConfigureViewForItemIndex;
	// 当前是否正在右拉刷新标记
	BOOL isRefreshing;
}

#pragma mark - View Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (self) {
		UIImage *deselectedImage = [[UIImage imageNamed:@"tabbar_item_home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		UIImage *selectedImage = [[UIImage imageNamed:@"tabbar_item_home_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		// 底部导航item
		UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"首页" image:nil tag:0];
		tabBarItem.image = deselectedImage;
		tabBarItem.selectedImage = selectedImage;
		self.tabBarItem = tabBarItem;
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	[self setUpNavigationBarShowRightBarButtonItem:YES];
	
	numberOfItems = 2;
	readItems = [[NSMutableDictionary alloc] init];
	lastConfigureViewForItemIndex = 0;
	isRefreshing = NO;
	
	self.rightPullToRefreshView = [[RightPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - CGRectGetHeight(self.tabBarController.tabBar.frame))];
	self.rightPullToRefreshView.delegate = self;
	self.rightPullToRefreshView.dataSource = self;
	[self.view addSubview:self.rightPullToRefreshView];
	
	[self requestHomeContentAtIndex:0];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeSwitch:) name:@"DKNightVersionNightFallingNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nightModeSwitch:) name:@"DKNightVersionDawnComingNotification" object:nil];
	
//	UIDevice *device = [UIDevice currentDevice];
//	NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
//	NSString *deviceID = [BaseFunction md5Digest:currentDeviceId];
//	// @"761784e559875c76cc95222cc8c8135a17bb61e1079fb654100ce81f4ef8e6ef"
//	NSString *myid = @"761784e559875c76cc95222cc8c8135a17bb61e1079fb654100ce81f4ef8e6ef";
//	NSLog(@"myid.length = %ld", myid.length);
//	NSLog(@"deviceID = %@, deviceID.length = %ld", deviceID, deviceID.length);
}

#pragma mark - Lifecycle

- (void)dealloc {
	self.rightPullToRefreshView.delegate = nil;
	self.rightPullToRefreshView.dataSource = nil;
	self.rightPullToRefreshView = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - NSNotification

- (void)nightModeSwitch:(NSNotification *)notification {
	if (Is_Night_Mode) {
		self.tabBarController.tabBar.backgroundImage = [self imageWithColor:[UIColor colorWithRed:48 / 255.0 green:48 / 255.0 blue:48 / 255.0 alpha:1]];
	} else {
		self.tabBarController.tabBar.backgroundImage = [self imageWithColor:[UIColor colorWithRed:241 / 255.0 green:241 / 255.0 blue:241 / 255.0 alpha:1]];
	}
	
	[self.rightPullToRefreshView reloadData];
}

#pragma mark - RightPullToRefreshViewDataSource

- (NSInteger)numberOfItemsInRightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView {
	return numberOfItems;
}

- (UIView *)rightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
	HomeView *homeView = nil;
	
	//create new view if no view is available for recycling
	if (view == nil) {
		view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(rightPullToRefreshView.frame), CGRectGetHeight(rightPullToRefreshView.frame))];
		homeView = [[HomeView alloc] initWithFrame:view.bounds];
		[view addSubview:homeView];
	} else {
		homeView = (HomeView *)view.subviews[0];
	}
	
	//remember to always set any properties of your carousel item
	//views outside of the `if (view == nil) {...}` check otherwise
	//you'll get weird issues with carousel item content appearing
	//in the wrong place in the carousel
	if (index == numberOfItems - 1 || index == readItems.allKeys.count) {// 当前这个 item 是没有展示过的
		[homeView refreshSubviewsForNewItem];
	} else {// 当前这个 item 是展示过了但是没有显示过数据的
		lastConfigureViewForItemIndex = MAX(index, lastConfigureViewForItemIndex);
		[homeView configureViewWithHomeEntity:readItems[[@(index) stringValue]] animated:YES];
	}
	
	return view;
}

#pragma mark - RightPullToRefreshViewDelegate

- (void)rightPullToRefreshViewRefreshing:(RightPullToRefreshView *)rightPullToRefreshView {
	[self refreshing];
}

- (void)rightPullToRefreshView:(RightPullToRefreshView *)rightPullToRefreshView didDisplayItemAtIndex:(NSInteger)index {
	if (index == numberOfItems - 1) {// 如果当前显示的是最后一个，则添加一个 item
		numberOfItems++;
		[self.rightPullToRefreshView insertItemAtIndex:(numberOfItems - 1) animated:YES];
	}
	
	if (index < readItems.allKeys.count && readItems[[@(index) stringValue]]) {
		HomeView *homeView = (HomeView *)[rightPullToRefreshView itemViewAtIndex:index].subviews[0];
		[homeView configureViewWithHomeEntity:readItems[[@(index) stringValue]] animated:(lastConfigureViewForItemIndex == 0 || lastConfigureViewForItemIndex < index)];
	} else {
		[self requestHomeContentAtIndex:index];
	}
}

- (void)rightPullToRefreshViewCurrentItemIndexDidChange:(RightPullToRefreshView *)rightPullToRefreshView {
	if (isGreatThanIOS9) {
		UIView *currentItemView = [rightPullToRefreshView currentItemView];
		for (id subView in rightPullToRefreshView.contentView.subviews) {
			if (![subView isKindOfClass:[UILabel class]]) {
				UIView *itemView = (UIView *)subView;
				HomeView *homeView = (HomeView *)itemView.subviews[0].subviews[0];
				UIScrollView *scrollView = (UIScrollView *)[homeView viewWithTag:ScrollViewTag];
				if (itemView == currentItemView.superview) {
					scrollView.scrollsToTop = YES;
				} else {
					scrollView.scrollsToTop = NO;
				}
			}
		}
	}
}

#pragma mark - Network Requests

// 右拉刷新
- (void)refreshing {
	if (readItems.allKeys.count > 0) {// 避免第一个还未加载的时候右拉刷新更新数据
		[self showHUDWithText:@""];
		isRefreshing = YES;
		[self requestHomeContentAtIndex:0];
	}
}

- (void)requestHomeContentAtIndex:(NSInteger)index {
	[HTTPTool requestHomeContentByIndex:index success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if ([responseObject[@"result"] isEqualToString:REQUEST_SUCCESS]) {
			HomeEntity *returnHomeEntity = [HomeEntity objectWithKeyValues:responseObject[@"hpEntity"]];
			if (isRefreshing) {
				[self endRefreshing];
				if ([returnHomeEntity.strHpId isEqualToString:((HomeEntity *)readItems[@"0"]).strHpId]) {// 没有最新数据
					[self showHUDWithText:IsLatestData delay:HUD_DELAY];
				} else {// 有新数据
					// 删掉所有的已读数据，不用考虑第一个已读数据和最新数据之间相差几天，简单粗暴
					[readItems removeAllObjects];
					[self hideHud];
				}
				
				[self endRequestHomeContent:returnHomeEntity atIndex:index];
			} else {
				[self hideHud];
				[self endRequestHomeContent:returnHomeEntity atIndex:index];
			}
		}
	} failBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"home error = %@", error);
	}];
}

#pragma mark - Private

- (void)endRefreshing {
	isRefreshing = NO;
	[self.rightPullToRefreshView endRefreshing];
}

- (void)endRequestHomeContent:(HomeEntity *)homeEntity atIndex:(NSInteger)index {
	[readItems setObject:homeEntity forKey:[@(index) stringValue]];
	[self.rightPullToRefreshView reloadItemAtIndex:index animated:NO];
}

#pragma mark - Parent

- (void)share {
	[super share];
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
