//
//  RECache.m
//  Retriever
//
//  Created by cyan on 2016/10/25.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "RECache.h"

static NSString *const kRECacheFavouriteAppsKey = @"Favourite";

@implementation RECache

+ (NSDictionary *)favouriteAppIdentifiers {
    NSDictionary *object = [[NSUserDefaults standardUserDefaults] objectForKey:kRECacheFavouriteAppsKey];
    return object ?: @{};
}

+ (void)setFavouriteAppIdentifiers:(NSDictionary *)identifiers {
    [[NSUserDefaults standardUserDefaults] setObject:identifiers forKey:kRECacheFavouriteAppsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
