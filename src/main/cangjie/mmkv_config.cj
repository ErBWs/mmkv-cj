/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv

/**
 * All-in-one configuration for creating a MMKV instance.
 */
public class MMKVConfig {
    public var mode: Int32 // Defaults to SINGLE_PROCESS_MODE
    public var aes256: Bool // using AES-256 key length
    public var cryptKey: ?String
    public var rootPath: ?String

    public var expectedCapacity: UIntNative // the initial file size

    public var enableKeyExpire: ?Bool
    public var expiredInSeconds: Int32 // ExpireNever = 0

    public var enableCompareBeforeSet: Bool

    public var recover: ?MMKVRecoverStrategic // if not set, use the old style callback

    public var itemSizeLimit: UInt32 // the size limit of a key-value pair, reject insert if pass limit

    public init(
        mode!: Int32 = MMKV.SINGLE_PROCESS_MODE,
        aes256!: Bool = false,
        cryptKey!: ?String = None,
        rootPath!: ?String = None,
        expectedCapacity!: UIntNative = 0,
        enableKeyExpire!: ?Bool = None,
        expiredInSeconds!: Int32 = 0,
        enableCompareBeforeSet!: Bool = false,
        recover!: ?MMKVRecoverStrategic = None,
        itemSizeLimit!: UInt32 = 0
    ) {
        this.mode = mode
        this.aes256 = aes256
        this.cryptKey = cryptKey
        this.rootPath = rootPath
        this.expectedCapacity = expectedCapacity
        this.enableKeyExpire = enableKeyExpire
        this.expiredInSeconds = expiredInSeconds
        this.enableCompareBeforeSet = enableCompareBeforeSet
        this.recover = recover
        this.itemSizeLimit = itemSizeLimit
    }
}
