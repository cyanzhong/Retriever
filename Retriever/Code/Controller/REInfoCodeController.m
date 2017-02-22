//
//  REInfoCodeController.m
//  Retriever
//
//  Created by cyan on 2016/10/24.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "REInfoCodeController.h"
#import <WebKit/WebKit.h>
#import "REInfoTreeController.h"
#import "REAppInfoBar.h"
#import "HOCodeView.h"
#import "VKBeautify.h"

typedef NS_ENUM(NSInteger, REInfoCodeType) {
    REInfoCodeTypeJSON      = 0,
    REInfoCodeTypeXML,
    REInfoCodeTypeTree
};

@interface REInfoCodeController ()

@property (nonatomic, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) id info;
@property (nonatomic, strong) id propertyList;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, copy) NSString *json;
@property (nonatomic, copy) NSString *xml;
@property (nonatomic, strong) HOCodeView *codeView;
@property (nonatomic, assign) REInfoCodeType selectedType;
@property (nonatomic, strong) REAppInfoBar *infoBar;

@end

@implementation REInfoCodeController

- (instancetype)initWithInfo:(id)info {
    if (self = [super init]) {
        _info = info;
    }
    return self;
}

- (UISegmentedControl *)segmentedControl {
    return (UISegmentedControl *)self.navigationItem.titleView;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Share"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(share:)];

    self.navigationItem.titleView = [[UISegmentedControl alloc] initWithItems:@[@"JSON", @"XML", @"Tree"]];
    
    self.segmentedControl.selectedSegmentIndex = REInfoCodeTypeJSON;
    [self.segmentedControl addTarget:self 
                              action:@selector(didSegmentedControlValueChanged:) 
                    forControlEvents:UIControlEventValueChanged];
    
    self.codeView = [[HOCodeView alloc] init];
    self.codeView.backgroundColor = self.view.backgroundColor;
    
    self.codeView.contentInset = UIEdgeInsetsMake(0, 0, kREAppInfoBarHeight, 0);
    self.codeView.scrollIndicatorInsets = self.codeView.contentInset;
    [self.view addSubview:self.codeView];
    [self.codeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.bShowBottomBar) {
        self.infoBar = [[REAppInfoBar alloc] initWithInfo:self.info];
        [self.view addSubview:self.infoBar];
        [self.infoBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.equalTo(0);
            make.height.equalTo(kREAppInfoBarHeight);
        }];
        
        @weakify(self)
        self.infoBar.openHandler = ^{
            @strongify(self)
            [self openApplication];
        };
    }
    
    [self refresh];
}

- (void)openApplication {
    [REHelper openApplication:self.info];
}

- (void)share:(UIBarButtonItem *)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    @weakify(self)
    void(^shareIconHandler)(UIAlertAction *) = ^(UIAlertAction *action) {
        @strongify(self)
        [self shareIcon];
    };
    UIAlertAction *shareIconAction = [UIAlertAction actionWithTitle:@"Share Icon"
                                                              style:UIAlertActionStyleDefault
                                                            handler:shareIconHandler];
    
    void(^sharePlistHandler)(UIAlertAction *) = ^(UIAlertAction *action) {
        @strongify(self)
        [self sharePlist];
    };
    UIAlertAction *sharePlistAction = [UIAlertAction actionWithTitle:@"Share Plist"
                                                               style:UIAlertActionStyleDefault
                                                             handler:sharePlistHandler];
    [alertController addAction:shareIconAction];
    [alertController addAction:sharePlistAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)shareItem:(id)item {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[item]
                                                                                         applicationActivities:nil];
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [rootViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)shareIcon {
    UIImage *image = [REHelper iconImageForApplication:self.info format:2];
    [self shareItem:image];
}

- (void)sharePlist {
    NSString *path = AppDocumentPath([NSString stringWithFormat:@"%@.plist", self.displayName]);
    [self.propertyList writeToFile:path atomically:YES];
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    [self shareItem:fileUrl];
}

- (void)didSegmentedControlValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == REInfoCodeTypeTree) {
        REInfoTreeController *controller = [[REInfoTreeController alloc] initWithInfo:self.info];
        controller.title = self.displayName;
        [self.navigationController pushViewController:controller animated:YES];
        sender.selectedSegmentIndex = self.selectedType;
    } else {
        self.selectedType = sender.selectedSegmentIndex;
        [self refresh];
    }
}

- (void)refresh {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case REInfoCodeTypeJSON: [self.codeView render:self.json language:@"json"]; break;
        case REInfoCodeTypeXML: [self.codeView render:self.xml language:@"xml"]; break;
        default: break;
    }
}

#pragma mark - Lazy Init

- (id)propertyList {
    if (_propertyList == nil) {
        if ([self.info isKindOfClass:NSClassFromString(kREApplicationProxyClass)]) {
            _propertyList = [self.info valueForKeyPath:kREPropertyListKeyPath];
        } else {
            _propertyList = [self.info valueForKey:kREPluginPropertyKey];
        }
    }
    return _propertyList;
}

- (NSString *)displayName {
    if (_displayName == nil) {
        _displayName = [REHelper displayNameForApplication:self.info];
    }
    return _displayName;
}

- (NSString *)json {
    if (_json == nil) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self.propertyList
                                                       options:0
                                                         error:nil];
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        _json = [VKBeautify beautified:json type:VKBeautifySourceTypeJSON];
    }
    return _json;
}

- (NSString *)xml {
    if (_xml == nil) {
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:self.propertyList
                                                                  format:NSPropertyListXMLFormat_v1_0
                                                                 options:0
                                                                   error:nil];
        NSString *xml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        _xml = [VKBeautify beautified:xml type:VKBeautifySourceTypeXML];
    }
    return _xml;
}

#pragma mark - 3D Touch Menu

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    @weakify(self)
    NSMutableArray *arrItems = [@[] mutableCopy];
    UIPreviewAction *shareIconAction = [UIPreviewAction actionWithTitle:@"Share Icon" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        @strongify(self)
        [self shareIcon];
    }];
    [arrItems addObject:shareIconAction];
    
    UIPreviewAction *sharePlistAction = [UIPreviewAction actionWithTitle:@"Share Plist" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        @strongify(self)
        [self sharePlist];
    }];
    [arrItems addObject:sharePlistAction];
    
    if ([self.info isKindOfClass:NSClassFromString(@"LSApplicationProxy")]) {
        UIPreviewAction *openAction = [UIPreviewAction actionWithTitle:@"Open" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            @strongify(self)
            [self openApplication];
        }];
        [arrItems addObject:openAction];
    }
    return [arrItems copy];
}

@end
