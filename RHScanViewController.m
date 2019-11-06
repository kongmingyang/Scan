//
//  RHScanViewController.m
//  RHScan
//
//  Created by river on 2018/2/1.
//  Copyright © 2018年 richinfo. All rights reserved.
//

#import "RHScanViewController.h"
#import "RHScanPermissions.h"
#import "RHScanNative.h"
#import "RHScanView.h"

@interface RHScanViewController ()<UIGestureRecognizerDelegate>

#pragma mark -----  扫码使用的库对象 -------


@property (nonatomic,strong) RHScanNative* scanObj;


/// 扫码区域视图,二维码一般都是框
@property (nonatomic,strong) RHScanView* qRScanView;


///记录开始的缩放比例
@property(nonatomic,assign)CGFloat beginGestureScale;

///最后的缩放比例
@property(nonatomic,assign)CGFloat effectiveScale;


@end

@implementation RHScanViewController

#pragma mark - life

- (void)viewDidLoad {
    
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.view.backgroundColor = [UIColor blackColor];
     _effectiveScale = 1;
    [self cameraInitOver];
    
    [self drawScanView];

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    
    [RHScanPermissions requestCameraPemissionWithResult:^(BOOL granted) {
        if (granted) {
            //不延时，可能会导致界面黑屏并卡住一会
            [self performSelector:@selector(startScan) withObject:nil afterDelay:0.1];
            
        }else{
            [_qRScanView stopDeviceReadying];
            [self showError:@"   请到设置隐私中开启本程序相机权限   " withReset:NO];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self stopScan];
    [_qRScanView stopScanAnimation];
    
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//绘制扫描区域
- (void)drawScanView
{
    if (!_qRScanView)
    {
        CGRect rect = self.view.frame;
        rect.origin = CGPointMake(0, 0);
        if (_style == nil) {
            _style = [RHScanViewStyle new];
        }
        self.qRScanView = [[RHScanView alloc]initWithFrame:rect style:_style];
        
        [self.view addSubview:_qRScanView];
    }
    [_qRScanView startDeviceReadyingWithText:_cameraInvokeMsg];
}

#pragma mark 增加拉近/远视频界面
- (void)cameraInitOver
{
    if (self.isVideoZoom) {
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
        pinch.delegate = self;
        [self.view addGestureRecognizer:pinch];
    }
}

- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser
{
    self.effectiveScale = self.beginGestureScale * recogniser.scale;
    if (self.effectiveScale < 1.0){
        self.effectiveScale = 1.0;
    }
    [self.scanObj setVideoScale:self.effectiveScale];
    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}

- (void)reStartDevice
{
     [_scanObj startScan];
}

//启动设备
- (void)startScan
{
    if ( ![RHScanPermissions cameraPemission] )
    {
        [_qRScanView stopDeviceReadying];
        [self showError:@"   请到设置隐私中开启本程序相机权限   " withReset:NO];
        return;
    }
    
    UIView *videoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    videoView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:videoView atIndex:0];
    __weak __typeof(self) weakSelf = self;
    
    if (!_scanObj )
    {
        CGRect cropRect = CGRectZero;
        
        if (_isOpenInterestRect) {
            
            //设置只识别框内区域
            cropRect = [RHScanView getScanRectWithPreView:self.view style:_style];
        }
        //AVMetadataObjectTypeITF14Code 扫码效果不行,另外只能输入一个码制，虽然接口是可以输入多个码制
        self.scanObj = [[RHScanNative alloc]initWithPreView:videoView ObjectType:nil cropRect:cropRect success:^(NSArray<NSString *> *array) {
            
            [weakSelf scanResultWithArray:array];
        }];
        [_scanObj setNeedCaptureImage:NO];
        [_scanObj setNeedAutoVideoZoom:YES];
    }
    [_scanObj startScan];
    [_qRScanView stopDeviceReadying];
    [_qRScanView startScanAnimation];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)stopScan
{
    [_scanObj stopScan];
}

#pragma mark - 扫码结果处理

- (void)scanResultWithArray:(NSArray<NSString*>*)array
{
    //经测试，可以同时识别2个二维码，不能同时识别二维码和条形码
    if (array.count < 1)
    {
        [self showError:@"识别失败了" withReset:YES];
        
        return;
    }
    if (!array[0] || [array[0] isEqualToString:@""] ) {
        
        [self showError:@"识别失败了" withReset:YES];
        return;
    }
    NSString *scanResult = array[0];
    NSLog(@"%@",scanResult);
    [self showError:scanResult withReset:YES];
    //TODO: 这里可以根据需要自行添加震动或播放声音提示相关代码
    //加载菊花
    //停止扫描
}



#pragma mark - 提示语
- (void)showError:(NSString*)str withReset:(BOOL)isRest
{
    if (str==nil || [str isEqualToString:@""]) {
        str =@"扫码失败，请重新扫一扫";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:str preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self startScan];
        NSLog(@"重新扫一扫");
        
        [self.qRScanView stopDeviceReadying];
        
    }];
    [alertController addAction:confirmAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

@end

