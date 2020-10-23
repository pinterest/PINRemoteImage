# Changelog

## [3.0.3](https://github.com/Pinterest/PINRemoteImage/tree/3.0.3) (2020-10-23)

[Full Changelog](https://github.com/Pinterest/PINRemoteImage/compare/3.0.2...3.0.3)


- Fixes macOS build on newer versions of Xcode [\#581](https://github.com/pinterest/PINRemoteImage/pull/581) ([garrettmoon](https://github.com/garrettmoon))

## [3.0.2](https://github.com/Pinterest/PINRemoteImage/tree/3.0.2) (2020-10-22)

[Full Changelog](https://github.com/Pinterest/PINRemoteImage/compare/3.0.1...3.0.2)


- Add support for automated releases [\#580](https://github.com/pinterest/PINRemoteImage/pull/580) ([garrettmoon](https://github.com/garrettmoon))
- Fix imports for non-SPM [\#579](https://github.com/pinterest/PINRemoteImage/pull/579) ([garrettmoon](https://github.com/garrettmoon))
- Moves to an .xcworkspace so we don't imbed subprojects [\#575](https://github.com/pinterest/PINRemoteImage/pull/575) ([garrettmoon](https://github.com/garrettmoon))
- SPM define [\#574](https://github.com/pinterest/PINRemoteImage/pull/574) ([3a4oT](https://github.com/3a4oT))
- SPM - Objective-C++ consumers fix [\#573](https://github.com/pinterest/PINRemoteImage/pull/573) ([3a4oT](https://github.com/3a4oT))
- Use proper units when setting preferredFramesPerSecond [\#572](https://github.com/pinterest/PINRemoteImage/pull/572) ([bdolman](https://github.com/bdolman))
- SPM support [\#571](https://github.com/pinterest/PINRemoteImage/pull/571) ([3a4oT](https://github.com/3a4oT))
- fix: build error when using multiproject config [\#569](https://github.com/pinterest/PINRemoteImage/pull/569) ([hendych](https://github.com/hendych))
- Integrated UIGraphicsImageRenderer for iOS/tvOS 10.0 and above [\#549](https://github.com/pinterest/PINRemoteImage/pull/549) ([IHEARTCOOKIES](https://github.com/IHEARTCOOKIES))
## [3.0.1](https://github.com/Pinterest/PINRemoteImage/tree/3.0.1) (2020-09-08)

[Full Changelog](https://github.com/Pinterest/PINRemoteImage/compare/3.0.0...3.0.1)

**Merged pull requests:**

- Update PINCache in podspec [\#564](https://github.com/pinterest/PINRemoteImage/pull/564) ([garrettmoon](https://github.com/garrettmoon))
- Update PINCache and PINOperation [\#562](https://github.com/pinterest/PINRemoteImage/pull/562) ([garrettmoon](https://github.com/garrettmoon))
- Let's use the same commands we use locally. [\#561](https://github.com/pinterest/PINRemoteImage/pull/561) ([garrettmoon](https://github.com/garrettmoon))
- Ensure the example defines the macros before referencing them. [\#557](https://github.com/pinterest/PINRemoteImage/pull/557) ([bolsinga](https://github.com/bolsinga))
- Remove the PCH file and ensure macros are defined before using [\#556](https://github.com/pinterest/PINRemoteImage/pull/556) ([bolsinga](https://github.com/bolsinga))
- Seems that having the framework and example have the same name confuses cocoapods [\#555](https://github.com/pinterest/PINRemoteImage/pull/555) ([garrettmoon](https://github.com/garrettmoon))
- Upgrade WebP to 1.1.0 [\#554](https://github.com/pinterest/PINRemoteImage/pull/554) ([garrettmoon](https://github.com/garrettmoon))
- Conditionally call CADisplayLink method based upon iOS10 availability to remove deprecation warning [\#552](https://github.com/pinterest/PINRemoteImage/pull/552) ([bolsinga](https://github.com/bolsinga))
- Fix typos [\#548](https://github.com/pinterest/PINRemoteImage/pull/548) ([pgrimaud](https://github.com/pgrimaud))
- Remove unused CI directory [\#547](https://github.com/pinterest/PINRemoteImage/pull/547) ([jparise](https://github.com/jparise))
- PINCachedAnimatedImage: Fix retain cycles [\#546](https://github.com/pinterest/PINRemoteImage/pull/546) ([bolsinga](https://github.com/bolsinga))
- Fix up analyze for new github CI [\#545](https://github.com/pinterest/PINRemoteImage/pull/545) ([garrettmoon](https://github.com/garrettmoon))
- Switch to GitHub Actions for CI [\#544](https://github.com/pinterest/PINRemoteImage/pull/544) ([jparise](https://github.com/jparise))
- \#trivial Fix performance issue caused by saving encoded image data to memory cache [\#539](https://github.com/pinterest/PINRemoteImage/pull/539) ([Naituw](https://github.com/Naituw))
- Update 3.0.0 change log and podspec [\#537](https://github.com/pinterest/PINRemoteImage/pull/537) ([ernestmama](https://github.com/ernestmama))
- Fix memory cache content in README [\#530](https://github.com/pinterest/PINRemoteImage/pull/530) ([OhKanghoon](https://github.com/OhKanghoon))
-  Refactor remote manager task for uuid method [\#526](https://github.com/pinterest/PINRemoteImage/pull/526) ([zhongwuzw](https://github.com/zhongwuzw))
- Burst Animated Image speed of frame index search [\#523](https://github.com/pinterest/PINRemoteImage/pull/523) ([zhongwuzw](https://github.com/zhongwuzw))
- Set HTTPMaximumConnectionsPerHost to PINRemoteImageHTTPMaximumConnectionsPerHost only if user don't provide sessionConfiguration [\#516](https://github.com/pinterest/PINRemoteImage/pull/516) ([zhongwuzw](https://github.com/zhongwuzw))
- Fixes re-downloading data corrupt for the same url [\#514](https://github.com/pinterest/PINRemoteImage/pull/514) ([zhongwuzw](https://github.com/zhongwuzw))

## 3.0.0 -- 2020 Jan 06
- [new] Add PINRemoteImageManagerConfiguration configuration object. [#492](https://github.com/pinterest/PINRemoteImage/pull/492) [rqueue](https://github.com/rqueue)
- [fixed] Fixes blending in animated WebP images. [#507](https://github.com/pinterest/PINRemoteImage/pull/507) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes support in PINAnimatedImageView for WebP animated images. [#507](https://github.com/pinterest/PINRemoteImage/pull/507) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes re-downloading data corrupt for the same url. [#514](https://github.com/pinterest/PINRemoteImage/pull/514) [zhongwuzw](https://github.com/zhongwuzw)
- [new] Exposure didCompleteTask:withError: delegate method of protocol PINURLSessionManagerDelegate. [#519](https://github.com/pinterest/PINRemoteImage/pull/519) [zhongwuzw](https://github.com/zhongwuzw)
- [fixed] Fixes AnimatedImageView designated initializer not work. [#512](https://github.com/pinterest/PINRemoteImage/pull/512) [zhongwuzw](https://github.com/zhongwuzw)
- [fixed] Set bpp(bits per pixel) to 32 bit for GIF. [#511](https://github.com/pinterest/PINRemoteImage/pull/511) [zhongwuzw](https://github.com/zhongwuzw)
- [new] Add cancel method for PINRemoteImageManager. [#509](https://github.com/pinterest/PINRemoteImage/pull/509) [zhongwuzw](https://github.com/zhongwuzw)
- [fixed] Fixes build error when using Xcode 10.2.1. [#524](https://github.com/pinterest/PINRemoteImage/pull/524) [ANNotunzdY](https://github.com/ANNotunzdY)

## 3.0.0 Beta 14
- [fixed] Re-enable warnings check [#506](https://github.com/pinterest/PINRemoteImage/pull/506) [garrettmoon](https://github.com/garrettmoon)
- [new] Allow use of NSURLCache via a custom NSURLSession [#477](https://github.com/pinterest/PINRemoteImage/pull/477) [wiseoldduck](https://github.com/wiseoldduck)
- [new] Respect Cache-Control and Expires headers if the cache supports TTL. [#462](https://github.com/pinterest/PINRemoteImage/pull/462) [wiseoldduck](https://github.com/wiseoldduck)
- [new] Updated to latest PINCache beta 7. [#461](https://github.com/pinterest/PINRemoteImage/pull/461) [wiseoldduck](https://github.com/wiseoldduck)
- [iOS11] Fix warnings [#428](https://github.com/pinterest/PINRemoteImage/pull/428) [Eke](https://github.com/Eke)
- [new / beta] Native Support for GIFs and animated WebP [#453](https://github.com/pinterest/PINRemoteImage/pull/453) [garrettmoon](https://github.com/garrettmoon)
- [new] Add support for getting NSURLSessionMetrics back. [#456](https://github.com/pinterest/PINRemoteImage/pull/456) [garrettmoon](https://github.com/garrettmoon)
- [removed] Removed support for FLAnimatedImage [#453](https://github.com/pinterest/PINRemoteImage/pull/453) [garrettmoon](https://github.com/garrettmoon)
- [new] Add support for higher frame rate devices to animated images. [#417](https://github.com/pinterest/PINRemoteImage/pull/417) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes non-animated GIFs being delivered as an animated image. [#434](https://github.com/pinterest/PINRemoteImage/pull/434) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes a bug where using PINRemoteImageBasicCache would cause images to be decoded on the main thread. [#457](https://github.com/pinterest/PINRemoteImage/pull/457) [kgaidis](https://github.com/kgaidis)
- [cleanup] Remove unused code that supported iOS < 7. [#435](https://github.com/pinterest/PINRemoteImage/pull/435) [Adlai-Holler](https://github.com/Adlai-Holler)
- [cleanup] Use NS_ERROR_ENUM to improve Swift import. [#440](https://github.com/pinterest/PINRemoteImage/pull/440) [Adlai-Holler](https://github.com/Adlai-Holler)
- [fixed] Fixes nil session manager configuration. [#460](https://github.com/pinterest/PINRemoteImage/pull/460) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes deprecated -defaultImageCache not being called if overridden. [479](https://github.com/pinterest/PINRemoteImage/pull/479) [nguyenhuy](https://github.com/nguyenhuy)
- [new] Add a new API that allows a priority to be set when a new download task is scheduled. [#490](https://github.com/pinterest/PINRemoteImage/pull/490) [nguyenhuy](https://github.com/nguyenhuy)

## 3.0.0 Beta 13
- [new] Support for webp and improved support for GIFs. [#411](https://github.com/pinterest/PINRemoteImage/pull/411) [garrettmoon](https://github.com/garrettmoon)
- [new] Added back tvOS support through a new target [#408](https://github.com/pinterest/PINRemoteImage/pull/408) [jverdi](https://github.com/jverdi)
- [refactor] Refactor out KVO on NSURLSessionTask to avoid Apple crashes. [#410](https://github.com/pinterest/PINRemoteImage/pull/410) [garrettmoon](https://github.com/garrettmoon)

## 3.0.0 Beta 12
- [new] Added a way to specify custom retry logic when network error happens [#386](https://github.com/pinterest/PINRemoteImage/pull/386)
- [new] Improve disk cache migration performance [#391](https://github.com/pinterest/PINRemoteImage/pull/391) [chuganzy](https://github.com/chuganzy), [#394](https://github.com/pinterest/PINRemoteImage/pull/394) [nguyenhuy](https://github.com/nguyenhuy)
- [new] Adds support for using cell vs. wifi in leau of speed for determing which URL to download if speed is unavailable. [garrettmoon](https://github.com/garrettmoon)
- [new] Uses BPS minus time to first byte for deciding which of a set of URLs to download. [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes an edge case when image returned with 404 response, we now treat it as image instead of error [#399](https://github.com/pinterest/PINRemoteImage/pull/396) [maxwang](https://github.com/wsdwsd0829)

## 3.0.0 Beta 11
- [fixed] Fixes a deadlock with canceling processor tasks [#374](https://github.com/pinterest/PINRemoteImage/pull/374) [zachwaugh](https://github.com/zachwaugh)
- [fixed] Fixes a deadlock in the retry system. [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes a threadsafety issue in accessing callbacks. [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes a crash with resumed downloads when a key is long. [garrettmoon](https://github.com/garrettmoon)
- [new] PINRemoteImageManager now respects the request timeout value of session configuration. [garrettmoon](https://github.com/garrettmoon)
- [new] Updated to latest PINCache beta 5. [garrettmoon](https://github.com/garrettmoon)
- [new] Added support for getting NSURLResponse from a PINRemoteImageManagerResult object. [garrettmoon](https://github.com/garrettmoon)

## 3.0.0 Beta 10
- [new] Added support (in iOS 10) for skipping cancelation if the estimated amount of time to complete the download is less than the average time to first byte for a host. [#364](https://github.com/pinterest/PINRemoteImage/pull/364) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes an issue where PINResume would assert because the server didn't return an expected content length.
- [fixed] Fixed bytes per second on download tasks (which could affect if an image is progressively rendered) [#360](https://github.com/pinterest/PINRemoteImage/pull/360) [garrettmoon](https://github.com/garrettmoon)
- [new] Added request configuration handler to allow customizing HTTP headers per request [#355](https://github.com/pinterest/PINRemoteImage/pull/355) [zachwaugh](https://github.com/zachwaugh)
- [fixed] Moved storage of resume data to disk from memory. [garrettmoon](https://github.com/garrettmoon)
- [fixed] Hopefully fixes crashes occuring in PINURLSessionManager on iOS 9. [garrettmoon](https://github.com/garrettmoon)

## 2.1.4 -- 2016 Apr 22
- [new] Have PINProgressiveImage pass back the quality of the current progressive image [#185](https://github.com/pinterest/PINRemoteImage/pull/185)

## 2.1.3 -- 2016 Apr 13
- [fixed] Images May Be Removed from Disk Cache for Not Being in Memory Cache [#186](https://github.com/pinterest/PINRemoteImage/commit/f15ca03ece954b4712b2c669c849245617e73e08)

## 2.1.2 -- 2016 Mar 25
- [fixed] Remove disk cache call potentially on main thread [#167](https://github.com/pinterest/PINRemoteImage/pull/167)
- [fixed] Nullability specifiers [#170](https://github.com/pinterest/PINRemoteImage/pull/170)
- [fixed] Speling errorrs, unused properties and spacing [#172](https://github.com/pinterest/PINRemoteImage/pull/172)

## 2.1.1 -- 2016 Mar 20
- [new] Slightly more performant locking [#165](https://github.com/pinterest/PINRemoteImage/pull/165)
- [new] Added support for pulling images synchronously from the cache [#162](https://github.com/pinterest/PINRemoteImage/pull/162)
- [fixed] Non-decoded images no longer cached by OS [#161](https://github.com/pinterest/PINRemoteImage/pull/161)
- [fixed] OS X and Carthage support [#164](https://github.com/pinterest/PINRemoteImage/pull/164)

## 2.1 -- 2016 Mar 11
- [new] tvOS support: [#131](https://github.com/pinterest/PINRemoteImage/pull/131)
- [new] Added method to get image out of cache synchronously: [#162](https://github.com/pinterest/PINRemoteImage/pull/162)
- [fixed] Undecoded images are no longer cached by OS: [#161](https://github.com/pinterest/PINRemoteImage/pull/161)
- [fixed] Carthage support and OS X example: [#160](https://github.com/pinterest/PINRemoteImage/pull/160)

## 2.0.1 -- 2016 Feb 23
- [new] Removed explicit disabling of bitcode: [#136](https://github.com/pinterest/PINRemoteImage/pull/136)
- [fixed] Progressive rendering in example apps: [#148](https://github.com/pinterest/PINRemoteImage/pull/148)
- [fixed] Carthage compilation: [#141](https://github.com/pinterest/PINRemoteImage/pull/141)
- [fixed] Crash on iOS 7 when setting download priority [#137](https://github.com/pinterest/PINRemoteImage/pull/137)
- [fixed] Dumb test bugs! [#144](https://github.com/pinterest/PINRemoteImage/pull/144)
