//
//  TUThumborURL.m
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <objc/runtime.h>

#import "ThumborURL.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>


static inline NSString *TUFormattedStringFromRect(CGRect r);
static inline NSString *TUFormattedStringFromSize(CGSize size);
static inline NSData *TUCreateEncryptedAES128Data(NSString *imageURLString, NSString *optionsUrlPath, NSString *securityKey);
static inline NSData *TUCreateEncryptedHMACSHA1Data(NSString *imageURLString, NSString *securityKey);


@interface TUOptions ()

- (NSArray *)URLOptions;
- (NSString *)URLOptionsPath;

@end


@interface TUEndpointConfiguration ()

@property (nonatomic, strong, readwrite) NSCache *secureURLCache;

@end


@implementation TUEndpointConfiguration

- (id)initWithBaseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _baseURL = [baseURL copy];
    _globalSecurityKey = [securityKey copy];

    _secureURLCache = [[NSCache alloc] init];
    [_secureURLCache setEvictsObjectsWithDiscardedContent:NO];
    [_secureURLCache setCountLimit:NSIntegerMax];
        
    return self;
}

- (id)initWithBaseURL:(NSURL *)baseURL;
{
    return [self initWithBaseURL:baseURL securityKey:nil];
}


- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options;
{
    NSAssert(self.globalSecurityKey, @"globalSecurityKey required for calling %@", NSStringFromSelector( _cmd));
    return [self secureURLWithImageURL:imageURL options:options securityKey:self.globalSecurityKey];
}

- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options securityKey:(NSString *)securityKey;
{
    if (!imageURL.thumborizableURL) {
        return imageURL;
    }
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", imageURL.absoluteString, options.URLOptionsPath];
    NSURL *cachedURL = [self.secureURLCache objectForKey:cacheKey];
    if (cachedURL) {
        return cachedURL;
    }
        
    NSURL *secureURL = [NSURL TU_secureURLWithOptions:options imageURL:imageURL baseURL:self.baseURL securityKey:securityKey];
    if (secureURL) {
        [self.secureURLCache setObject:secureURL forKey:cacheKey];
        return secureURL;
    }
    
    return nil;
}

@end


@implementation TUFilter

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
{
    TUFilter *filter = [[[self class] alloc] init];
    filter.arguments = arguments;
    filter.name = name;
    return filter;
}

+ (id)filterWithName:(NSString *)name arguments:(id)firstArg, ...;
{
    NSMutableArray *argsAry = [NSMutableArray array];
    
    va_list args;
    va_start(args, firstArg);
    for (id arg = firstArg; arg != nil; arg = va_arg(args, id)) {
        [argsAry addObject:arg];
    }
    va_end(args);
    
    return [self filterWithName:name argumentsArray:argsAry];
}


@end


@implementation TUOptions

- (id)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _scale = 1.0f;
    
    return self;
}


+ (NSArray *)keysToCopy;
{
    static NSArray *keys = nil;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        keys = @[
            @"targetSize",
            @"smart",
            @"debug",
            @"meta", 
            @"crop", 
            @"fitIn",
            @"valign",
            @"halign", 
            @"filters",
            @"vflip",
            @"hflip",
            @"scale",
            @"encryption"
        ];
    });
    
    return keys;
}

- (id)copyWithZone:(NSZone *)zone;
{
    TUOptions *opt = [[TUOptions alloc] init];

    [opt setValuesForKeysWithDictionary:[self dictionaryWithValuesForKeys:[TUOptions keysToCopy]]];

    return opt;
}

