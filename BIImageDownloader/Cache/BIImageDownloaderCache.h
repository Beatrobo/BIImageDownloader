//
//  BIImageDownloaderCache.h
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import "BIImageDownloader.h"

@interface BIImageDownloaderCache : NSObject
{
    BIImageType* _image;
}

+ (instancetype)cacheWithData:(NSData*)data key:(NSString*)key; // returns nil if data is nil
+ (instancetype)cacheFromStorageWithKey:(NSString*)key usingFileManager:(NSFileManager*)fm; // returns nil if no data on storage

@property (nonatomic, copy)     NSString*      key;
@property (nonatomic)           NSTimeInterval createdAt;
@property (nonatomic, copy)     NSData*        data;

@property (nonatomic, readonly) BIImageType* image;

- (void)save;
- (void)deleteUsingFileManager:(NSFileManager*)fm;

- (BOOL)isExpiredWith:(NSTimeInterval)time lifeTime:(NSTimeInterval)lifeTime;

@end
