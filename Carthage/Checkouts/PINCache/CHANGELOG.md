# Changelog

## [3.0.3](https://github.com/Pinterest/PINCache/tree/3.0.3) (2020-10-22)

[Full Changelog](https://github.com/Pinterest/PINCache/compare/3.0.2...3.0.3)


- Update PINOperation to fix imports [\#293](https://github.com/pinterest/PINCache/pull/293) ([garrettmoon](https://github.com/garrettmoon))
- Add support for automated releases [\#292](https://github.com/pinterest/PINCache/pull/292) ([garrettmoon](https://github.com/garrettmoon))
- Fix up imports [\#290](https://github.com/pinterest/PINCache/pull/290) ([garrettmoon](https://github.com/garrettmoon))
- Fix build issues by removing nested PINOperation.xcodeproj [\#282](https://github.com/pinterest/PINCache/pull/282) ([elliottwilliams](https://github.com/elliottwilliams))

## [3.0.2](https://github.com/Pinterest/PINCache/tree/3.0.2) (2020-10-06)

[Full Changelog](https://github.com/Pinterest/PINCache/compare/3.0.1...3.0.2)

**Merged pull requests:**

- Update checkout action [\#287](https://github.com/pinterest/PINCache/pull/287) ([garrettmoon](https://github.com/garrettmoon))
- Use make commands on the CI so it actually fails [\#286](https://github.com/pinterest/PINCache/pull/286) ([garrettmoon](https://github.com/garrettmoon))
- Added SPM support [\#283](https://github.com/pinterest/PINCache/pull/283) ([3a4oT](https://github.com/3a4oT))
- Fix PINCaching compiling in Xcode 12.0b6 \(\#275\) [\#281](https://github.com/pinterest/PINCache/pull/281) ([sagesse-cn](https://github.com/sagesse-cn))

## [3.0.1](https://github.com/Pinterest/PINCache/tree/3.0.1) (2020-08-20)

[Full Changelog](https://github.com/Pinterest/PINCache/compare/3.0.1-beta.8...3.0.1)

**Implemented enhancements:**

- Support Catalyst [\#272](https://github.com/pinterest/PINCache/pull/272) ([cgmaier](https://github.com/cgmaier))

**Merged pull requests:**

- Update PINOperation [\#277](https://github.com/pinterest/PINCache/pull/277) ([garrettmoon](https://github.com/garrettmoon))
- Fix PINCacheTests compiling in Xcode 12.0b4 [\#276](https://github.com/pinterest/PINCache/pull/276) ([arangato](https://github.com/arangato))
- Remove BUCK files [\#274](https://github.com/pinterest/PINCache/pull/274) ([adlerj](https://github.com/adlerj))
- Fix compiling in Xcode 12.0b4 [\#273](https://github.com/pinterest/PINCache/pull/273) ([zacwest](https://github.com/zacwest))
- Fix the grammar in an assertion failure message [\#270](https://github.com/pinterest/PINCache/pull/270) ([jparise](https://github.com/jparise))
- Add Carthage for watchOS, fix macOS min deployment target version [\#269](https://github.com/pinterest/PINCache/pull/269) ([dreampiggy](https://github.com/dreampiggy))
- Remove the unused CI directory [\#265](https://github.com/pinterest/PINCache/pull/265) ([jparise](https://github.com/jparise))
- Fix up analyze for github CI [\#264](https://github.com/pinterest/PINCache/pull/264) ([garrettmoon](https://github.com/garrettmoon))
- Use correct class name in NSAssert\(\) messages [\#263](https://github.com/pinterest/PINCache/pull/263) ([jparise](https://github.com/jparise))
- Check fileURL outside of the locked scope [\#262](https://github.com/pinterest/PINCache/pull/262) ([jparise](https://github.com/jparise))
- Remove Danger from the project [\#261](https://github.com/pinterest/PINCache/pull/261) ([jparise](https://github.com/jparise))
- Switch to GitHub Actions for CI [\#259](https://github.com/pinterest/PINCache/pull/259) ([jparise](https://github.com/jparise))
- Test that the "remove object" blocks are called [\#258](https://github.com/pinterest/PINCache/pull/258) ([jparise](https://github.com/jparise))
- Discrepancy between Header Comment and Implementation \#trivial [\#257](https://github.com/pinterest/PINCache/pull/257) ([jlaws](https://github.com/jlaws))
- Optimization `PINMemoryCache` trim to date [\#252](https://github.com/pinterest/PINCache/pull/252) ([kinarobin](https://github.com/kinarobin))
- Optimize `PINMemoryCache` remove objects when receive memory warning notification [\#251](https://github.com/pinterest/PINCache/pull/251) ([kinarobin](https://github.com/kinarobin))

## 3.0.1 -- Beta 8
- [fix] Initing PINCache with TTL enabled should enable TTL on PINMemoryCache. [#246](https://github.com/pinterest/PINCache/pull/246)
- [performance] Return TTL cache objects without waiting for all metadata to be read. [#228](https://github.com/pinterest/PINCache/pull/228)
- [performance] Memory cache now performs some tasks such as trimming and removing experied objects with low priority. [#234](https://github.com/pinterest/PINCache/pull/234)

## 3.0.1 -- Beta 7
- [fix] Fix up warnings and upgrade to PINOperation 1.1.1: [#213](https://github.com/pinterest/PINCache/pull/213)
- [performance] Reduce locking churn in cleanup methods. [#212](https://github.com/pinterest/PINCache/pull/212)
- [fix] Don't set file protection unless requested. [#220](https://github.com/pinterest/PINCache/pull/220)
- [new] Add ability to set an object level TTL: [#209](https://github.com/pinterest/PINCache/pull/209)
- [performance] Improve performance of age limit trimming: [#224](https://github.com/pinterest/PINCache/pull/224)

## 3.0.1 -- Beta 6
- [fix] Add some sane limits to the disk cache: [#201]https://github.com/pinterest/PINCache/pull/201
- [new] Update enumeration methods to allow a stop flag to be flipped by caller: [#204](https://github.com/pinterest/PINCache/pull/204)
- [performance] Improves cache miss performance by ~2 orders of magnitude on device: [#202](https://github.com/pinterest/PINCache/pull/202)
- [performance] Significantly improve startup performance: [#203](https://github.com/pinterest/PINCache/pull/203)

## 3.0.1 -- Beta 5
- [fix] Respect small byteLimit settings by checking object size in setObject: [#198](https://github.com/pinterest/PINCache/pull/198)
- [new] Added an ability to set custom encoder/decoder for file names: [#192](https://github.com/pinterest/PINCache/pull/192)

## 2.2.1 -- 2016 Mar 5
- [new] Removed need for extension macro: [#72](https://github.com/pinterest/PINCache/pull/72)

## 2.2.1 -- 2016 Feb 15

- [fixed] When ttlCache is enabled, skip updating the file modification time when accessing `fileURLForKey:` [#70](https://github.com/pinterest/PINCache/pull/70)

## 2.2 -- 2016 Feb 10

- [new] Allow caches to behave like a TTLCache [#66](https://github.com/pinterest/PINCache/pull/66)

## 2.1.2 -- 2015 Nov 19

- [fix] Fix disk caching bug due to incorrect string encoding [#42](https://github.com/pinterest/PINCache/pull/42)


## 2.1.1 -- 2015 Nov 17

- [new] Added `tvOS` support
- [fixed] PINDiskCache byteCount tracking bug [#30](https://github.com/pinterest/PINCache/pull/30)


## 2.1 -- 2015 Aug 24

- [new] Xcode 7 support
- [fixed] Invalid task ID's used for expiration handler on background tasks [#13](https://github.com/pinterest/PINCache/issues/13)
- [fixed] Support for OS X since UIBackgroundTask is only on iOS [#19](https://github.com/pinterest/PINCache/pull/19)


## 2.0.1 -- 2015 May 1

- [new] Added support for using PINCache in extensions
- [new] Adopting nullability annotations.


## 2.0 -- 2015 February 25

- [fix] PINCache redesign to avoid deadlocks


## 1.2.3 -- 2014 December 13

- [fix] TMDiskCache/TMMemoryCache: import `UIKit` to facilitate Swift usage (thanks [digabriel](https://github.com/tumblr/TMCache/pull/57)!)
- [fix] TMDiskCache: add try catch to ensure an exception isn’t thrown if a file on disk is unable to be unarchived (thanks [leonskywalker](https://github.com/tumblr/TMCache/pull/62)!)
- [fix] TMDiskCache: create trash directory asynchronously to avoid race condition (thanks [napoapo77](https://github.com/tumblr/TMCache/pull/68)!)


## 1.2.2 -- 2014 October 6

- [new] Remove deprecated `documentation` property from Podspec


## 1.2.1 -- 2013 July 28

- [new] TMDiskCache: introduced concept of "trash" for rapid wipeouts
- [new] TMDiskCache: `nil` checks to prevent crashes
- [new] TMCache/TMDiskCache/TMMemoryCache: import Foundation to facilitate Swift usage


## 1.2.0 -- 2013 May 24

- [new] TMDiskCache: added method `enumerateObjectsWithBlock:completionBlock:`
- [new] TMDiskCache: added method `enumerateObjectsWithBlock:`
- [new] TMDiskCache: added unit tests for the above
- [new] TMMemoryCache: added method `enumerateObjectsWithBlock:completionBlock:`
- [new] TMMemoryCache: added method `enumerateObjectsWithBlock:`
- [new] TMMemoryCache: added event block `didReceiveMemoryWarningBlock`
- [new] TMMemoryCache: added event block `didEnterBackgroundBlock`
- [new] TMMemoryCache: added boolean property `removeAllObjectsOnMemoryWarning`
- [new] TMMemoryCache: added boolean property `removeAllObjectsOnEnteringBackground`
- [new] TMMemoryCache: added unit tests for memory warning and app background blocks
- [del] TMCache: removed `cost` methods pending a solution for disk-based cost


## 1.1.2 -- 2013 May 13

- [fix] TMCache: prevent `objectForKey:block:` from hitting the thread ceiling
- [new] TMCache: added a test to make sure we don't deadlock the queue


## 1.1.1 -- 2013 May 1

- [fix] simplified appledoc arguments in podspec, updated doc script


## 1.1.0 -- 2013 April 29

- [new] TMCache: added method `setObject:forKey:withCost:`
- [new] TMCache: documentation


## 1.0.3 -- 2013 April 27

- [new] TMCache: added property `diskByteCount` (for convenience)
- [new] TMMemoryCache: `totalCost` now returned synchronously from queue
- [fix] TMMemoryCache: `totalCost` set to zero immediately after `removeAllObjects:`


## 1.0.2 -- 2013 April 26

- [fix] TMCache: cache hits from memory will now update access time on disk
- [fix] TMDiskCache: set & remove methods now acquire a `UIBackgroundTaskIdentifier`
- [fix] TMDiskCache: will/didAddObject blocks actually get executed
- [fix] TMDiskCache: `trimToSize:` now correctly removes objects in order of size
- [fix] TMMemoryCache: `trimToCost:` now correctly removes objects in order of cost
- [new] TMDiskCache: added method `trimToSizeByDate:`
- [new] TMMemoryCache: added method `trimToCostByDate:`
- [new] TMDiskCache: added properties `willRemoveAllObjectsBlock` & `didRemoveAllObjectsBlock`
- [new] TMMemoryCache: added properties `willRemoveAllObjectsBlock` & `didRemoveAllObjectsBlock`
- [new] TMCache: added unit tests


## 1.0.1 -- 2013 April 23

- added an optional "cost limit" to `TMMemoryCache`, including new properties and methods
- calling `[TMDiskCache trimToDate:]` with `[NSDate distantPast]` will now clear the cache
- calling `[TMDiskCache trimDiskToSize:]` will now remove files in order of access date
- setting the byte limit on `TMDiskCache` to 0 will no longer clear the cache (0 means no limit)
