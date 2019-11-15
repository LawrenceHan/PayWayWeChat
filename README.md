#  PayWayWeChat

### Setup

1. Add LSApplicationQueriesSchemes: `weixin`, `weixinULAPI` in `Info.plist`.
2. Add URL Type for `WeChat` url schemes.
3. In `application:didFinishLaunchingWithOptions` call `WXPay.default.registerApp`.
4. In `app:open url:options:` call `WXPay.default.open(url: url, options: options)`.
5. Use `WXPay.default.isDebug` to set debug mode.
6. Use `WXPay.default.callbackTimeout` to control callback timeout.

### References:

[Network Link Conditioner](https://nshipster.com/network-link-conditioner/)

[Bridging header for framework](https://stackoverflow.com/questions/24875745/xcode-6-beta-4-using-bridging-headers-with-framework-targets-is-unsupported)

[Mixed Modules](https://medium.com/allatoneplace/challenges-building-a-swift-framework-d882867c97f9)

