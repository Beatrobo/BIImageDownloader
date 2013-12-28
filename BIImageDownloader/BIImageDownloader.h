#import "BIImageType.h"


typedef void(^BIImageDownloaderCompleteBlock)(BIImageType* image); // nil is failed. UIImage or NSImage


@interface BIImageDownloader : NSObject

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

+ (instancetype)sharedInstance;

- (BIImageType*)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)expireTime completion:(BIImageDownloaderCompleteBlock)completion;

@end
