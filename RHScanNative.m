//
//  RHScanNative.m
//  RHScan
//
//  Created by river on 2018/2/1.
//  Copyright © 2018年 richinfo. All rights reserved.
//

#import "RHScanNative.h"

@interface RHScanNative()<AVCaptureMetadataOutputObjectsDelegate>
{
    BOOL bNeedScanResult;
    BOOL bHadAutoVideoZoom;
}

@property (assign,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;

@property(nonatomic,strong)  AVCaptureStillImageOutput *stillImageOutput;//拍照

@property(nonatomic,assign)BOOL isNeedCaputureImage;

@property(nonatomic,assign)BOOL isAutoVideoZoom;

@property (assign,nonatomic)CGFloat initialPinchZoom;

///扫码结果
@property (nonatomic, strong) NSMutableArray<NSString*> *arrayResult;

///扫码类型
@property (nonatomic, strong) NSArray* arrayBarCodeType;

///视频预览显示视图
@property (nonatomic,weak)UIView *videoPreView;

/*** 专门用于保存描边的图层 ***/
@property (nonatomic,strong) CALayer *containerLayer;


/*!
 *  扫码结果返回
 */
@property(nonatomic,copy)void (^blockScanResult)(NSArray<NSString*> *array);


@end

@implementation RHScanNative


- (void)setNeedCaptureImage:(BOOL)isNeedCaputureImg
{
    _isNeedCaputureImage = isNeedCaputureImg;
}

-(void)setNeedAutoVideoZoom:(BOOL)isAutoVideoZoom
{
    _isAutoVideoZoom = isAutoVideoZoom;
}

- (CALayer *)containerLayer
{
    if (_containerLayer == nil) {
        _containerLayer = [[CALayer alloc] init];
    }
    return _containerLayer;
}


- (instancetype)initWithPreView:(UIView*)preView ObjectType:(NSArray*)objType cropRect:(CGRect)cropRect success:(void(^)(NSArray<NSString*> *array))block
{
    if (self = [super init]) {
        [self initParaWithPreView:preView ObjectType:objType cropRect:cropRect success:block];
    }
    return self;
}

- (instancetype)initWithPreView:(UIView*)preView ObjectType:(NSArray*)objType success:(void(^)(NSArray<NSString*> *array))block
{
    if (self = [super init]) {
        
        [self initParaWithPreView:preView ObjectType:objType cropRect:CGRectZero success:block];
    }
    
    return self;
}


- (void)initParaWithPreView:(UIView*)videoPreView ObjectType:(NSArray*)objType cropRect:(CGRect)cropRect success:(void(^)(NSArray<NSString*> *array))block
{
    self.arrayBarCodeType = objType;
    self.blockScanResult = block;
    self.videoPreView = videoPreView;
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (!_device) {
        return;
    }
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    if ( !_input  )
        return ;
    
    
    bNeedScanResult = YES;
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    
    if ( !CGRectEqualToRect(cropRect,CGRectZero) )
    {
        _output.rectOfInterest = cropRect;
    }
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    
    if ([_session canAddInput:_input])
    {
        [_session addInput:_input];
    }
    
    if ([_session canAddOutput:_output])
    {
        [_session addOutput:_output];
    }

    if ([_session canAddOutput:_stillImageOutput])
    {
        [_session addOutput:_stillImageOutput];
    }
    
    if (!objType) {
        objType = [self defaultMetaDataObjectTypes];
    }
    
    _output.metadataObjectTypes = objType;
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    CGRect frame = videoPreView.frame;
    frame.origin = CGPointZero;
    _preview.frame = frame;
    
    [videoPreView.layer insertSublayer:self.preview atIndex:0];
 
    // 7.添加容器图层
    [videoPreView.layer addSublayer:self.containerLayer];
     self.containerLayer.frame = frame;
    
    
     [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
//    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
//     CGFloat scale = videoConnection.videoScaleAndCropFactor;

    [_input.device lockForConfiguration:nil];
    
    //自动白平衡
    if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
    {
        [_input.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }
    //先进行判断是否支持控制对焦,不开启自动对焦功能，很难识别二维码。
    if (_device.isFocusPointOfInterestSupported &&[_device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        [_input.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    }
    //自动曝光
    if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
    {
        [_input.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
     [_input.device unlockForConfiguration];
    
}
- (BOOL)getFlashMode
{
    AVCaptureTorchMode torch = self.input.device.torchMode;
    if(torch == AVCaptureTorchModeOn)
    {
        return YES;
    }
    return NO;
}

- (CGFloat)getVideoMaxScale
{
    [_input.device lockForConfiguration:nil];
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
    CGFloat maxScale = videoConnection.videoMaxScaleAndCropFactor;
    [_input.device unlockForConfiguration];
    
    return maxScale;
}

-(CGFloat)getVideoZoomFactor
{
    return _input.device.videoZoomFactor;
}

-(AVCaptureVideoPreviewLayer *)getVideoPreview
{
    return _preview;
}

- (void)setVideoScale:(CGFloat)scale
{
    [_input.device lockForConfiguration:nil];
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
    CGFloat maxScaleAndCropFactor = ([[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor])/16;
    
    if (scale > maxScaleAndCropFactor)
        scale = maxScaleAndCropFactor;
    
    CGFloat zoom = scale / videoConnection.videoScaleAndCropFactor;
    
    videoConnection.videoScaleAndCropFactor = scale;
    
    [_input.device unlockForConfiguration];
    
    CGAffineTransform transform = _videoPreView.transform;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    
     _videoPreView.transform = CGAffineTransformScale(transform, zoom, zoom);
    
    [CATransaction commit];
   
}

- (void)changeScanType:(NSArray*)objType
{    
    _output.metadataObjectTypes = objType;
}

- (void)startScan
{
    if ( _input && !_session.isRunning )
    {
        [_session startRunning];
        bNeedScanResult = YES;
        
        [_videoPreView.layer insertSublayer:self.preview atIndex:0];
        
       // [_input.device addObserver:self forKeyPath:@"torchMode" options:0 context:nil];
    }
    bNeedScanResult = YES;
    bHadAutoVideoZoom = NO;
    [self setVideoScale:1];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( object == _input.device ) {
    }
}

- (void)stopScan
{
    bNeedScanResult = NO;
    if ( _input && _session.isRunning )
    {
        bNeedScanResult = NO;
        [_session stopRunning];
    }
}

- (void)setTorch:(BOOL)torch {   
    
    [self.input.device lockForConfiguration:nil];
    self.input.device.torchMode = torch ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
    [self.input.device unlockForConfiguration];
}

- (void)changeTorch
{
    AVCaptureTorchMode torch = self.input.device.torchMode;
   
    switch (_input.device.torchMode) {
        case AVCaptureTorchModeAuto:
            break;
        case AVCaptureTorchModeOff:
            torch = AVCaptureTorchModeOn;
            break;
        case AVCaptureTorchModeOn:
            torch = AVCaptureTorchModeOff;
            break;
        default:
            break;
    }
    
    [_input.device lockForConfiguration:nil];
    _input.device.torchMode = torch;
    [_input.device unlockForConfiguration];
}


-(UIImage *)getImageFromLayer:(CALayer *)layer size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, YES, [[UIScreen mainScreen]scale]);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}

- (void)captureImage
{
    AVCaptureConnection *stillImageConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
    
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
     {
         [self stopScan];
         
         if (_blockScanResult)
         {
             _blockScanResult(_arrayResult);
         }
         
     }];
}

- (void)changeVideoScale:(AVMetadataMachineReadableCodeObject *)objc
{
    NSArray *array = objc.corners;
    CGPoint point = CGPointZero;
    int index = 0;
    CFDictionaryRef dict = (__bridge CFDictionaryRef)(array[index++]);
    // 把点转换为不可变字典
    // 把字典转换为点，存在point里，成功返回true 其他false
    CGPointMakeWithDictionaryRepresentation(dict, &point);
    NSLog(@"X:%f -- Y:%f",point.x,point.y);
    CGPoint point2 = CGPointZero;
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[2], &point2);
    NSLog(@"X:%f -- Y:%f",point2.x,point2.y);
    CGFloat scace =150/(point2.x-point.x); //当二维码图片宽小于150，进行放大
    if (scace > 1) {
        for (CGFloat i= 1.0; i<=scace; i = i+0.001) {
            [self setVideoScale:i];
        }
    }
    return;
}

- (void)drawLine:(AVMetadataMachineReadableCodeObject *)objc
{

    NSArray *array = objc.corners;
    
    // 1.创建形状图层, 用于保存绘制的矩形
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    
    // 设置线宽
    layer.lineWidth = 2;
    // 设置描边颜色
    layer.strokeColor = [UIColor greenColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 2.创建UIBezierPath, 绘制矩形
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointZero;
    int index = 0;
    
    CFDictionaryRef dict = (__bridge CFDictionaryRef)(array[index++]);
    // 把点转换为不可变字典
    // 把字典转换为点，存在point里，成功返回true 其他false
    CGPointMakeWithDictionaryRepresentation(dict, &point);
    
    // 设置起点
    [path moveToPoint:point];
    NSLog(@"X:%f -- Y:%f",point.x,point.y);
    
    // 2.2连接其它线段
    for (int i = 1; i<array.count; i++) {
        CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[i], &point);
        [path addLineToPoint:point];
        NSLog(@"X:%f -- Y:%f",point.x,point.y);
    }
    // 2.3关闭路径
    [path closePath];
    layer.path = path.CGPath;
    // 3.将用于保存矩形的图层添加到界面上
    [self.containerLayer addSublayer:layer];
}

- (void)clearLayers
{
    if (self.containerLayer.sublayers)
    {
        for (CALayer *subLayer in self.containerLayer.sublayers)
        {
            [subLayer removeFromSuperlayer];
        }
    }
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!bNeedScanResult) {
        return;
    }
    
    bNeedScanResult = NO;
    
    if (!_arrayResult) {
        
        self.arrayResult = [NSMutableArray arrayWithCapacity:1];
    }
    else
    {
        [_arrayResult removeAllObjects];
    }
    
    //识别扫码类型
    for(AVMetadataObject *current in metadataObjects)
    {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]] )
        {
            bNeedScanResult = NO;
            NSString *scannedResult = [(AVMetadataMachineReadableCodeObject *) current stringValue];
            
            if (scannedResult && ![scannedResult isEqualToString:@""])
            {
                [_arrayResult addObject:scannedResult];
            }
            //测试可以同时识别多个二维码
        }
    }
    
    if (_arrayResult.count < 1)
    {
        bNeedScanResult = YES;
        return;
    }
    if (_isAutoVideoZoom && !bHadAutoVideoZoom) {
        
        AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)[self.preview transformedMetadataObjectForMetadataObject:metadataObjects.lastObject];
        [self changeVideoScale:obj];
         bNeedScanResult = YES;
         bHadAutoVideoZoom  =YES;
        return;
    }
    if (_isNeedCaputureImage)
    {
        [self captureImage];
    }
    else
    {
        [self stopScan];

        if (_blockScanResult) {
            _blockScanResult(_arrayResult);
        }
    }
}


