#import "BIImageType.h"


typedef void(^BIImageDownloaderCompleteBlock)(BIImageType* image); // nil is failed. UIImage or NSImage


@interface BIImageDownloader : NSObject

+ (instancetype)sharedInstance;

- (BIImageType*)getImageWithURL:(NSString*)url
               useOnMemoryCache:(BOOL)useOnMemoryCache
                       lifeTime:(NSUInteger)lifeTime
                     completion:(BIImageDownloaderCompleteBlock)completion;

-  (BIImageType*)getImageWithURL:(NSString*)url
                useOnMemoryCache:(BOOL)useOnMemoryCache
                        lifeTime:(NSUInteger)lifeTime
feedbackNetworkActivityIndicator:(BOOL)feedbackNetworkActivityIndicator
                 completionQueue:(dispatch_queue_t)queue
                      completion:(BIImageDownloaderCompleteBlock)completion;

@end
