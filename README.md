# ThumborURL

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
* Performs quickly

## Usage

1. Add `https://github.com/square/ThumborURL.git` as a submodule of your project
1. Add `thumborurl.xcodeproj` as a subproject of your Xcode project.
1. Make the `thumborurl` library a dependency of your target.
1. Link the `thumborurl` library to your target.
1. `#import <thumborurl/ThumborURL.h>`

## Examples

    TUOptions *opts = [[TUOptions alloc] init];

    NSURL *imageURL = [NSURL URLWithString:@"twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";

    opts.crop = CGRectMake(20, 20, 20, 20);
    opts.smart = YES;
    opts.targetSize = CGSizeMake(10, 10);
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;

    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    // u is http://images.example.com/aOH7-AuI2kyIb4d9TLbcBdDlGwk=/20x20:40x40/fit-in/10x-10/smart/twitter.com/foo.png
