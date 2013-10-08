//
//  BIImageDownloaderCache.m
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import "BIImageDownloaderCache.h"

@implementation BIImageDownloaderCache

+ (instancetype)cacheWithData:(NSData*)data key:(NSString*)key
{
    if (!data) {
        return nil;
    }
    
    BIImageDownloaderCache* cache = [[self alloc] init];
    if (!cache) {
        return nil;
    }
    
    cache.createdAt = time(NULL);
    cache.data = data;
    cache.key = key;
    return cache;
}

+ (instancetype)cacheFromStorageWithKey:(NSString *)key usingFileManager:(NSFileManager*)fm;
{
    NSData* data = [NSData dataWithContentsOfFile:[[self cacheDirectoryPath] stringByAppendingPathComponent:key]];
    BIImageDownloaderCache* cache = [self cacheWithData:data key:key];
    if (!cache) {
        return nil;
    }
    cache.createdAt = [[fm attributesOfItemAtPath:[[self cacheDirectoryPath] stringByAppendingPathComponent:key] error:nil] fileCreationDate].timeIntervalSince1970;
    return cache;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (UIImage*)image
{
    if (_image) {
        return _image;
    }
    return [UIImage imageWithData:_data];
}
#elif TARGET_OS_MAC
- (NSImage*)image
{
    if (_image) {
        return _image;
    }
#warning あとで NSImage のこと調べる
    return nil;
}
#endif

- (BOOL)isExpiredWith:(NSTimeInterval)time lifeTime:(NSTimeInterval)lifeTime
{
    if (abs(time - _createdAt) > lifeTime) {
        return YES;
    }
    return NO;
}

- (void)save
{
    [_data writeToFile:[[[self class] cacheDirectoryPath] stringByAppendingPathComponent:_key] atomically:NO];
}

- (void)deleteUsingFileManager:(NSFileManager *)fm
{
    [fm removeItemAtPath:[[[self class] cacheDirectoryPath] stringByAppendingPathComponent:_key] error:nil];
}

+ (NSString*)cacheDirectoryPath
{
    NSArray* cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cacheDirectory = [cachePaths objectAtIndex:0];
    return cacheDirectory;
}

@end
