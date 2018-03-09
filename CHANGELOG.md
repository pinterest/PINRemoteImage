## master
* Add your own contributions to the next release on the line below this with your name.
- [iOS11] Fix warnings [#428](https://github.com/pinterest/PINRemoteImage/pull/428) [Eke](https://github.com/Eke)
- [new] Add support for higher frame rate devices to animated images. [#417](https://github.com/pinterest/PINRemoteImage/pull/417) [garrettmoon](https://github.com/garrettmoon)
- [fixed] Fixes non-animated GIFs being delivered as an animated image. [#434](https://github.com/pinterest/PINRemoteImage/pull/434) [garrettmoon](https://github.com/garrettmoon)
- Remove unused code that supported iOS < 7. [#435](https://github.com/pinterest/PINRemoteImage/pull/435) [Adlai-Holler](https://github.com/Adlai-Holler)
- Use NS_ERROR_ENUM to improve Swift import. [#440](https://github.com/pinterest/PINRemoteImage/pull/440) [Adlai-Holler](https://github.com/Adlai-Holler)

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
