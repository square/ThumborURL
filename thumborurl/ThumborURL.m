//
//  TUThumborURL.m
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Square, Inc. All rights reserved.
//

#import "ThumborURL.h"
#import "base64urlsafe.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

static inline NSString *formatRect(CGRect r);
static inline NSString *formatSize(CGSize size);


@implementation TUEndpointConfiguration

@synthesize baseURL = _baseURL;
@synthesize globalSecurityKey = _globalSecurityKey;

- (id)initWithBaseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.baseURL = baseURL;
    self.globalSecurityKey = securityKey;

    return self;
}

- (id)initWithBaseURL:(NSURL *)baseURL;
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.baseURL = baseURL;

    return self;
}

- (void)dealloc;
{
    [_baseURL release]; _baseURL = nil;
    [_globalSecurityKey release]; _globalSecurityKey = nil;
    
    [super dealloc];
}

- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options;
{
    NSAssert(self.globalSecurityKey, @"globalSecurityKey required for calling %@", NSStringFromSelector( _cmd));
    return [self secureURLWithImageURL:imageURL options:options securityKey:self.globalSecurityKey];
}

- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options securityKey:(NSString *)securityKey;
{
    return [NSURL TU_secureURLWithOptions:options imageURL:imageURL baseURL:self.baseURL securityKey:securityKey];
}

@end


@implementation TUFilter

@synthesize name = _name;
@synthesize arguments = _arguments;

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
{
    TUFilter *f = [[[self class] alloc] init];
    f.arguments = arguments;
    f.name = name;
    return [f autorelease];
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

- (void)dealloc;
{
    [_name release]; _name = nil;
    [_arguments release]; _arguments = nil;
    
    [super dealloc];
}

@end


@interface TUOptions ()

- (NSArray *)URLOptions;
- (NSString *)URLOptionsPath;

@end


@implementation TUOptions

@synthesize targetSize = _targetSize;
@synthesize smart = _smart;
@synthesize debug = _debug;
@synthesize meta = _meta;
@synthesize crop = _crop;
@synthesize fitIn = _fitIn;
@synthesize valign = _valign;
@synthesize halign = _halign;
@synthesize filters = _filters;
@synthesize vflip = _vflip;
@synthesize hflip = _hflip;
@synthesize scale = _scale;

- (id)init;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _scale = 1.0f;
    
    return self;
}

- (void)dealloc;
{
    [_filters release]; _filters = nil;
    
    [super dealloc];
}

+ (NSArray *)keysToCopy;
{
    static NSArray *keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [[NSArray alloc] initWithObjects:
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
                nil];
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
    NSMutableArray *params = [[NSMutableArray alloc] init];
    
    if (_debug) {
        [params addObject:@"debug"];
    }

    if (_meta) {
        [params addObject:@"meta"];
    }

    if (!CGRectEqualToRect(_crop, CGRectZero)) {
        [params addObject:formatRect(_crop)];
    }

    switch (_fitIn) {
        case TUFitInAdaptive:
            [params addObject:@"adaptive-fit-in"];
            break;
        case TUFitInNormal:
            [params addObject:@"fit-in"];
            break;
        case TUFitInNone:
            // Do nothing
            break;
    }

    CGSize size = _targetSize;
    
    size.width *= _scale;
    size.height *= _scale;

    if (_hflip) {
        size.width *= -1;
    }

    if (_vflip) {
        size.height *= -1;
    }

    if (!CGSizeEqualToSize(size, CGSizeZero)) {
        [params addObject:formatSize(size)];
    }

    switch (_halign) {
        case TUHorizontalAlignLeft:
            [params addObject:@"left"];
            break;
        case TUHorizontalAlignRight:
            [params addObject:@"right"];
            break;
        case TUHorizontalAlignCenter:
            // Do nothing
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
            // Do nothing
            break;
    }

    if (_smart) {
        [params addObject:@"smart"];
    }

    if (_filters.count) {
        NSMutableArray *filterStrings = [[NSMutableArray alloc] initWithCapacity:_filters.count + 1];
        [filterStrings addObject:@"filters"];

        for (TUFilter *f in _filters) {
            NSString *str = [[NSString alloc] initWithFormat:@"%s(%s)", f.name, [f.arguments componentsJoinedByString:@","]];
            [filterStrings addObject:str];
            [str release];
        }

        [params addObject:[filterStrings componentsJoinedByString:@":"]];
        [filterStrings release];
    }

    return [[params copy] autorelease];
}

