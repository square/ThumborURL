//
//  TUThumborURL.m
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Mike Lewis. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.


#import "ThumborURL.h"
#import "base64urlsafe.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


@implementation TUFilter

@synthesize name = _name;
@synthesize arguments = _arguments;

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
{
    TUFilter *f = [[[self class] alloc] init];
    f.arguments = arguments;
    f.name = name;
    return f;
}
+ (id)filterWithName:(NSString *)name arguments:(id)firstArg, ...;
{
    NSMutableArray *argsAry = [[NSMutableArray alloc] init];
    
    va_list args;
    va_start(args, firstArg);
    for (id arg = firstArg; arg != nil; arg = va_arg(args, id))
    {
        [argsAry addObject:arg];
    }
    va_end(args);
    
    return [self filterWithName:name argumentsArray:argsAry];
}

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

+ (NSArray *)keysToCopy;
{
    static NSArray *keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [[NSArray alloc] initWithObjects:@"targetSize", @"smart", @"debug", @"meta", @"crop", @"fitIn", @"valign", @"halign", @"filters", @"vflip", @"hflip", nil];
    });
    return keys;
}

- (id)copyWithZone:(NSZone *)zone;
{
    TUOptions *opt = [[TUOptions alloc] init];

    [opt setValuesForKeysWithDictionary:[self dictionaryWithValuesForKeys:[TUOptions keysToCopy]]];

    return opt;
}

static inline NSString *formatSize(CGSize size) {
    return [[NSString alloc] initWithFormat:@"%dx%d", (NSInteger)size.width, (NSInteger)size.height];
}

static inline NSString *formatRect(CGRect r) {

    return [[NSString alloc] initWithFormat:@"%dx%d:%dx%d",
                                            (NSInteger)r.origin.x,
                                            (NSInteger)r.origin.y,
                                            (NSInteger)(r.origin.x + r.size.width),
                                            (NSInteger)(r.origin.y + r.size.height)
    ];
}

- (NSArray *)options;
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

    if (_vflip) {
        size.width *= -1;
    }

    if (_hflip) {
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
        }

        [params addObject:[filterStrings componentsJoinedByString:@":"]];
    }

    return [params copy];
}

- (NSString *)optionsPath;
{
    return [NSString pathWithComponents:self.options];
}


@end

@implementation NSURL (ThumborURL)

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
{
    assert(securityKey.length > 0);
    
    NSString *imageURLString = imageURL.absoluteString;
    
    // MD5 the imageURLString
    NSData *imageURLStringData = [imageURLString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *imageHash = [[NSMutableData alloc] initWithLength:CC_MD5_DIGEST_LENGTH];
    CC_MD5(imageURLStringData.bytes, imageURLStringData.length, imageHash.mutableBytes);
    
    NSString *imageHashString = [imageHash description];
    imageHashString = [imageHashString stringByReplacingOccurrencesOfString:@"[<> ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, imageHashString.length)];

    // The URL we want to encrypt is appended by the imageHashString
    NSString *urlToEncrypt = [options.optionsPath stringByAppendingFormat:@"/%@", imageHashString];

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
    CCCryptorStatus  status = CCCryptorCreateFromData(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, key.bytes,
                                                      key.length, NULL, buffer.mutableBytes, buffer.length,
                                                      &cryptor, NULL);

    assert(status == kCCSuccess);
    assert(cryptor);

    size_t bytesNeeded = CCCryptorGetOutputLength(cryptor, dataToEncrypt.length, YES);

    NSMutableData *result = [[NSMutableData alloc] initWithLength:bytesNeeded];

    size_t currentOffset = 0;
    size_t dataMoved = 0;
    status = CCCryptorUpdate(cryptor, dataToEncrypt.bytes, dataToEncrypt.length,
                  result.mutableBytes, result.length, &dataMoved);
    
    assert(status == kCCSuccess);

    currentOffset += dataMoved;

    CCCryptorFinal(cryptor, result.mutableBytes + currentOffset, result.length - currentOffset,
                   &dataMoved);

    currentOffset += dataMoved;
    assert(currentOffset == result.length);

    CCCryptorRelease(cryptor);
    cryptor = NULL;
    
    memset(buffer.mutableBytes, 0, buffer.length);
    
    // Now we're finished encrypting the url, let's Base64 encode it
    
    NSMutableData *secureURL = [[NSMutableData alloc] initWithLength:((result.length + 2) * 3 / 2)];
    
    size_t newLen = b64_ntop_urlsafe(result.bytes, result.length, secureURL.mutableBytes, secureURL.length);
    secureURL.length = newLen;
    
    NSString *encodedString = [[NSString alloc] initWithData:secureURL encoding:NSUTF8StringEncoding];
    
    // Append the image URL to it

    NSString *finalURL = [[NSString alloc] initWithFormat:@"/%@/%@", encodedString, imageURLString];
    
    // Make it relative to the base URL    
    return [[NSURL alloc] initWithString:finalURL relativeToURL:baseURL];
}

@end
