//
//  REHelper.m
//  Retriever
//
//  Created by cyan on 2016/10/21.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "REHelper.h"

static NSString *const kRERetrieverGitHubURL = @"https://github.com/cyanzhong/Retriever";

@implementation REHelper

+ (id)defaultWorkspace {
    return [@"LSApplicationWorkspace" invokeClassMethod:@"defaultWorkspace"];
}

+ (NSArray *)installedApplications {
    return [[self defaultWorkspace] invoke:@"allInstalledApplications"];
}

+ (NSArray *)installedPlugins {
    return [[self defaultWorkspace] invoke:@"installedPlugins"];
}

+ (NSString *)displayNameForApplication:(id)app {
    return [([app valueForKeyPath:kREDisplayNameKeyPath] ?: [app valueForKey:kRELocalizedShortNameKey]) description];
}

+ (NSString *)identifierForApp:(id)app {
    if ([app isKindOfClass:NSClassFromString(@"LSApplicationProxy")]) {
        return [[self class] bundleIdentifierForApplication:app];
    }
    else if ([app isKindOfClass:NSClassFromString(@"LSPlugInKitProxy")]) {
        return [[self class] pluginIdentifierForPlugin:app];
    }
    return @"";
}

+ (NSString *)bundleIdentifierForApplication:(id)app {
    return [app valueForKey:@"bundleIdentifier"];
}

+ (NSString *)pluginIdentifierForPlugin:(id)plugin {
    return [plugin valueForKey:@"pluginIdentifier"];
}

+ (UIImage *)iconImageForApplication:(id)app {
    return [self iconImageForApplication:app format:0];
}

+ (UIImage *)iconImageForApplication:(id)app format:(NSInteger)format {
    return [UIImage invoke:@"_applicationIconImageForBundleIdentifier:format:scale:"
                 arguments:@[[self bundleIdentifierForApplication:app], @(format), @([UIScreen mainScreen].scale)]];
}

+ (id)applicationForIdentifier:(NSString *)identifier {
    return [@"LSApplicationProxy" invokeClassMethod:@"applicationProxyForIdentifier:" args:identifier, nil];
}

+ (/* LSPlugInKitProxy * */id)plugInForIdentifier:(NSString *)identifier {
    return [@"LSPlugInKitProxy" invokeClassMethod:@"pluginKitProxyForIdentifier:" args:identifier, nil];
}

+ (NSArray *)applicationsForIdentifiers:(NSArray *)identifiers {
    NSMutableArray *apps = [NSMutableArray array];
    for (NSString *identifier in identifiers) {
        [apps addObject:[self applicationForIdentifier:identifier]];
    }
    return apps;
}

+ (void)openApplication:(id)app {
    [[self defaultWorkspace] invoke:@"openApplicationWithBundleID:"
                               args:[self bundleIdentifierForApplication:app], nil];
}

+ (void)openGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kRERetrieverGitHubURL]
                                       options:@{}
                             completionHandler:nil];
}

+ (void)shareRetriever {
    NSArray *items = @[[NSURL URLWithString:kRERetrieverGitHubURL], [UIImage imageNamed:@"AppIcon60x60@3x.png"], @"Retriever: Retrieve InfoPlist without Jailbreak on iOS Devices"];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items
                                                                             applicationActivities:nil];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:controller
                                                                                     animated:YES
                                                                                   completion:nil];
}

@end
