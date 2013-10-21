//
//  BIImageDownloader.h
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #define BIImageType UIImage
#elif TARGET_OS_MAC
    #define BIImageType NSImage
#endif


typedef void(^BIImageDownloaderCompleteBlock)(BIImageType* image); // nil is failed. UIImage or NSImage

@interface BIImageDownloader : NSObject

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

+ (instancetype)sharedInstance;

- (BIImageType*)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)expireTime completion:(BIImageDownloaderCompleteBlock)completion;

@end
