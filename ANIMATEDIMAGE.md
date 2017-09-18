# TODO
- Test on a device.
- Ensure PINGifAnimatedImage is threadsafe
- Ensure PINWebPAnimatedImage is threadsafe
- Ensure PINCachedAnimatedImage is threadsafe
- Ensure PINAnimatedImage is threadsafe
- Add framesize property to PINAnimatedImage for calculation in framesToCache ?
- Add support for handling memory warnings, likely need to adjust framesToCache method and have some slow reincrease after recieving a memory warning without recieving a new one for a while.
- Consider using PINOperationQueue in PINCachedAnimatedImage