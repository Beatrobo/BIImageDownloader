#import  "BIImageDownloader.h"
#import  "BIImageDownloaderCache.h"
#import  <CommonCrypto/CommonDigest.h>
#include <time.h>
#import  "BIReachability.h"


@interface BIImageDownloader ()
{
    dispatch_queue_t     _storageQueue;
    NSFileManager*       _fm;
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
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
        _fm = [[NSFileManager alloc] init];
        _storageQueue = dispatch_queue_create("com.beatrobo.library.BIImageDownloader.storage", DISPATCH_QUEUE_SERIAL);
        _memoryCache = [NSMutableDictionary dictionaryWithCapacity:50];

        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        #endif
    }
    return self;
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
        if (completion) {
            completion(cache.image);
        }
        return cache.image;
    }

    dispatch_async(_storageQueue, ^{
        BIImageDownloaderCache* cache = [self cacheForKey:key onMemory:NO expiresTime:expireTime];
        if (cache.image) {
            @synchronized(_memoryCache) {
                [_memoryCache setObject:cache forKey:key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(cache.image);
                }
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
                [BIReachability beginNetworkConnection];
                [_operationQueue addOperationWithBlock:^{
                    NSURLResponse* res   = nil;
                    NSError*       error = nil;
                    NSData*        data  = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [BIReachability endNetworkConnection];
                        if (!data) {
                            if (completion) {
                                completion(nil);
                            }
                        }
                        else {
                            dispatch_async(_storageQueue, ^{
                                BIImageDownloaderCache* cache = [BIImageDownloaderCache cacheWithData:data key:key];
                                if (!cache.image) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (completion) {
                                            completion(nil); // error, invalid data
                                        }
                                    });
                                }
                                else {
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
                                }
                            });
                        }
                    });
                }];
            });
        }
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
    }
    else {
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
