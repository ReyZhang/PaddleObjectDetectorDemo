//
//  ResourceManager.h
//  object-detector
//
//  Created by boss on 2025/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResourceManager : NSObject

/**
 根据版本检查并更新模型
 version : 服务器端版本号
 resourceUrl： 资源地址 .zip
 */
- (void)checkAndUpdateModelFromVersion:(NSString *)serverVersion
                                resourceUrl:(NSURL *)resourceUrl
                                completeBlock: (void(^)(BOOL success,NSString *message))block;


/**
 本地模型版本
 */
+ (NSString *)localVersion;

@end

NS_ASSUME_NONNULL_END
