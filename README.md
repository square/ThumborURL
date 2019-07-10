# ThumborURL
[![CI Status](https://api.travis-ci.org/square/ThumborURL.svg?branch=master)](https://travis-ci.org/square/ThumborURL)

A library to generate encrypted URLs for [Thumbor](https://github.com/thumbor/thumbor) in your iOS app.

## Features

* Encrypts and signs Thumbor URLs
* Sets image manipulation options
	* Resize
	* Crop
	* Filters
	* Scale
	* Flipping
	* Detection
	* Trim
* Performs quickly

## Installation

### Cocoapods

1. Add `pod ThumborURL` to your Podfile.
1. `pod install`
1. `import ThumborURL` (Swift) or `@import ThumborURL;` (Objective-C).

### Manually

1. Add `https://github.com/square/ThumborURL.git` as a submodule of your project.
1. Add `thumborurl.xcodeproj` as a subproject of your Xcode project.
1. Make the `thumborurl` library a dependency of your target.
1. Link the `thumborurl` library to your target.
1. `#import <thumborurl/ThumborURL.h>`

## Usage

### Swift

```swift
let imageURL = URL(string: "twitter.com/foo.png")!
let baseURL = URL(string: "http://images.example.com")!
let securityKey = "omg152"

let options = TUOptions()
options.crop = CGRect(x: 10, y: 10, width: 10, height: 10)
options.smart = true
options.targetSize = CGSize(width: 10, height: 10)
options.fitIn = .normal
options.vflip = true
options.filters = [
    TUFilter(name: "watermark", argumentsArray: ["blah.png", "10", "20", "30"]),
    TUFilter(name: "watermark", argumentsArray: ["baz.png", "4", "8", "5"])
]

let thumborImageURL = NSURL.tu_secureURL(with: options, imageURL: imageURL, baseURL: baseURL, securityKey: securityKey)

// thumborImageURL = "http://images.example.com/9sG5VMXh7HoCgPlNH8AZx42y4fc=/10x10:20x20/fit-in/10x-10/smart/filters:watermark(blah.png,10,20,30):watermark(baz.png,4,8,5)/twitter.com/foo.png"
```

### Objective-C

```objective-c
TUOptions *opts = [[TUOptions alloc] init];

NSURL *imageURL = [NSURL URLWithString:@"twitter.com/foo.png"];
NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
NSString *key = @"omg152";

opts.crop = CGRectMake(20, 20, 20, 20);
opts.smart = YES;
opts.targetSize = CGSizeMake(10, 10);
opts.fitIn = TUFitInNormal;
opts.vflip = YES;
opts.filters = @[[TUFilter filterWithName:@"watermark" arguments:@"blah.png", @"10", @"20", @"30", nil],
                 [TUFilter filterWithName:@"watermark" arguments:@"baz.png", @"4", @"8", @"15", nil]];

NSURL *thumborImageURL = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
// thumborImageURL is http://images.example.com/9sG5VMXh7HoCgPlNH8AZx42y4fc=/10x10:20x20/fit-in/10x-10/smart/filters:watermark(blah.png,10,20,30):watermark(baz.png,4,8,5)/twitter.com/foo.png
```