- (NSArray *)URLOptions;
{
    NSMutableArray *params = [NSMutableArray array];
    
    if (_debug) {
        [params addObject:@"debug"];
    }

    if (_meta) {
        [params addObject:@"meta"];
    }

    if (!CGRectEqualToRect(_crop, CGRectZero)) {
        [params addObject:TUFormattedStringFromRect(_crop)];
    }

    switch (_fitIn) {
        case TUFitInAdaptive:
            [params addObject:@"adaptive-fit-in"];
            break;
            
        case TUFitInNormal:
            [params addObject:@"fit-in"];
            break;
            
        case TUFitInNone:
            // Do nothing.
            break;
    }

    CGSize size = _targetSize;
    size.width *= _scale;
    size.height *= _scale;

    if (_hflip) {
        size.width *= -1.0f;
    }
    if (_vflip) {
        size.height *= -1.0f;
    }

    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        [params addObject:TUFormattedStringFromSize(size)];
    }

    switch (_halign) {
        case TUHorizontalAlignLeft:
            [params addObject:@"left"];
            break;
            
        case TUHorizontalAlignRight:
            [params addObject:@"right"];
            break;
            
        case TUHorizontalAlignCenter:
            // Do nothing.
            break;
    }

    switch (_valign) {
        case TUVerticalAlignTop:
            [params addObject:@"top"];
            break;
            
        case TUVerticalAlignBottom:
            [params addObject:@"bottom"];
            break;
            
        case TUVerticalAlignMiddle:
            // Do nothing.
            break;
    }

    if (_smart) {
        [params addObject:@"smart"];
    }

    if (_filters.count) {
        NSMutableArray *filterStrings = [[NSMutableArray alloc] initWithCapacity:(_filters.count + 1)];
        [filterStrings addObject:@"filters"];

        for (TUFilter *filter in _filters) {
            NSString *str = [[NSString alloc] initWithFormat:@"%@(%@)", filter.name, [filter.arguments componentsJoinedByString:@","]];
            [filterStrings addObject:str];
        }

        [params addObject:[filterStrings componentsJoinedByString:@":"]];
    }

    return [params copy];
}

- (NSString *)URLOptionsPath;
{
    return [NSString pathWithComponents:self.URLOptions];
}

- (TUOptions *)optionsBySettingSize:(CGSize)newSize;
{
    TUOptions *newOptions = [self copy];
    newOptions.targetSize = newSize;
    return newOptions;
}

@end


@implementation NSURL (ThumborURL)

static NSString *const TUIsThumborizedURLKey = @"TUIsThumborizedURL";

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
{
    assert(securityKey.length > 0);

    // Remove the query from calculating the hash.
    NSString *imageURLString = imageURL.absoluteString;

    NSString *query = imageURL.query;
    if (query != nil) {
        imageURLString = [imageURLString substringToIndex:imageURLString.length - (query.length + 1)];
    }

    // Encrypt URL based declared encryption scheme.
    NSString *suffix = nil;
    NSData *result = nil;
    switch (options.encryption) {
        case TUEncryptionModeAES128:
            suffix = imageURLString;
            result = TUCreateEncryptedAES128Data(imageURLString, options.URLOptionsPath, securityKey);
            break;

        case TUEncryptionModeHMACSHA1:
        default: {
            // It is important not to generate the URL by using stringByAppendingPathComponent because the trimmedString is not
            // a filesystem path component. As such, http://lol gets turned into http:/lol by the API which 
            // Thumbor will then reject causing all images in our app which use Thumbor to stop loading :)
            NSString *trimmedString = [imageURLString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            NSString *optionsString = options.URLOptionsPath;
            
            if (optionsString.length) {
                suffix = [NSString stringWithFormat:@"%@/%@", optionsString, trimmedString];
            } else {
                suffix = trimmedString;
            }
            
            result = TUCreateEncryptedHMACSHA1Data(suffix, securityKey);
            break;
        }
    }

    // Base 64 encode the data. Replace invalid characters so the URL will be valid. Thumbor expects this replacement.
    NSMutableString *base64String = [result.base64Encoding mutableCopy];
    [base64String replaceOccurrencesOfString:@"+" withString:@"-"options:NSLiteralSearch range:NSMakeRange(0, base64String.length)];
    [base64String replaceOccurrencesOfString:@"/" withString:@"_"options:NSLiteralSearch range:NSMakeRange(0, base64String.length)];

    NSString *finalURL = [NSString stringWithFormat:@"/%@/%@", base64String, suffix];

    NSURL *URL = [NSURL URLWithString:finalURL relativeToURL:baseURL];

    objc_setAssociatedObject(URL, (__bridge void *)TUIsThumborizedURLKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return URL;
}

#pragma mark - Properties

- (BOOL)isThumborizableURL;
{
    static NSSet *thumborizableURLSchemes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thumborizableURLSchemes = [NSSet setWithObjects:
                                   @"http",
                                   @"https",
                                   nil
                                   ];
    });

    return [thumborizableURLSchemes containsObject:self.scheme.lowercaseString];
}

