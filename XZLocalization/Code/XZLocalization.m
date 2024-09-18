//
//  XZLocalization.m
//  XZLocalization
//
//  Created by 徐臻 on 2024/9/15.
//

#import "XZLocalization.h"
#import <XZDefines/XZRuntime.h>
@import ObjectiveC;

XZLocalizationPredicate const XZLocalizationPredicateBraces   = { '{', '}' };
XZAppLanguage           const XZAppLanguageChinese            = @"zh-Hans";
XZAppLanguage           const XZAppLanguageChineseTraditional = @"zh-Hant";
XZAppLanguage           const XZAppLanguageEnglish            = @"en";
NSNotificationName      const XZAppLanguagePreferencesDidChangeNotification = @"XZAppLanguagePreferencesDidChangeNotification";

/// 语言偏好设置在 NSUserDefaults 中的键名。
static NSString * const AppleLanguages = @"AppleLanguages";
/// 记录了当前的语言偏好设置。
static XZAppLanguage _Nullable _preferredLanguage = nil;
/// 是否开启应用内切换语言功能。
static BOOL _isInAppLanguagePreferencesEnabled    = NO;
/// 是否支持应用内切换语言功能。
static BOOL _isInAppLanguagePreferencesSupported  = NO;

@implementation XZLocalization

+ (XZAppLanguage)preferredLanguage {
    if (_preferredLanguage != nil) {
        return _preferredLanguage;
    }
    NSArray<XZAppLanguage> * const preferredLanguages = NSBundle.mainBundle.preferredLocalizations;
    if ([preferredLanguages isKindOfClass:[NSArray class]] && preferredLanguages.count > 0) {
        _preferredLanguage = preferredLanguages[0];
    } else {
        _preferredLanguage = NSBundle.mainBundle.localizations.firstObject ?: @"en";
    }
    return _preferredLanguage;
}

+ (void)setPreferredLanguage:(XZAppLanguage)newValue {
    // 参数校验
    if (newValue == nil || newValue.length == 0) {
        return;
    }
    
    // 新旧值比较
    if ([_preferredLanguage isEqualToString:newValue]) {
        return;
    }
    
    // 判断是否支持目标语言
    if (![self.supportedLanguages containsObject:newValue]) {
        NSLog(@"%@", XZLocalizedString(@"语言设置失败，不支持 {0} 语言。", newValue));
        return;
    }
    
    // 如果没有开启应用内语言设置，不保存值。
    if (self.isInAppLanguagePreferencesEnabled) {
        _preferredLanguage = newValue.copy;
        [NSNotificationCenter.defaultCenter postNotificationName:XZAppLanguagePreferencesDidChangeNotification object:self];
    }
    
    // 更新语言偏好设置
    NSArray<XZAppLanguage> *preferredLanguages = [NSUserDefaults.standardUserDefaults stringArrayForKey:AppleLanguages];
    if (preferredLanguages.count > 0) {
        NSInteger index = [preferredLanguages indexOfObject:newValue];
        if (index == 0) {
            return;
        }
        NSMutableArray * const newPreferences = [NSMutableArray arrayWithArray:preferredLanguages];
        if (index != NSNotFound) {
            [newPreferences removeObjectAtIndex:index];
        }
        [newPreferences insertObject:newValue atIndex:0];
        preferredLanguages = newPreferences;
    } else {
        preferredLanguages = @[newValue];
    }
    [NSUserDefaults.standardUserDefaults setObject:preferredLanguages forKey:AppleLanguages];
}

+ (NSLocaleLanguageDirection)languageDirectionForLanguage:(XZAppLanguage)language {
    NSString *identifier = [NSLocale canonicalLanguageIdentifierFromString:language];
    return [NSLocale characterDirectionForLanguage:identifier];
}

+ (NSArray<XZAppLanguage> *)supportedLanguages {
    return NSBundle.mainBundle.localizations;
}

+ (BOOL)isInAppLanguagePreferencesEnabled {
    return _isInAppLanguagePreferencesEnabled;
}

+ (void)setInAppLanguagePreferencesEnabled:(BOOL)isInAppLanguagePreferencesEnabled {
    NSAssert(NSThread.isMainThread, XZLocalizedString(@"方法 %s 只能在主线程调用。"),  __PRETTY_FUNCTION__);
    [self setInAppLanguagePreferencesSupported];
    _isInAppLanguagePreferencesEnabled = isInAppLanguagePreferencesEnabled;
}

+ (void)setInAppLanguagePreferencesSupported {
    if (_isInAppLanguagePreferencesSupported) {
        return;
    }
    _isInAppLanguagePreferencesSupported = YES;
    
    SEL const method = @selector(localizedStringForKey:value:table:);
    xz_objc_class_addMethodWithBlock(NSBundle.class, method, nil, nil, nil, ^id _Nonnull(SEL  _Nonnull selector) {
        return ^NSString *(NSBundle *self, NSString *key, NSString *value, NSString *tableName) {
            if (_isInAppLanguagePreferencesEnabled) {
                // 开启状态下，NSBundle 查找本地化字符串，先查找语言包
                XZAppLanguage const preferredLanguage = XZLocalization.preferredLanguage;
                NSBundle *    const languageBundle    = [self xz_resourceBundleForLanguage:preferredLanguage];
                // 这里已经是语言包，直接向原始实现发送消息
                return ((NSString *(*)(NSBundle *, SEL, NSString *, NSString *, NSString *))objc_msgSend)(languageBundle, selector, key, value, tableName);
            }
            return ((NSString *(*)(NSBundle *, SEL, NSString *, NSString *, NSString *))objc_msgSend)(self, selector, key, value, tableName);
        };
    });
}

