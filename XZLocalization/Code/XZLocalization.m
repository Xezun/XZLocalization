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
/// 支持应用内语言偏好设置的类。
static Class _Nullable _inAppLanguageBundleClass = Nil;

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
    if (_inAppLanguageBundleClass == Nil) {
        return NO;
    }
    return _inAppLanguageBundleClass == NSBundle.mainBundle.class;
}

+ (void)setInAppLanguagePreferencesEnabled:(BOOL)isInAppLanguagePreferencesEnabled {
    NSAssert(NSThread.isMainThread, XZLocalizedString(@"方法 %s 只能在主线程调用。"),  __PRETTY_FUNCTION__);
    
    NSBundle * const mainBundle = NSBundle.mainBundle;
    
    // 以 mainBundle 的类作为超类，派生支持应用内语言偏好设置的子类。
    if (_inAppLanguageBundleClass == Nil) {
        _inAppLanguageBundleClass = xz_objc_createClass(mainBundle.class, ^(Class  _Nonnull __unsafe_unretained newClass) {
            SEL const method = @selector(localizedStringForKey:value:table:);
            xz_objc_class_addMethodWithBlock(newClass, method, nil, nil, ^NSString *(NSBundle *self, NSString *key, NSString *value, NSString *tableName) {
                XZAppLanguage const preferredLanguage = XZLocalization.preferredLanguage;
                NSBundle * const languageBundle = [XZLocalization resourceBundleForLanguage:preferredLanguage];
                if (languageBundle != nil) {
                    return [languageBundle localizedStringForKey:key value:value table:tableName];
                }
                struct objc_super super = {
                    .receiver = self,
                    .super_class = class_getSuperclass(object_getClass(self))
                };
                return ((NSString *(*)(struct objc_super *, SEL, NSString *, NSString *, NSString *))objc_msgSendSuper)(&super, method, key, value, tableName);
            }, nil);
        });
    }
    
    // 开启/关闭功能
    if (isInAppLanguagePreferencesEnabled) {
        if (![mainBundle.class isKindOfClass:_inAppLanguageBundleClass]) {
            object_setClass(mainBundle, _inAppLanguageBundleClass);
        }
    } else {
        while ([mainBundle isKindOfClass:_inAppLanguageBundleClass]) {
            object_setClass(mainBundle, mainBundle.superclass);
        }
    }
}

+ (NSBundle *)resourceBundleForLanguage:(XZAppLanguage)language {
    static NSMutableDictionary<NSString *, id> *_languageBundles = nil;
    
    NSBundle *resourceBundle = _languageBundles[language];
    if (resourceBundle != nil) {
        return ((id)resourceBundle == NSNull.null) ? nil : resourceBundle;
    }
    
    NSString *path = [NSBundle.mainBundle pathForResource:language ofType:@"lproj"];
    resourceBundle = [NSBundle bundleWithPath:path];
    
    if (_languageBundles == nil) {
        _languageBundles = [NSMutableDictionary dictionary];
    }
    _languageBundles[language] = resourceBundle ?: [NSNull null];
    
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
