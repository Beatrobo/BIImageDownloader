//
//  BIImageDownloader.m
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import "BIImageDownloader.h"
#import <CommonCrypto/CommonDigest.h>
#include <time.h>
#import "BIReachability.h"
#import "NSURLConnection+bi_sendAsynchronousRequestOnMainThread.h"

//#define BIImageDownloaderDebugLog(format, ...)   DPDLog(format, ##__VA_ARGS__)
#define BIImageDownloaderDebugLog(format, ...)   {;}

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

@end

@implementation BIImageDownloaderCache

+ (BIImageDownloaderCache *)cacheWithData:(NSData*)data key:(NSString*)key
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

+ (BIImageDownloaderCache*)cacheFromStorageWithKey:(NSString *)key usingFileManager:(NSFileManager*)fm;
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



#pragma mark -



@interface BIImageDownloader ()
{
    NSOperationQueue* _queue;
    dispatch_queue_t  _storageQueue;
    NSFileManager*    _fm;

    NSMutableDictionary* _memoryCache;
}
@end

@implementation BIImageDownloader

+ (BIImageDownloader*)sharedInstance
{
    static id downloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[[self class] alloc] initInstance];
    });
    return downloader;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initInstance
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 3;
        _fm = [[NSFileManager alloc] init];
        _storageQueue = dispatch_queue_create("BIImageDownloader.storage", 0);
        _memoryCache = [NSMutableDictionary dictionaryWithCapacity:50];

        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        #endif
    }
    return self;
}

- (NSOperationQueue*)operationQueue
{
    return _queue;
}

- (void)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)expireTime completion:(BIImageDownloaderCompleteBlock)completion
{
    if (!url) {
        completion(nil);
        return;
    }
    NSString* key = [self keyWithURL:url];

    // find cahce on memory
    BIImageDownloaderCache* cache = [self cacheForKey:key onMemory:YES expiresTime:expireTime];
    if (cache.image) {
        BIImageDownloaderDebugLog(@"%@ is on memory, %d", url, _memoryCache.count);
        completion(cache.image);
        return;
    }

    dispatch_async(_storageQueue, ^{
        BIImageDownloaderCache* cache = [self cacheForKey:key onMemory:NO expiresTime:expireTime];
        if (cache.image) {
            BIImageDownloaderDebugLog(@"%@ is on storage", url);
            @synchronized(_memoryCache) {
                [_memoryCache setObject:cache forKey:key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(cache.image);
            });
            return;
        }
        BIImageDownloaderDebugLog(@"fetching... %@", url);
        NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

        dispatch_async(dispatch_get_main_queue(), ^{
            [BIReachability beginNetworkConnection];
        });
        [NSURLConnection bi_sendAsynchronousRequest:req queue:_queue
                                  completionHandler:^(NSURLResponse * res, NSData * data, NSError * error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [BIReachability endNetworkConnection];
                                      });

                                      if (!data) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              DPDLog(@"fetch error %@, %@:%@", url, res, error);
                                              completion(nil);
                                          });
                                          return;
                                      }

                                      dispatch_async(_storageQueue, ^{
                                          BIImageDownloaderCache* cache = [BIImageDownloaderCache cacheWithData:data key:key];
                                          if (cache.image) {
                                              [cache save];
                                              if (useOnMemoryCache) {
                                                  @synchronized(_memoryCache) {
                                                      [self sweepMemoryCacheIfNeeded];
                                                      [_memoryCache setObject:cache forKey:key];
                                                  }
                                              }
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completion(cache.image);
                                              });
                                          } else {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completion(nil); // error, invalid data
                                              });
                                          }

                                      });
                                  }];
    });
}

- (NSString*)keyWithURL:(NSString*)url
{
    const char *cStr = [url UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (BIImageDownloaderCache*)cacheForKey:(NSString*)key onMemory:(BOOL)onmemory expiresTime:(NSUInteger)time
{
    if (onmemory) {
        BIImageDownloaderCache* cache;
        @synchronized(_memoryCache) {
            cache = [_memoryCache objectForKey:key];
        }
        return cache;
    } else {
        BIImageDownloaderCache* cache = [BIImageDownloaderCache cacheFromStorageWithKey:key usingFileManager:_fm];
        if (cache) {
            if ([cache isExpiredWith:[[NSDate date] timeIntervalSince1970] lifeTime:time]) {
                @synchronized(_memoryCache) {
                    [_memoryCache removeObjectForKey:key];
                }
                [cache deleteUsingFileManager:_fm];
                return nil;
            }
            return cache;
        }
    }
    return nil;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (void)memoryWarning
{
    @synchronized(_memoryCache) {
        [_memoryCache removeAllObjects];
    }
}
#endif

- (void)sweepMemoryCacheIfNeeded
{
    // not implemented yet
}

@end
