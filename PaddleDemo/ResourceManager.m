//
//  ResourceManager.m
//  object-detector
//
//  Created by boss on 2025/7/12.
//

#import "ResourceManager.h"
#import <SSZipArchive/SSZipArchive.h>
#import <CommonCrypto/CommonDigest.h>

@interface ResourceManager ()

@property(nonatomic,strong) NSString *serverVersion;
@property(nonatomic,copy) void(^resultBlock)(BOOL success,NSString *message);

@end

@implementation ResourceManager


/**
 根据版本检查并更新模型
 version : 版本号
 resourceUrl： 资源地址 .zip
 */
- (void)checkAndUpdateModelFromVersion:(NSString *)serverVersion
                                resourceUrl:(NSURL *)resourceUrl
                                completeBlock: (void(^)(BOOL success,NSString *message))block {
    self.resultBlock = block;
    self.serverVersion = serverVersion;
    
    if (nil == serverVersion || [serverVersion isEqualToString:@""]) {
        !self.resultBlock ?: self.resultBlock(NO,@"serverVersion 版本参数不能为空");
        return;
    }
    
    if (nil == resourceUrl) {
        !self.resultBlock ?: self.resultBlock(NO,@"resourceUrl 资源包参数不能为空");
        return;
    }
    
    //读取当前本地版本号
    NSString *localVersion = [[self class] localVersion];
    
    //服务端版本号与本地版本号比较
    if ([self version:serverVersion isNewerThan:localVersion]) {
        NSLog(@"⬇️ 发现新版本：%@ → %@，准备下载资源包...", localVersion, serverVersion);
        [self downloadAndUpdateBundleFromURL:resourceUrl
                               serverVersion:serverVersion];
    } else {
        !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"当前模型是最新版本：%@", localVersion]);
        return;
    }
    
}



/**
 根据资源文件地址，下载资源
 */
- (void)downloadAndUpdateBundleFromURL:(NSURL *)zipURL
                         serverVersion:(NSString *)version {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:zipURL completionHandler:^(NSURL *location, NSURLResponse *res, NSError *err) {
        if (err || !location) {
            !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"下载 zip 失败: %@",err.localizedDescription]);
            return;
        }
        

        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //1. 解压到临时目录
        NSString *tempUnzipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"res_unzip"];
        [fileManager removeItemAtPath:tempUnzipPath error:nil];
        BOOL ok = [SSZipArchive unzipFileAtPath:location.path toDestination:tempUnzipPath];
        if (!ok) {
            !self.resultBlock ?: self.resultBlock(NO,@"解压失败");
            return;
        }else {
            tempUnzipPath = [tempUnzipPath stringByAppendingPathComponent:@"version"];
        }
        
        //2. 复制到指定目录
        NSString *docPath = [self docPath]; //Documents所在目录
        NSString *modelPath = [docPath stringByAppendingString:@"/picodet_l_640_cpu.nb"];
        NSString *labelsPath = [docPath stringByAppendingString:@"/ti_label_list.txt"];
        
        // 2.1复制前先删除旧文件，不然会提示 File Exist的问题
        if ([fileManager fileExistsAtPath:modelPath]) {
            NSError *error;
            [fileManager removeItemAtPath:modelPath error:&error];
            if (error) {
                !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"删除模型文件出错: %@", error.localizedDescription]);
                return;
            }
        }
        
        if ([fileManager fileExistsAtPath:labelsPath]) {
            NSError *error;
            [fileManager removeItemAtPath:labelsPath error:&error];
            if (error) {
                !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"删除标签文件出错: %@", error.localizedDescription]);
                return;
            }
        }

        //2.2 将临时目录下的文件，复制到指定目录下
        BOOL modelUpdate = NO;
        BOOL labelsUpdate = NO;
        {
            NSError *copyErr;
            [[NSFileManager defaultManager] copyItemAtPath:[tempUnzipPath stringByAppendingString:@"/picodet_l_640_cpu.nb"] toPath:modelPath error:&copyErr];
            if (!copyErr) {
                NSLog(@"模型替换成功，新版本: %@", version);
                modelUpdate = YES;
               
            } else {
                !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"模型替换失败: %@", copyErr.localizedDescription]);
                modelUpdate = NO;
                return;
            }
        }
        
        {
            NSError *copyErr;
            [[NSFileManager defaultManager] copyItemAtPath:[tempUnzipPath stringByAppendingString:@"/ti_label_list.txt"] toPath:labelsPath error:&copyErr];
            if (!copyErr) {
                NSLog(@"标签替换成功，新版本: %@", version);
                labelsUpdate = YES;
               
            } else {
                !self.resultBlock ?: self.resultBlock(NO,[NSString stringWithFormat:@"标签替换失败: %@", copyErr.localizedDescription]);
                labelsUpdate = NO;
                return;
            }
        }
        
        
        //3.模型与标签均替换成功， 更新本地版本号
        if (modelUpdate && labelsUpdate) {
            
            NSString *localVersion = [[self class] localVersion];
            
            //更新本地存储的版本号
            [[NSUserDefaults standardUserDefaults] setObject:version forKey:[[self class] localVersionKey]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            !self.resultBlock ?: self.resultBlock(YES, [NSString stringWithFormat:@"版本升级成功: %@ → %@", localVersion, version]);
            
        }
        
    }];
    [task resume];
}




#pragma mark : -  private method

+ (NSString *)localVersionKey {
    return @"LocalResourceBundleVersion";
}

+ (NSString *)localVersion {
    return [[NSUserDefaults standardUserDefaults] stringForKey:[self localVersionKey]] ?: @"0.0.0";
}


- (NSString *)docPath {
    NSURL *docURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    return [docURL path];
}

- (BOOL)version:(NSString *)v1 isNewerThan:(NSString *)v2 {
    NSArray *a = [v1 componentsSeparatedByString:@"."];
    NSArray *b = [v2 componentsSeparatedByString:@"."];
    NSInteger count = MAX(a.count, b.count);
    for (NSInteger i = 0; i < count; i++) {
        NSInteger x = (i < a.count) ? [a[i] intValue] : 0;
        NSInteger y = (i < b.count) ? [b[i] intValue] : 0;
        if (x > y) return YES;
        if (x < y) return NO;
    }
    return NO;
}

- (NSString *)md5:(NSData *)data {
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *out = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02x", digest[i]];
    }
    return out;
}


@end
