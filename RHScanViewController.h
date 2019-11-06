//
//  RHScanViewController.h
//  RHScan
//
//  Created by river on 2018/2/1.
//  Copyright © 2018年 richinfo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RHScanViewStyle.h"


@interface RHScanViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>


#pragma mark ---- 需要初始化参数 ------

#pragma mark 扫描功能定制

///相机启动提示,如 相机启动中...
@property (nonatomic, copy) NSString *cameraInvokeMsg;

///自定义扫描框界面效果参数
@property (nonatomic, strong) RHScanViewStyle *style;

///启动区域识别功能
@property(nonatomic,assign) BOOL isOpenInterestRect;

///增加拉近/远视频界面
@property (nonatomic, assign) BOOL isVideoZoom;



#pragma mark - 扫码界面效果及提示等

///闪关灯开启状态记录
@property(nonatomic,readonly,assign)BOOL isOpenFlash;

///扫码存储的当前图片
@property(nonatomic,strong) UIImage* scanImage;

#pragma mark - 扫码界面操作等

///启动扫描
- (void)startScan;

///关闭扫描
- (void)stopScan;


@end

