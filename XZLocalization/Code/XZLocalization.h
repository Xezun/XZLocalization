//
//  XZLocalization.h
//  XZLocalization
//
//  Created by 徐臻 on 2024/9/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// App 语言，如 cn、en、ar 等。
typedef NSString *XZAppLanguage NS_EXTENSIBLE_STRING_ENUM;

/// 简体中文，符号为 zh-Hans 字符串。
FOUNDATION_EXPORT XZAppLanguage const XZAppLanguageChinese NS_SWIFT_NAME(XZAppLanguage.Chinese);
/// 繁体中文，符号为 zh-Hant 字符串。
FOUNDATION_EXPORT XZAppLanguage const XZAppLanguageChineseTraditional NS_SWIFT_NAME(XZAppLanguage.ChineseTraditional);
/// 英文，符号为 en 字符串。
FOUNDATION_EXPORT XZAppLanguage const XZAppLanguageEnglish NS_SWIFT_NAME(XZAppLanguage.English);

/// 语言偏好设置发生改变。
FOUNDATION_EXPORT NSNotificationName const XZAppLanguagePreferencesDidChangeNotification NS_SWIFT_NAME(XZAppLanguage.preferencesDidChangeNotification);

/// 本地化支持组件。
///
/// 读取本地化字符串，推荐使用本组件建提供的宏，支持在本地化字符串中使用参数（最多支持 64 个参数）。
/// @code
/// XZLocalizedString(stringToBeLocalized, ...)
/// @endcode
/// 示例：以中文为本地化的默认语言时，展示某人在某时去过某地，比如，小明在10月1日去过天安门，如下代码。
/// @code
/// self.textLabel.text = XZLocalizedString(@"{0}在{1}去过{2}。", data.name, data.date, data.spot);
/// @endcode
/// 那么，在进行英文本地化时，就可以像下面这样配置本地化字符串表。
/// @code
/// "{0}在{1}去过{2}。" = "{0} went to {2} on {1}.";
/// @endcode
/// 虽然英文和中文的语序并不一致，但是在代码中，我们不需要调整的参数的书写顺序，只需要调整本地化字符串引用参数的顺序即可。
/// @note 由于 OC 参数列表限制，值 nil 之后的参数会被忽略。
/// @note 虽然查找字符串中的参数的插值，会有产生额外操作，但是当本地化字符串没有参数时，使用的是原生的本地化方法，实际对性能影响已降至最低。
@interface XZLocalization : NSObject

/// 应用首选语言。
///
/// - Note: 更新首选语言，默认需重启应用才会生效。
///
/// 结合 `isInAppLanguagePreferenceEnabled` 属性，可以开启在应用内切换应用语言。
///
/// ```objc
/// UIWindow * const window = _window;
/// CGRect const bounds = UIScreen.mainScreen.bounds;
///
/// _window = [[UIWindow alloc] initWithFrame:bounds];
/// _window.backgroundColor = UIColor.whiteColor;
/// UIViewController *rootVC = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
/// _window.rootViewController = rootVC;
/// [_window makeKeyAndVisible];
///
/// // 转场动画
/// _window.layer.shadowColor = UIColor.blackColor.CGColor;
/// _window.layer.shadowOpacity = 0.5;
/// _window.layer.shadowRadius = 5.0;
/// _window.windowLevel = window.windowLevel + 1;
/// _window.frame = CGRectOffset(bounds, bounds.size.height, 0);
/// [UIView animateWithDuration:0.5 animations:^{
///     self->_window.frame = bounds;
/// } completion:^(BOOL finished) {
///     window.hidden = YES; // 释放旧的 window
///     self->_window.layer.shadowColor = nil;
/// }];
/// ```
@property (class, nonatomic, copy) XZAppLanguage preferredLanguage;

/// 语言的书写方向。
/// @param language 语言
+ (NSLocaleLanguageDirection)languageDirectionForLanguage:(XZAppLanguage)language;

/// 应用支持的所有语言。
@property (class, nonatomic, copy, readonly) NSArray<XZAppLanguage> *supportedLanguages;

/// 是否开启应用内语言偏好设置。默认否。
/// @note 开启功能后，更改应用语言立即生效，新的页面将按照新的语言展示。
@property (class, nonatomic, setter=setInAppLanguagePreferencesEnabled:) BOOL isInAppLanguagePreferencesEnabled;

@end

