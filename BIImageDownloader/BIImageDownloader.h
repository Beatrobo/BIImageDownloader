//
//  BIImageDownloader.h
//  BIImageDownloader
//
//  Created by Yusuke Sugamiya on 2013/07/19.
//  Original by ito on 2012/09/03.
//  Copyright (c) 2013年 Beatrobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BIImageDownloaderCompleteBlock)(id image); // nil is failed. UIImage or NSImage

@interface BIImageDownloader : NSObject

@property (nonatomic, readonly) NSOperationQueue* operationQueue;

+ (instancetype)sharedInstance;

- (void)getImageWithURL:(NSString*)url useOnMemoryCache:(BOOL)useOnMemoryCache lifeTime:(NSUInteger)expireTime completion:(BIImageDownloaderCompleteBlock)completion;

@end
