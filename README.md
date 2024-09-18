# XZLocalization

[![CI Status](https://img.shields.io/badge/Build-pass-brightgreen.svg)](https://cocoapods.org/pods/XZLocalization)
[![Version](https://img.shields.io/cocoapods/v/XZLocalization.svg?style=flat)](https://cocoapods.org/pods/XZLocalization)
[![License](https://img.shields.io/cocoapods/l/XZLocalization.svg?style=flat)](https://cocoapods.org/pods/XZLocalization)
[![Platform](https://img.shields.io/cocoapods/p/XZLocalization.svg?style=flat)](https://cocoapods.org/pods/XZLocalization)

## 示例项目 Example

要运行示例项目，请在拉取代码后，先在`Pods`目录执行`pod install`命令。

To run the example project, clone the repo, and run `pod install` from the Pods directory first.

## 环境需求 Requirements

iOS 12.0, Xcode 14.0

## 如何安装 Installation

推荐使用 [CocoaPods](https://cocoapods.org) 安装 XZLocalization 组件，在`Podfile`文件中添加下面这行代码即可。

XZLocalization is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'XZLocalization'
```

## 如何使用

1、支持带参数的本地化字符串

```objc
XZLocalizedString(@"{0}在{1}去过{2}。", data.name, data.date, data.place]);
```

2、应用内语言切换支持

```objc
XZLocalization.isInAppLanguagePreferencesEnabled = YES;
XZLocalization.preferredLanguage = XZAppLanguageEnglish;
```

## Author

Xezun, developer@xezun.com

## License

XZLocalization is available under the MIT license. See the LICENSE file for more info.