- (NSString *)URLOptionsPath;
{
    return [NSString pathWithComponents:self.URLOptions];
}

- (TUOptions *)optionsWithSize:(CGSize)newSize;
{
    TUOptions *newOptions = [self copy];
    newOptions.targetSize = newSize;
    return [newOptions autorelease];
}

@end


@implementation NSURL (ThumborURL)

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
{
    assert(securityKey.length > 0);

    // Remove the query from calculating the hash
    NSString *imageURLString = imageURL.absoluteString;

    NSString *query = imageURL.query;
    if (query != nil) {
        imageURLString = [imageURLString substringToIndex:imageURLString.length - (query.length + 1)];
    }

    // MD5 the imageURLString
    NSData *imageURLStringData = [imageURLString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *imageHash = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageURLStringData.bytes, imageURLStringData.length, imageHash.mutableBytes);
    
    NSString *imageHashString = [imageHash description];
    imageHashString = [imageHashString stringByReplacingOccurrencesOfString:@"[<> ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, imageHashString.length)];

    // The URL we want to encrypt is appended by the imageHashString
    NSString *urlToEncrypt = [options.URLOptionsPath stringByAppendingFormat:@"/%@", imageHashString];

    // Pad it to 16 bytes
    size_t paddingNeeded = (16 - [urlToEncrypt lengthOfBytesUsingEncoding:NSUTF8StringEncoding] % 16);
    urlToEncrypt = [urlToEncrypt stringByPaddingToLength:urlToEncrypt.length + paddingNeeded withString:@"{" startingAtIndex:0];
    
    assert(urlToEncrypt.length % 16 == 0);
    
    // Now we have the URL we want to encrypt
    NSData *dataToEncrypt = [urlToEncrypt dataUsingEncoding:NSUTF8StringEncoding];
    
    const size_t keySize = kCCKeySizeAES128;
    
    // Pad the key to 16 bytes
    securityKey = [securityKey stringByPaddingToLength:16 withString:securityKey startingAtIndex:0];
    NSData *key = [securityKey dataUsingEncoding:NSUTF8StringEncoding];
    
    assert(securityKey.length == keySize);
    assert(key.length == keySize);

    // Make the buffer twice the length
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:2048];

    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = CCCryptorCreateFromData(kCCEncrypt, 
                                                      kCCAlgorithmAES128,
                                                      kCCOptionECBMode,
                                                      key.bytes,
                                                      key.length,
                                                      NULL,
                                                      buffer.mutableBytes,
                                                      buffer.length,
                                                      &cryptor,
                                                      NULL);

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
    [buffer release];
    
    // Now we're finished encrypting the url, let's Base64 encode it
    NSMutableData *secureURL = [NSMutableData dataWithLength:((result.length + 2) * 3 / 2)];
    size_t newLen = b64_ntop_urlsafe(result.bytes, result.length, secureURL.mutableBytes, secureURL.length);
    secureURL.length = newLen;
    [result release];
    
    // Append the image URL to it
    NSString *encodedString = [[NSString alloc] initWithData:secureURL encoding:NSUTF8StringEncoding];
    NSString *finalURL = [NSString stringWithFormat:@"/%@/%@", encodedString, imageURLString];
    [encodedString release];
    
    // Make it relative to the base URL    
    return [NSURL URLWithString:finalURL relativeToURL:baseURL];
}

@end


static inline NSString *formatSize(CGSize size) {
    return [NSString stringWithFormat:@"%dx%d", (NSInteger)size.width, (NSInteger)size.height];
}

static inline NSString *formatRect(CGRect r) {
    return [NSString stringWithFormat:@"%dx%d:%dx%d",
            (NSInteger)r.origin.x,
            (NSInteger)r.origin.y,
            (NSInteger)(r.origin.x + r.size.width),
            (NSInteger)(r.origin.y + r.size.height)
    ];
}

