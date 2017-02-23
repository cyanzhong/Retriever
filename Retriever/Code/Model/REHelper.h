//
//  REHelper.h
//  Retriever
//
//  Created by cyan on 2016/10/21.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface REHelper : NSObject

+ (NSArray *)installedApplications;

+ (NSArray *)installedPlugins;

+ (NSString *)identifierForApp:(id)app;

+ (NSString *)bundleIdentifierForApplication:(id)app;

+ (NSString *)displayNameForApplication:(id)app;

+ (UIImage *)iconImageForApplication:(id)app;

+ (UIImage *)iconImageForApplication:(id)app format:(NSInteger)format;

+ (id)applicationForIdentifier:(NSString *)identifier;

+ (id)plugInForIdentifier:(NSString *)identifier;

+ (NSArray *)applicationsForIdentifiers:(NSArray *)identifiers;

+ (void)openApplication:(id)app;

+ (void)openGitHub;

+ (void)shareRetriever;

@end
