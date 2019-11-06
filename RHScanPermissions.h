//
//  RHScanPermissions.m
//  RHScan
//
//  Created by river on 2018/2/1.
//  Copyright © 2018年 richinfo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RHScanPermissions : NSObject

+ (BOOL)cameraPemission;

+ (void)requestCameraPemissionWithResult:(void(^)( BOOL granted))completion;

+ (BOOL)photoPermission;

@end
