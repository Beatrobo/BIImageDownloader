//
//  BIImageDownloaderCache.h
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BIImageDownloaderCache : NSObject
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    UIImage* _image;
#elif TARGET_OS_MAC
    NSImage* _image;
#endif
}

+ (BIImageDownloaderCache*)cacheWithData:(NSData*)data key:(NSString*)key; // returns nil if data is nil
+ (BIImageDownloaderCache*)cacheFromStorageWithKey:(NSString*)key usingFileManager:(NSFileManager*)fm; // returns nil if no data on storage

@property (nonatomic, copy)     NSString*      key;
@property (nonatomic)           NSTimeInterval createdAt;
@property (nonatomic, copy)     NSData*        data;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@property (nonatomic, readonly) UIImage* image;
#elif TARGET_OS_MAC
@property (nonatomic, readonly) NSImage* image;
#endif

- (void)save;
- (void)deleteUsingFileManager:(NSFileManager*)fm;

- (BOOL)isExpiredWith:(NSTimeInterval)time lifeTime:(NSTimeInterval)lifeTime;

@end