/**
 @brief  默认支持码的类别
 @return 支持类别 数组
 */
- (NSArray *)defaultMetaDataObjectTypes
{
    NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                               AVMetadataObjectTypeUPCECode,
                               AVMetadataObjectTypeCode39Code,
                               AVMetadataObjectTypeCode39Mod43Code,
                               AVMetadataObjectTypeEAN13Code,
                               AVMetadataObjectTypeEAN8Code,
                               AVMetadataObjectTypeCode93Code,
                               AVMetadataObjectTypeCode128Code,
                               AVMetadataObjectTypePDF417Code,
                               AVMetadataObjectTypeAztecCode] mutableCopy];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0)
    {
        [types addObjectsFromArray:@[
                                     AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                     AVMetadataObjectTypeDataMatrixCode
                                     ]];
    }
    
    return types;
}

#pragma mark --识别条码图片
+ (void)recognizeImage:(UIImage*)image success:(void(^)(NSArray<NSString*> *array))block;
{
    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 8.0 )
    {
        if (block) {
            block(@[@"只支持ios8.0之后系统"]);
        }
        return;
    }
    
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    NSMutableArray<NSString*> *mutableArray = [[NSMutableArray alloc]initWithCapacity:1];
    for (int index = 0; index < [features count]; index ++)
    {
        CIQRCodeFeature *feature = [features objectAtIndex:index];
        NSString *scannedResult = feature.messageString;
        [mutableArray addObject:scannedResult];
    }
    if (block) {
        block(mutableArray);
    }
}