@interface NSBundle (XZLocalization)
/// 获取指定语言的语言包。如果没有找到语言包，则返回自身。
/// - Parameter language: 语言
- (NSBundle *)xz_resourceBundleForLanguage:(XZAppLanguage)language NS_SWIFT_NAME(resourceBundle(for:));
@end

/// 识别字符串中的占位参数的格式。
typedef struct XZLocalizationPredicate {
    /// 开始字符
    char start;
    /// 结束字符。
    char end;
} XZLocalizationPredicate;

/// 构造占位分隔符。
/// - Parameters:
///   - start: 起始字符
///   - end: 终止字符
FOUNDATION_STATIC_INLINE XZLocalizationPredicate XZLocalizationPredicateMake(char start, char end) {
    return (XZLocalizationPredicate){ start, end };
}

/// 本地化字符串中，默认以大括号 `{}` 作为参数分隔符。
FOUNDATION_EXPORT XZLocalizationPredicate const XZLocalizationPredicateBraces;

@interface NSString (XZLocalization)
/// 替换字符串中被分隔符分割的占位符。
/// - Parameters:
///   - predicate: 分隔符
///   - transform: 获取占位符的替换内容的块函数
- (NSString *)xz_stringByReplacingMatchesOfPredicate:(XZLocalizationPredicate)predicate usingBlock:(id(^NS_NOESCAPE)(NSString *matchedString))transform;
/// 替换字符串中被分隔符分割的占位符。
/// - Parameters:
///   - predicate: 分隔符
///   - aDictionary: key 为占位符，value 为替换内容
- (NSString *)xz_stringByReplacingMatchesOfPredicate:(XZLocalizationPredicate)predicate usingDictionary:(NSDictionary<NSString *, id> *)aDictionary;
@end

@class NSArray;

#ifndef XZLocalizedString
#define _XZLocalizedStringOptimize(\
_00, _01, _02, _03, _04, _05, _06, _07, _08, _09, \
_10, _11, _12, _13, _14, _15, _16, _17, _18, _19, \
_20, _21, _22, _23, _24, _25, _26, _27, _28, _29, \
_30, _31, _32, _33, _34, _35, _36, _37, _38, _39, \
_40, _41, _42, _43, _44, _45, _46, _47, _48, _49, \
_50, _51, _52, _53, _54, _55, _56, _57, _58, _59, \
_60, _61, _62, _63, _64, _65, ...) _65

#define XZLocalizedString(stringToBeLocalized, ...) _XZLocalizedStringOptimize(64, ##__VA_ARGS__, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, NSLocalizedStringWithDefaultValue)(stringToBeLocalized, nil, NSBundle.mainBundle, @"", ##__VA_ARGS__, nil)

#define XZLocalizedStringFromTable(table, stringToBeLocalized, ...) _XZLocalizedStringOptimize(64, ##__VA_ARGS__, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, NSLocalizedStringWithDefaultValue)(stringToBeLocalized, table, NSBundle.mainBundle, @"", ##__VA_ARGS__, nil)

#define XZLocalizedStringFromTableInBundle(bundle, table, stringToBeLocalized, ...) _XZLocalizedStringOptimize(64, ##__VA_ARGS__, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, NSLocalizedStringWithDefaultValue)(stringToBeLocalized, table, bundle, @"", ##__VA_ARGS__, nil)

#define XZLocalizedStringWithDefaultValue(bundle, table, defaultValue, stringToBeLocalized, ...) _XZLocalizedStringOptimize(64, ##__VA_ARGS__, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, \
_XZLocalizedString, _XZLocalizedString, _XZLocalizedString, _XZLocalizedString, NSLocalizedStringWithDefaultValue)(stringToBeLocalized, table, bundle, defaultValue, ##__VA_ARGS__, nil)
#endif // <= #ifndef XZLocalizedString

/// 字符串本地化便利函数。请直接使用 `XZLocalizedString` 宏，而非此函数。
///
/// @discussion 支持在本地化字符串中，使用形如 {0}、{1}、{2} 的参数占位符，其中的数字表示参数的顺序，参数必须为对象。
///
/// @note not for direct use
///
/// @param stringToBeLocalized 需要本地化字符串
/// @param table 本地化字符串表
/// @param bundle 本地化字符串包
/// @param defaultValue 默认字符
/// @returns 已本地化的字符串
FOUNDATION_EXPORT NSString *_XZLocalizedString(NSString *stringToBeLocalized, NSString * _Nullable table, NSBundle *bundle, NSString *defaultValue, ...) NS_REQUIRES_NIL_TERMINATION;

NS_ASSUME_NONNULL_END
