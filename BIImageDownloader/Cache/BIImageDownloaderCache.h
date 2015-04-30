#import "BIImageType.h"


@interface BIImageDownloaderCache : NSObject

+ (instancetype)cacheWithData:(NSData*)data key:(NSString*)key; // returns nil if data is nil
+ (instancetype)cacheFromStorageWithKey:(NSString*)key usingFileManager:(NSFileManager*)fm; // returns nil if no data on storage

@property (nonatomic, readonly) BIImageType* image;

- (void)save;
- (void)deleteUsingFileManager:(NSFileManager*)fm;
- (BOOL)isExpiredWith:(NSTimeInterval)time lifeTime:(NSTimeInterval)lifeTime;

@end
