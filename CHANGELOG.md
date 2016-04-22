### 2.1.4 -- 2016 Apr 22 ###
- [new] Have PINProgressiveImage pass back the quality of the current progressive image [#185](https://github.com/pinterest/PINRemoteImage/pull/185)

### 2.1.3 -- 2016 Apr 13 ###
- [fixed] Images May Be Removed from Disk Cache for Not Being in Memory Cache [#186](https://github.com/pinterest/PINRemoteImage/commit/f15ca03ece954b4712b2c669c849245617e73e08)

### 2.1.2 -- 2016 Mar 25 ###
- [fixed] Remove disk cache call potentially on main thread [#167](https://github.com/pinterest/PINRemoteImage/pull/167)
- [fixed] Nullability specifiers [#170](https://github.com/pinterest/PINRemoteImage/pull/170)
- [fixed] Speling errorrs, unused properties and spacing [#172](https://github.com/pinterest/PINRemoteImage/pull/172)

### 2.1.1 -- 2016 Mar 20 ###
- [new] Slightly more performant locking [#165](https://github.com/pinterest/PINRemoteImage/pull/165)
- [new] Added support for pulling images synchronously from the cache [#162](https://github.com/pinterest/PINRemoteImage/pull/162)
- [fixed] Non-decoded images no longer cached by OS [#161](https://github.com/pinterest/PINRemoteImage/pull/161)
- [fixed] OS X and Carthage support [#164](https://github.com/pinterest/PINRemoteImage/pull/164)

### 2.1 -- 2016 Mar 11 ###
- [new] tvOS support: [#131](https://github.com/pinterest/PINRemoteImage/pull/131)
- [new] Added method to get image out of cache synchronously: [#162](https://github.com/pinterest/PINRemoteImage/pull/162)
- [fixed] Undecoded images are no longer cached by OS: [#161](https://github.com/pinterest/PINRemoteImage/pull/161)
- [fixed] Carthage support and OS X example: [#160](https://github.com/pinterest/PINRemoteImage/pull/160)

### 2.0.1 -- 2016 Feb 23 ###
- [new] Removed explicit disabling of bitcode: [#136](https://github.com/pinterest/PINRemoteImage/pull/136)
- [fixed] Progressive rendering in example apps: [#148](https://github.com/pinterest/PINRemoteImage/pull/148)
- [fixed] Carthage compilation: [#141](https://github.com/pinterest/PINRemoteImage/pull/141)
- [fixed] Crash on iOS 7 when setting download priority [#137](https://github.com/pinterest/PINRemoteImage/pull/137)
- [fixed] Dumb test bugs! [#144](https://github.com/pinterest/PINRemoteImage/pull/144)