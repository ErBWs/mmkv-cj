/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 *
 * C bindings for the MMKV Flutter bridge exported by libmmkv.so.
 *
 * These declarations deliberately use the default `internal` visibility.
 * Keep the high-level public API in separate wrapper types.
 */

protected package ohos_app_cangjie_mmkv.native

// Initialization and instance creation

foreign func mmkvInitialize_v2(
    rootDir: CString,
    cacheDir: CString,
    sdkInt: Int32,
    logLevel: Int32,
    callback: CFunc<(
        level: UInt32,
        file: CString,
        line: Int32,
        funcname: CString,
        message: CString
    ) -> Unit>
): CPointer<Unit>

foreign func getMMKVWithID(
    mmapID: CString,
    mode: Int32,
    cryptKey: CString,
    rootPath: CString,
    expectedCapacity: UIntNative,
    fromNameSpace: Bool,
    aes256: Bool,
    enableKeyExpire: Int32,
    expiredInSeconds: Int32,
    enableCompareBeforeSet: Bool,
    recover: Int32,
    itemSizeLimit: UInt32
): CPointer<Unit>

foreign func getDefaultMMKV(
    mode: Int32,
    cryptKey: CString,
    aes256: Bool,
    expectedCapacity: UIntNative,
    enableKeyExpire: Int32,
    expiredInSeconds: Int32,
    enableCompareBeforeSet: Bool,
    recover: Int32,
    itemSizeLimit: UInt32
): CPointer<Unit>

foreign func mmapID(handle: CPointer<Unit>): CString

// Primitive values and byte buffers

foreign func encodeBool_v2(
    handle: CPointer<Unit>,
    key: CString,
    value: Bool,
    expiration: UInt32
): Bool

foreign func decodeBool(handle: CPointer<Unit>, key: CString, defaultValue: Bool): Bool

foreign func encodeInt32_v2(
    handle: CPointer<Unit>,
    key: CString,
    value: Int32,
    expiration: UInt32
): Bool

foreign func decodeInt32(handle: CPointer<Unit>, key: CString, defaultValue: Int32): Int32

foreign func encodeInt64_v2(
    handle: CPointer<Unit>,
    key: CString,
    value: Int64,
    expiration: UInt32
): Bool

foreign func decodeInt64(handle: CPointer<Unit>, key: CString, defaultValue: Int64): Int64

foreign func encodeDouble_v2(
    handle: CPointer<Unit>,
    key: CString,
    value: Float64,
    expiration: UInt32
): Bool

foreign func decodeDouble(handle: CPointer<Unit>, key: CString, defaultValue: Float64): Float64

foreign func encodeBytes_v2(
    handle: CPointer<Unit>,
    key: CString,
    value: CPointer<Unit>,
    length: UInt64,
    expiration: UInt32
): Bool

/**
 * The returned buffer is allocated by MMKV when non-null and non-empty.
 * Its ownership is transferred to the caller.
 */
foreign func decodeBytes(
    handle: CPointer<Unit>,
    key: CString,
    length: CPointer<UInt64>
): CPointer<Unit>

// Encryption

foreign func reKey(
    handle: CPointer<Unit>,
    key: CString,
    length: UInt64,
    aes256: Bool
): Bool

/**
 * The returned buffer is allocated by MMKV and owned by the caller.
 */
foreign func cryptKey(handle: CPointer<Unit>, length: CPointer<UInt64>): CPointer<Unit>

foreign func checkReSetCryptKey(
    handle: CPointer<Unit>,
    key: CString,
    length: UInt64,
    aes256: Bool
): Unit

// Querying and mutation

foreign func valueSize(handle: CPointer<Unit>, key: CString, actualSize: Bool): UInt32

foreign func writeValueToNB(
    handle: CPointer<Unit>,
    key: CString,
    buffer: CPointer<Unit>,
    size: UInt32
): Int32

/**
 * MMKV allocates the returned key and size arrays. Their ownership is
 * transferred to the caller.
 */
foreign func allKeys(
    handle: CPointer<Unit>,
    keyArray: CPointer<CPointer<CString>>,
    sizeArray: CPointer<CPointer<UInt32>>,
    filterExpire: Bool
): UInt64

foreign func containsKey(handle: CPointer<Unit>, key: CString): Bool

foreign func count(handle: CPointer<Unit>, filterExpire: Bool): UInt64

foreign func totalSize(handle: CPointer<Unit>): UInt64

foreign func actualSize(handle: CPointer<Unit>): UInt64

foreign func removeValueForKey(handle: CPointer<Unit>, key: CString): Unit

foreign func removeValuesForKeys(
    handle: CPointer<Unit>,
    keyArray: CPointer<CString>,
    sizeArray: CPointer<UInt32>,
    count: UInt64
): Unit

foreign func clearAll(handle: CPointer<Unit>, keepSpace: Bool): Unit