#pragma mark --生成条码

//下面引用自 https://github.com/yourtion/Demo_CustomQRCode
#pragma mark - InterpolatedUIImage
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CGColorSpaceRelease(cs);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    UIImage *aImage = [UIImage imageWithCGImage:scaledImage];
    CGImageRelease(scaledImage);
    return aImage;
}

#pragma mark - QRCodeGenerator
+ (CIImage *)createQRForString:(NSString *)qrString {
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    // 创建filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 设置内容和纠错级别
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    // 返回CIImage
    return qrFilter.outputImage;
}


#pragma mark - 生成二维码，背景色及二维码颜色设置

+ (UIImage*)createQRWithString:(NSString*)text QRSize:(CGSize)size
{
    NSData *stringData = [text dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];

    CIImage *qrImage = qrFilter.outputImage;
    
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;

}
//引用自:http://www.jianshu.com/p/e8f7a257b612
+ (UIImage*)createQRWithString:(NSString*)text QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor
{
    
    NSData *stringData = [text dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                       keysAndValues:
                             @"inputImage",qrFilter.outputImage,
                             @"inputColor0",[CIColor colorWithCGColor:qrColor.CGColor],
                             @"inputColor1",[CIColor colorWithCGColor:bkColor.CGColor],
                             nil];
    
    CIImage *qrImage = colorFilter.outputImage;
    
    //绘制
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}