- (BOOL)isThumborizedURL;
{
    const NSNumber *isThumborizedURL = objc_getAssociatedObject(self, (__bridge void *)TUIsThumborizedURLKey);

    return isThumborizedURL.boolValue;
}

@end


static inline NSData *TUCreateEncryptedHMACSHA1Data(NSString *imageURLString, NSString *securityKey)
{
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:CC_SHA1_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA1,
           securityKey.UTF8String,    [securityKey    lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
           imageURLString.UTF8String, [imageURLString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
           buffer.mutableBytes);

    return buffer;
}

static inline NSData *TUCreateEncryptedAES128Data(NSString *imageURLString, NSString *optionsURLPath, NSString *securityKey)
{
    // MD5 the imageURLString.
    NSData *imageURLStringData = [imageURLString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *imageHash = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageURLStringData.bytes, (CC_LONG)imageURLStringData.length, imageHash.mutableBytes);

    NSString *imageHashString = [imageHash description];
    imageHashString = [imageHashString stringByReplacingOccurrencesOfString:@"[<> ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, imageHashString.length)];

    // The URL we want to encrypt is appended by the imageHashString.
    NSString *urlToEncrypt = [optionsURLPath stringByAppendingFormat:@"/%@", imageHashString];

    // Pad it to 16 bytes.
    size_t paddingNeeded = (16 - [urlToEncrypt lengthOfBytesUsingEncoding:NSUTF8StringEncoding] % 16);
    urlToEncrypt = [urlToEncrypt stringByPaddingToLength:urlToEncrypt.length + paddingNeeded withString:@"{" startingAtIndex:0];

    assert(urlToEncrypt.length % 16 == 0);

    // Now we have the URL we want to encrypt.
    NSData *dataToEncrypt = [urlToEncrypt dataUsingEncoding:NSUTF8StringEncoding];

    const size_t keySize = kCCKeySizeAES128;

    // Pad the key to 16 bytes.
    NSString *paddedSecurityKey = [securityKey stringByPaddingToLength:16 withString:securityKey startingAtIndex:0];
    NSData *key = [paddedSecurityKey dataUsingEncoding:NSUTF8StringEncoding];

    assert(paddedSecurityKey.length == keySize);
    assert(key.length == keySize);

    // Make the buffer twice the length.
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:2048];

    CCCryptorRef cryptor = NULL;
    size_t dataUsed = 0;
    CCCryptorStatus status = CCCryptorCreateFromData(kCCEncrypt,
                                                     kCCAlgorithmAES128,
                                                     kCCOptionECBMode,
                                                     key.bytes,
                                                     key.length,
                                                     NULL,
                                                     buffer.mutableBytes,
                                                     buffer.length,
                                                     &cryptor,
                                                     &dataUsed);

    assert(status == kCCSuccess);
    assert(cryptor);

    size_t bytesNeeded = CCCryptorGetOutputLength(cryptor, dataToEncrypt.length, YES);

    NSMutableData *result = [[NSMutableData alloc] initWithLength:bytesNeeded];

    size_t currentOffset = 0;
    size_t dataMoved = 0;
    status = CCCryptorUpdate(cryptor, dataToEncrypt.bytes, dataToEncrypt.length, result.mutableBytes, result.length, &dataMoved);
    assert(status == kCCSuccess);

    currentOffset += dataMoved;

    CCCryptorFinal(cryptor, result.mutableBytes + currentOffset, result.length - currentOffset, &dataMoved);

    currentOffset += dataMoved;
    assert(currentOffset == result.length);

    CCCryptorRelease(cryptor);
    cryptor = NULL;

    memset(buffer.mutableBytes, 0, buffer.length);
    
    return result;
}

static inline NSString *TUFormattedStringFromSize(CGSize size)
{
    return [NSString stringWithFormat:@"%@x%@", @(size.width), @(size.height)];
}

static inline NSString *TUFormattedStringFromRect(CGRect r)
{
    return [NSString stringWithFormat:@"%@x%@:%@x%@",
        @(r.origin.x),
        @(r.origin.y),
        @(r.origin.x + r.size.width),
        @(r.origin.y + r.size.height)
    ];
}
