//
//  REAppListController.m
//  Retriever
//
//  Created by cyan on 2016/10/21.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "REAppListController.h"
#import "RETableView.h"
#import "REAppListCell.h"
#import "REInfoCodeController.h"

typedef NS_ENUM(NSInteger, REListType) {
    REListTypeApp       = 0,
    REListTypePlugin,
    REListTypeFavourite
};

@interface REAppListController ()<
    UITableViewDelegate,
    UITableViewDataSource,
    UISearchResultsUpdating,
    UIViewControllerPreviewingDelegate
>

@property (nonatomic, strong) NSArray *list;
@property (nonatomic, strong) NSArray *filtered;
@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) RETableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableDictionary *dictFavorite;

@end

@implementation REAppListController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.titleView = [[UISegmentedControl alloc] initWithItems:@[@"Apps", @"Plugins", @"Favourites"]];
    
    self.segmentedControl.selectedSegmentIndex = REListTypeApp;
    [self.segmentedControl addTarget:self 
                              action:@selector(didSegementedControlValueChanged:)
                    forControlEvents:UIControlEventValueChanged];
    
    self.tableView = [[RETableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [refreshControl addTarget:self
                       action:@selector(didRefreshControlValueChanged:)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
    
    [self refresh];
}

- (void)didRefreshControlValueChanged:(UIRefreshControl *)sender {
    [self refresh];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender endRefreshing];
    });
}

- (UISegmentedControl *)segmentedControl {
    return (UISegmentedControl *)self.navigationItem.titleView;
}

- (void)didSegementedControlValueChanged:(UISegmentedControl *)sender {
    [self refresh];
    CGFloat offset = -CGRectGetHeight(self.searchController.searchBar.frame) - CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
    [self.tableView setContentOffset:CGPointMake(0, offset) animated:YES];
}

- (void)refresh {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSArray *apps = [REHelper installedApplications];
        NSArray *plugins = [REHelper installedPlugins];
        NSDictionary *identifiers = [RECache favouriteAppIdentifiers];
        self.dictFavorite = [identifiers mutableCopy];
        __block NSMutableArray *favApps = [NSMutableArray array];
        [self.dictFavorite enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            switch ([obj integerValue]) {
                case REListTypeApp:
                {
                    [favApps addObject:[REHelper applicationForIdentifier:key]];
                }
                    break;
                case REListTypePlugin:
                {
                    [favApps addObject:[REHelper plugInForIdentifier:key]];
                }
                    break;
                default:
                    break;
            }
        }];
        NSArray *favourites = [favApps copy];
        NSArray *data;
        
        switch (self.segmentedControl.selectedSegmentIndex) {
            case REListTypeApp: data = apps; break;
            case REListTypePlugin: data = plugins; break;
            case REListTypeFavourite: data = favourites; break;
            default: break;
        }
        
        self.list = [data sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString *name1 = [REHelper displayNameForApplication:obj1];
            NSString *name2 = [REHelper displayNameForApplication:obj2];
            return [name1 compare:name2];
        }];
        self.filtered = self.list;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.segmentedControl setTitle:[NSString stringWithFormat:@"Apps (%tu)", apps.count]
                          forSegmentAtIndex:REListTypeApp];
            [self.segmentedControl setTitle:[NSString stringWithFormat:@"Plugins (%tu)", plugins.count]
                          forSegmentAtIndex:REListTypePlugin];
            [self.segmentedControl sizeToFit];
            [self.tableView reloadData];
        });
    });
}

- (REInfoCodeController *)codeControllerAtIndexPath:(NSIndexPath *)indexPath {
    id app = self.filtered[indexPath.row];
    REInfoCodeController *controller = [[REInfoCodeController alloc] initWithInfo:app];
    controller.bShowBottomBar =
    [app isKindOfClass:NSClassFromString(@"LSApplicationProxy")];
    return controller;
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"REHomeCell";
    REAppListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[REAppListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [cell render:self.filtered[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    REInfoCodeController *controller = [self codeControllerAtIndexPath:indexPath];
    self.searchController.active = NO;
    [self.navigationController pushViewController:controller animated:YES];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = [REHelper identifierForApp:self.filtered[indexPath.row]];
    BOOL like = self.segmentedControl.selectedSegmentIndex != REListTypeFavourite && !self.dictFavorite[identifier];
    NSString *title = like ? @"Like" : @"Dislike";
    
    @weakify(self)
    void (^actionHandler)(UITableViewRowAction *action, NSIndexPath *indexPath) = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        @strongify(self)
        if (like) {
            [self.dictFavorite setObject:@(self.segmentedControl.selectedSegmentIndex)
                                  forKey:identifier];
        } else {
            [self.dictFavorite removeObjectForKey:identifier];
        }
        if (self.segmentedControl.selectedSegmentIndex == REListTypeFavourite) {
            NSMutableArray *list = self.filtered.mutableCopy;
            [list removeObjectAtIndex:indexPath.row];
            self.filtered = list;
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [tableView reloadData];
        }
        [RECache setFavouriteAppIdentifiers:self.dictFavorite];
    };
    
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                      title:title
                                                                    handler:actionHandler];
    return @[action];
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text.lowercaseString;
    if (isBlankText(searchText)) {
        self.filtered = self.list;
        [self.tableView reloadData];
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableArray *filtered = [NSMutableArray array];
            for (id item in self.list) {
                NSString *name = [REHelper displayNameForApplication:item];
                if ([name.lowercaseString containsString:searchText]) {
                    [filtered addObject:item];
                }
            }
            self.filtered = filtered;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
}

#pragma mark - 3D Touch

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    CGPoint point = [self.tableView.superview convertPoint:location toView:nil];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath) {
        return [self codeControllerAtIndexPath:indexPath];
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self showViewController:viewControllerToCommit sender:self];
}

@end
