/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv

/**
 * The levels of MMKV log.
 */
public type MMKVLogLevel = Int32
/**
 * Debug level. Not available for release/production build.
 */
public let MMKVLogDebug: MMKVLogLevel = 0
/**
 * Info level. The default level.
 */
public let MMKVLogInfo: MMKVLogLevel = 1
/**
 * Warning level.
 */
public let MMKVLogWarning: MMKVLogLevel = 2
/**
 * Error level.
 */
public let MMKVLogError: MMKVLogLevel = 3
/**
 * Special level for disabling all logging.
 * It's highly NOT suggested to turn off logging. Makes it hard to diagnose online/production bugs.
 */
public let MMKVLogNone: MMKVLogLevel = 4
