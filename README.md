
# SGQRCode
本项目是对SGQRCode做了简单的修改，增加了拉近放大功能，原项目连接https://github.com/kingsic/SGQRCode


## 主要内容的介绍

* `生成二维码`<br>

* `扫描二维码`<br>

* `从相册中读取二维码`<br>

* `根据光线强弱开启手电筒`<br>

* `扫描成功之后界面之间逻辑跳转处理`<br>

* `扫描界面可自定义（线扫描条样式以及网格样式）`<br>

* `扫描界面仿微信（请根据项目需求，自行布局或调整）`<br>



## 代码介绍 (详细使用，请参考 Demo)

#### 1、在 info.plist 中添加以下字段（iOS 10 之后需添加的字段）

* `NSCameraUsageDescription (相机权限访问)`<br>

* `NSPhotoLibraryUsageDescription (相册权限访问)`<br>

#### 2、二维码扫描

```Objective-C
    __weak typeof(self) weakSelf = self;

    /// 创建二维码扫描
    SGQRCodeObtainConfigure *configure = [SGQRCodeObtainConfigure QRCodeObtainConfigure];
    [obtain establishQRCodeObtainScanWithController:self configure:configure];
    // 二维码扫描回调方法
    [obtain setBlockWithQRCodeObtainScanResult:^(SGQRCodeObtain *obtain, NSString *result) {
        <#code#>
    }];
    // 二维码扫描开启方法: 需手动开启
    [obtain startRunningWithBefore:^{
        // 在此可添加 HUD
    } completion:^{
        // 在此可移除 HUD
    }];
    // 根据外界光线强弱值判断是否自动开启手电筒
    [obtain setBlockWithQRCodeObtainScanBrightness:^(SGQRCodeObtain *obtain, CGFloat brightness) {
        <#code#>
    }];
    
    /// 从相册中读取二维码    
    [obtain establishAuthorizationQRCodeObtainAlbumWithController:self];
    // 从相册中读取图片上的二维码回调方法
    [obtain setBlockWithQRCodeObtainAlbumResult:^(SGQRCodeObtain *obtain, NSString *result) {
        <#code#>
    }];
```

#### 3、二维码生成

```Objective-C
    /// 常规二维码
    _imageView.image = [SGQRCodeObtain generateQRCodeWithData:@"https://github.com/kingsic" size:size];
    
    /// 带 logo 的二维码
    _imageView.image = [SGQRCodeObtain generateQRCodeWithData:@"https://github.com/kingsic" size:size logoImage:logoImage ratio:ratio];
```


## 效果图

![](https://github.com/kingsic/SGQRCode/raw/master/Picture/sorgle1.png)       ![](https://github.com/kingsic/SGQRCode/raw/master/Picture/sorgle2.png)

![](https://github.com/kingsic/SGQRCode/raw/master/Picture/sorgle3.png)       ![](https://github.com/kingsic/SGQRCode/raw/master/Picture/sorgle4.png)


## 问题及解决方案

* 若在使用 CocoaPods 安装第三方时，出现 [!] Unable to find a specification for SGQRCode 提示时，打开终端先输入 pod repo remove master；执行完毕后再输入 pod setup 即可 (可能会等待一段时间)

* [iOS 从相册中读取条形码/二维码遇到的问题](https://blog.csdn.net/gaomingyangc/article/details/54017879)

* iOS 扫描支持 7.0+；从相册中读取二维码支持 8.0+；因此，CocoaPods 版本最低支持 8.0+