// Instance lifecycle and storage management

foreign func mmkvSync(handle: CPointer<Unit>, sync: Bool): Unit

foreign func clearMemoryCache(handle: CPointer<Unit>): Unit

foreign func pageSize(): Int32

foreign func version(): CString

foreign func trim(handle: CPointer<Unit>): Unit

foreign func mmkvClose(handle: CPointer<Unit>): Unit

foreign func mmkvMemcpy(
    destination: CPointer<Unit>,
    source: CPointer<Unit>,
    size: UInt64
): Unit

foreign func backupOne(mmapID: CString, destinationDir: CString, rootPath: CString): Bool

foreign func restoreOne(mmapID: CString, sourceDir: CString, rootPath: CString): Bool

foreign func backupAll(destinationDir: CString): UInt64

foreign func restoreAll(sourceDir: CString): UInt64

foreign func enableAutoExpire(handle: CPointer<Unit>, expiration: UInt32): Bool

foreign func disableAutoExpire(handle: CPointer<Unit>): Bool

foreign func enableCompareBeforeSet(handle: CPointer<Unit>): Bool

foreign func disableCompareBeforeSet(handle: CPointer<Unit>): Bool

foreign func isFileValid(mmapID: CString, rootPath: CString): Bool

foreign func removeStorage(mmapID: CString, rootPath: CString): Bool

foreign func isMultiProcess(handle: CPointer<Unit>): Bool

foreign func isReadOnly(handle: CPointer<Unit>): Bool

foreign func getNameSpace(rootPath: CString): Bool

foreign func checkExist(mmapID: CString, rootPath: CString): Bool

foreign func importFrom(handle: CPointer<Unit>, sourceHandle: CPointer<Unit>): UInt64

// Handler registration

foreign func registerErrorHandler(
    callback: CFunc<(mmapID: CString, errorType: Int32) -> Int32>
): Unit

foreign func registerContentChangeNotify(
    callback: CFunc<(mmapID: CString) -> Unit>
): Unit

foreign func registerContentLoadedNotify(
    callback: CFunc<(mmapID: CString) -> Unit>
): Unit

foreign func checkContentChanged(handle: CPointer<Unit>): Unit

protected let c_mmkvInitialize_v2 = mmkvInitialize_v2
protected let c_getMMKVWithID = getMMKVWithID
protected let c_getDefaultMMKV = getDefaultMMKV
protected let c_mmapID = mmapID
protected let c_encodeBool_v2 = encodeBool_v2
protected let c_decodeBool = decodeBool
protected let c_encodeInt32_v2 = encodeInt32_v2
protected let c_decodeInt32 = decodeInt32
protected let c_encodeInt64_v2 = encodeInt64_v2
protected let c_decodeInt64 = decodeInt64
protected let c_encodeDouble_v2 = encodeDouble_v2
protected let c_decodeDouble = decodeDouble
protected let c_encodeBytes_v2 = encodeBytes_v2
protected let c_decodeBytes = decodeBytes
protected let c_reKey = reKey
protected let c_cryptKey = cryptKey
protected let c_checkReSetCryptKey = checkReSetCryptKey
protected let c_valueSize = valueSize
protected let c_writeValueToNB = writeValueToNB
protected let c_allKeys = allKeys
protected let c_containsKey = containsKey
protected let c_count = count
protected let c_totalSize = totalSize
protected let c_actualSize = actualSize
protected let c_removeValueForKey = removeValueForKey
protected let c_removeValuesForKeys = removeValuesForKeys
protected let c_clearAll = clearAll
protected let c_mmkvSync = mmkvSync
protected let c_clearMemoryCache = clearMemoryCache
protected let c_pageSize = pageSize
protected let c_version = version
protected let c_trim = trim
protected let c_mmkvClose = mmkvClose
protected let c_mmkvMemcpy = mmkvMemcpy
protected let c_backupOne = backupOne
protected let c_restoreOne = restoreOne
protected let c_backupAll = backupAll
protected let c_restoreAll = restoreAll
protected let c_enableAutoExpire = enableAutoExpire
protected let c_disableAutoExpire = disableAutoExpire
protected let c_enableCompareBeforeSet = enableCompareBeforeSet
protected let c_disableCompareBeforeSet = disableCompareBeforeSet
protected let c_isFileValid = isFileValid
protected let c_removeStorage = removeStorage
protected let c_isMultiProcess = isMultiProcess
protected let c_isReadOnly = isReadOnly
protected let c_getNameSpace = getNameSpace
protected let c_checkExist = checkExist
protected let c_importFrom = importFrom
protected let c_registerErrorHandler = registerErrorHandler
protected let c_registerContentChangeNotify = registerContentChangeNotify
protected let c_registerContentLoadedNotify = registerContentLoadedNotify
protected let c_checkContentChanged = checkContentChanged
