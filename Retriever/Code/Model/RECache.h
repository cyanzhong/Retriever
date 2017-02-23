//
//  RECache.h
//  Retriever
//
//  Created by cyan on 2016/10/25.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RECache : NSObject

+ (NSDictionary *)favouriteAppIdentifiers;

+ (void)setFavouriteAppIdentifiers:(NSDictionary *)identifiers;

@end
