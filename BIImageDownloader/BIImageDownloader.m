#import "BIImageDownloader.h"
#import "BIImageDownloaderCache.h"
#import <CommonCrypto/CommonDigest.h>
#include <time.h>
#import "BIReachability.h"
#import "NSURLConnection+bi_sendAsynchronousRequestOnMainThread.h"
#import "BIImageDownloaderLog.h"


@interface BIImageDownloader ()
{
    NSOperationQueue* _queue;
    dispatch_queue_t  _storageQueue;
    NSFileManager*    _fm;

    NSMutableDictionary* _memoryCache;
}
@end


@implementation BIImageDownloader

+ (instancetype)sharedInstance
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

- (BIImageType*)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)expireTime completion:(BIImageDownloaderCompleteBlock)completion
{
    if (!url) {
        if (completion) {
            completion(nil);
        }
        return nil;
    }
    NSString* key = [self keyWithURL:url];

    // find cahce on memory
    BIImageDownloaderCache* cache = [self cacheForKey:key onMemory:YES expiresTime:expireTime];
    if (cache.image) {
        BIIDLogDebug(@"%@ is on memory, %d", url, (int)_memoryCache.count);
        if (completion) {
            completion(cache.image);
        }
        return cache.image;
    }

    dispatch_async(_storageQueue, ^{
        BIImageDownloaderCache* cache = [self cacheForKey:key onMemory:NO expiresTime:expireTime];
        if (cache.image) {
            BIIDLogDebug(@"%@ is on storage", url);
            @synchronized(_memoryCache) {
                [_memoryCache setObject:cache forKey:key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(cache.image);
                }
            });
            return;
        }
        BIIDLogDebug(@"fetching... %@", url);
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
                                              BIIDLogError(@"fetch error %@, %@:%@", url, res, error);
                                              if (completion) {
                                                  completion(nil);
                                              }
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
                                                  if (completion) {
                                                      completion(cache.image);
                                                  }
                                              });
                                          } else {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  if (completion) {
                                                      completion(nil); // error, invalid data
                                                  }
                                              });
                                          }

                                      });
                                  }];
    });
    return nil;
}

- (NSString*)keyWithURL:(NSString*)url
{
    const char *cStr = [url UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
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
