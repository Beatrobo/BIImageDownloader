#import "BIImageType.h"


typedef void(^BIImageDownloaderCompleteBlock)(BIImageType* image); // nil is failed. UIImage or NSImage


@interface BIImageDownloader : NSObject

+ (instancetype)sharedInstance;
@property (nonatomic, readonly) NSOperationQueue* operationQueue;

@property (nonatomic ,readonly) dispatch_queue_t completionQueue; // default is main queue
- (BIImageType*)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)lifeTime completion:(BIImageDownloaderCompleteBlock)completion;

@end
