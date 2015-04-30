#import "BIImageDownloaderCache.h"


@interface BIImageDownloaderCache ()
{
    BIImageType* _image;
}
@end


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

+ (instancetype)cacheFromStorageWithKey:(NSString*)key usingFileManager:(NSFileManager*)fm;
{
    NSData* data = [NSData dataWithContentsOfFile:[[self cacheDirectoryPath] stringByAppendingPathComponent:key]];
    BIImageDownloaderCache* cache = [self cacheWithData:data key:key];
    if (!cache) {
        return nil;
    }
    cache.createdAt = [[fm attributesOfItemAtPath:[[self cacheDirectoryPath] stringByAppendingPathComponent:key] error:nil] fileCreationDate].timeIntervalSince1970;
    return cache;
}

- (BIImageType*)image
{
    if (_image) {
        return _image;
    }

    return [[BIImageType alloc] initWithData:_data];
}

- (BOOL)isExpiredWith:(NSTimeInterval)time lifeTime:(NSTimeInterval)lifeTime
{
    if ((NSTimeInterval)(fabs((double)time - (double)_createdAt)) > lifeTime) {
        return YES;
    }
    return NO;
}

- (void)save
{
    [_data writeToFile:[[[self class] cacheDirectoryPath] stringByAppendingPathComponent:_key] atomically:NO];
}

- (void)deleteUsingFileManager:(NSFileManager*)fm
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