+ (UIImage*)createQRWithString:(NSString*)text QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor logo:(UIImage *)logo
{
    
    NSData *stringData = [text dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                       keysAndValues:
                             @"inputImage",qrFilter.outputImage,
                             @"inputColor0",[CIColor colorWithCGColor:qrColor.CGColor],
                             @"inputColor1",[CIColor colorWithCGColor:bkColor.CGColor],
                             nil];
    // 取出输出图片
    CIImage *outputImage = [colorFilter outputImage];
    outputImage = [outputImage imageByApplyingTransform:CGAffineTransformMakeScale(20, 20)];
    // 转化图片
    UIImage *image = [UIImage imageWithCIImage:outputImage];
    // 为二维码加自定义图片
    // 开启绘图, 获取图片 上下文<图片大小>
    CGFloat logoWidth = image.size.width/4.0;
    UIGraphicsBeginImageContext(image.size);
    // 将二维码图片画上去
    [image drawInRect:CGRectMake(0, 0, image.size.width,image.size.height)];
    // 将小图片画上去
    UIImage *smallImage =logo;
    [smallImage drawInRect:CGRectMake((image.size.width - logoWidth) / 2, (image.size.width - logoWidth) / 2, logoWidth, logoWidth)];
    // 获取最终的图片
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    // 关闭上下文
    UIGraphicsEndImageContext();
    // 显示
    return finalImage;
}

+ (UIImage*)createBarCodeWithString:(NSString*)text QRSize:(CGSize)size
{
    
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    CIFilter *filter = [CIFilter filterWithName:@"CICode128BarcodeGenerator"];
    
    [filter setValue:data forKey:@"inputMessage"];
    
     CIImage *barcodeImage = [filter outputImage];
    
    // 消除模糊
    CGFloat scaleX = size.width / barcodeImage.extent.size.width; // extent 返回图片的frame
    
    CGFloat scaleY = size.height / barcodeImage.extent.size.height;
    
    CIImage *transformedImage = [barcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
 
    return [UIImage imageWithCIImage:transformedImage];
    
}

+(UIImage*)image:(UIImage *)theImage
{
    UIImage* bigImage = theImage;
    float actualHeight = bigImage.size.height;
    float actualWidth = bigImage.size.width;
    float newWidth =0;
    float newHeight =0;
    if(actualWidth > actualHeight) {
        //宽图
        newHeight =256.0f;
        newWidth = actualWidth / actualHeight * newHeight;
    }
    else
    {
        //长图
        newWidth =256.0f;
        newHeight = actualHeight / actualWidth * newWidth;
    }
    CGRect rect =CGRectMake(0.0,0.0, newWidth, newHeight);
    UIGraphicsBeginImageContext(rect.size);
    [bigImage drawInRect:rect];// scales image to rect
    theImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //RETURN
    return theImage;
}

@end
