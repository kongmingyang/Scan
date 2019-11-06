//
//  RHScanView.h
//
//  
//  Created by Richinfo on 16/11/16.
//  Copyright © 2016年 Richinfo. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "RHScanLineAnimation.h"
#import "RHScanNetAnimation.h"
#import "RHScanViewStyle.h"

/**
 扫码区域显示效果
 */
@interface RHScanView : UIView

/**
 @brief  初始化
 @param frame 位置大小
 @param style 类型

 @return instancetype
 */
-(id)initWithFrame:(CGRect)frame style:(RHScanViewStyle*)style;

/**
 *  设备启动中文字提示
 */
- (void)startDeviceReadyingWithText:(NSString*)text;

/**
 *  设备启动完成
 */
- (void)stopDeviceReadying;

/**
 *  开始扫描动画
 */
- (void)startScanAnimation;

/**
 *  结束扫描动画
 */
- (void)stopScanAnimation;

/**
 返回扫描区域坐标

 @return 坐标
 */
-(CGRect)getScanRetangleRect;

//

/**
 @brief  根据矩形区域，获取Native扫码识别兴趣区域
 @param view  视频流显示UIView
 @param style 效果界面参数
 @return 识别区域
 */
+ (CGRect)getScanRectWithPreView:(UIView*)view style:(RHScanViewStyle*)style;



/**
 根据矩形区域，获取ZXing库扫码识别兴趣区域

 @param view 视频流显示视图
 @param style 效果界面参数
 @return 识别区域
 */
+ (CGRect)getZXingScanRectWithPreView:(UIView*)view style:(RHScanViewStyle*)style;


@end
