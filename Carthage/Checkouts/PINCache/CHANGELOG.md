## master

* Add your own contributions to the next release on the line below this with your name.

## 3.0.1 -- Beta 5
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