@end

@implementation NSBundle (XZLocalization)

- (NSBundle *)xz_resourceBundleForLanguage:(XZAppLanguage)language {
    static const void * const _languageBundles = &_languageBundles;
    NSMutableDictionary<NSString *, id> *languageBundles = objc_getAssociatedObject(self, _languageBundles);
    
    // 查找缓存
    NSBundle *resourceBundle = languageBundles[language];
    if (resourceBundle != nil) {
        return ((id)resourceBundle == NSNull.null) ? self : resourceBundle;
    }
    
    // 建立缓存
    if (languageBundles == nil) {
        languageBundles = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _languageBundles, languageBundles, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    // 查找语言包，找不到返回自身，使用 NSNull 标记已经找过了。
    if ([self.bundleURL.lastPathComponent hasSuffix:@".lproj"]) {
        // 自身就是语言包
        languageBundles[language] = NSNull.null;
        resourceBundle = self;
    } else {
        NSString *path = [self pathForResource:language ofType:@"lproj"];
        if (path != nil) {
            resourceBundle = [NSBundle bundleWithPath:path];
        }
        if (resourceBundle != nil) {
            languageBundles[language] = resourceBundle;
        } else {
            languageBundles[language] = NSNull.null;
            resourceBundle = self;
        }
    }
    
    return resourceBundle;
}

@end

@implementation NSString (XZLocalization)

- (NSString *)xz_stringByReplacingMatchesOfPredicate:(XZLocalizationPredicate)predicate usingBlock:(id  _Nonnull (^NS_NOESCAPE)(NSString * _Nonnull))transform {
    NSRange range = NSMakeRange(0, self.length);
    NSStringEnumerationOptions options = NSStringEnumerationByComposedCharacterSequences;
    
    NSMutableString *result = [NSMutableString string];
    NSMutableString *search = [NSMutableString string];
    BOOL __block isMatching = NO;
    [self enumerateSubstringsInRange:range options:options usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (substringRange.length == 0) {
            return;
        }
        
        // 判断标记符号
        if (substringRange.length == 1) {
            // 标记符只能是单字节字符
            unichar const character = [substring characterAtIndex:0];
            if (character <= CHAR_MAX) {
                // 结束字符
                if (character == predicate.end) {
                    if (isMatching) {
                        isMatching = NO;
                        [result appendFormat:@"%@", transform(search)];
                        [search setString:@""];
                    } else {
                        [result appendString:substring];
                    }
                    return;
                }
                // 开始字符
                if (character == predicate.start) {
                    if (isMatching) {
                        // 已经处于识别模式，放弃当前识别的内容，重新开始识别
                        [result appendString:substring];
                        [result appendString:search];
                        [search setString:@""];
                    } else {
                        isMatching = YES;
                    }
                    return;
                }
            }
        }
        
        // 非标记符号
        if (isMatching) {
            [search appendString:substring];
        } else {
            [result appendString:substring];
        }
    }];
    
    if (isMatching) {
        [result appendFormat:@"%c", predicate.start];
        [result appendString:search];
    }
    return result;
}

- (NSString *)xz_stringByReplacingMatchesOfPredicate:(XZLocalizationPredicate)predicate usingDictionary:(NSDictionary<NSString *,id> *)aDictionary {
    return [self xz_stringByReplacingMatchesOfPredicate:predicate usingBlock:^NSString * _Nonnull(NSString * _Nonnull string) {
        id const value = aDictionary[string];
        return value ?: [NSString stringWithFormat:@"%c%@%c", predicate.start, string, predicate.end];
    }];
}

@end


NSString *_XZLocalizedString(NSString *stringToBeLocalized, NSString *table, NSBundle *bundle, NSString *defaultValue, ...) {
    NSMutableDictionary<NSString *, id> *arguments = nil;
    va_list args;
    va_start(args, defaultValue);
    id value = nil;
    while ((value = va_arg(args, id))) {
        if (arguments == nil) {
            arguments = [NSMutableDictionary dictionary];
        }
        NSString *key = [NSString stringWithFormat:@"%ld", (long)arguments.count];
        arguments[key] = value;
    }
    va_end(args);
    
    stringToBeLocalized = NSLocalizedStringWithDefaultValue(stringToBeLocalized, table, bundle, defaultValue, @"加载本地化字符串");
    if (arguments == nil) {
        return stringToBeLocalized;
    }
    return [stringToBeLocalized xz_stringByReplacingMatchesOfPredicate:XZLocalizationPredicateBraces usingDictionary:arguments];
}
