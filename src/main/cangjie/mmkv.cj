/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv

import std.collection.ArrayList
import kit.AbilityKit.ApplicationContext
import kit.IPCKit.MessageSequence
import kit.IPCKit.Parcelable
import ohos_app_cangjie_mmkv.native.*

/**
 * An highly efficient, reliable, multi-process key-value storage framework.
 * THE PERFECT drop-in replacement for Preferences.
 */
public class MMKV {
    private static var _rootDir: String = ""
    private let _handle: CPointer<Unit>

    /**
     * Single-process mode. The default mode on an MMKV instance.
     */
    public static let SINGLE_PROCESS_MODE: Int32 = 1 << 0

    /**
     * Multi-process mode.
     * To enable multi-process accessing of an MMKV instance, you must set this mode whenever you getting that instance.
     */
    public static let MULTI_PROCESS_MODE: Int32 = 1 << 1

    public static let READ_ONLY_MODE: Int32 = 1 << 5

    private static let BACKUP_MODE: Int32 = 1 << 4

    public static let ExpireNever: UInt32 = 0
    public static let ExpireInMinute: UInt32 = 60
    public static let ExpireInHour: UInt32 = 60 * 60
    public static let ExpireInDay: UInt32 = 24 * 60 * 60
    public static let ExpireInMonth: UInt32 = 30 * 24 * 60 * 60
    public static let ExpireInYear: UInt32 = 365 * 30 * 24 * 60 * 60

    init(handle: CPointer<Unit>) {
        this._handle = handle
    }

    /**
     * Initialize MMKV with default configuration.
     * You must call one of the initialize() methods on App startup process before using MMKV.
     *
     * @param context The ApplicationContext of the App, usually from UIAbility.
     * @param logLevel The log level of MMKV, defaults to {@link MMKVLogLevel.LevelInfo}.
     * @param handler Handle log redirecting & crc/file check failure.
     * @returns The root folder of MMKV, defaults to $(FilesDir)/mmkv.
     */
    public static func initialize(
        context: ApplicationContext,
        logLevel!: MMKVLogLevel = MMKVLogInfo,
        handler!: ?MMKVHandler = None
    ): String {
        initializeWithPath(
            context.filesDirectory + "/mmkv",
            context.cacheDir,
            logLevel: logLevel,
            handler: handler
        )
    }

    /**
     * Initialize MMKV with customize settings.
     * You must call one of the initialize() methods on App startup process before using MMKV.
     *
     * @param rootDir The root folder of MMKV, defaults to $(FilesDir)/mmkv.
     * @param cacheDir The cache folder of MMKV, defaults to $(CacheDir).
     * @param logLevel The log level of MMKV, defaults to {@link MMKVLogLevel.LevelInfo}.
     * @param handler Handle log redirecting & crc/file check failure.
     * @returns The root folder of MMKV, defaults to $(FilesDir)/mmkv.
     */
    public static func initializeWithPath(
        rootDir: String,
        cacheDir: String,
        logLevel!: MMKVLogLevel = MMKVLogInfo,
        handler!: ?MMKVHandler = None
    ): String {
        unsafe {
            setHandler(handler)
            let root = LibC.mallocCString(rootDir)
            let cache = LibC.mallocCString(cacheDir)
            let logHandler = match (handler) {
            	case Some(v) => if (v.wantLogRedirect()) { logCallback } else { defaultLogCallback }
            	case _ => defaultLogCallback
            }
            c_mmkvInitialize_v2(
                root,
                cache,
                0,
                logLevel,
                logHandler
            )
            LibC.free(root)
            LibC.free(cache)

            registerCallbacks()
            _rootDir = rootDir
            rootDir
        }
    }

    /**
     * @param rootDir the customize root directory of a NameSpace
     * @returns a NameSpace with custom root dir
     */
    public static func nameSpace(rootDir: String): NameSpace {
        unsafe {
            let str = LibC.mallocCString(rootDir)
            let succeed = c_getNameSpace(str)
            LibC.free(str)
            if (!succeed) {
                throw IllegalArgumentException("Invalid rootDir: [${rootDir}].")
            }
            NameSpace(rootDir)
        }
    }

    /**
     * Identical with the original MMKV with the global root dir
     */
    public static func defaultNameSpace(): NameSpace {
        if (_rootDir.isEmpty()) {
            throw IllegalStateException("You should Call MMKV.initialize() first.")
        }
        NameSpace(_rootDir)
    }

    /**
     * @returns The version of MMKV.
     */
    public static prop version: String {
        get() {
            unsafe { c_version().toString() }
        }
    }

    /**
     * @returns The device's memory page size.
     */
    public static prop pageSize: Int32 {
        get() {
            unsafe { c_pageSize() }
        }
    }

    /**
     * @returns The root folder of MMKV, defaults to $(FilesDir)/mmkv.
     */
    public static prop rootDir: String {
        get() {
            _rootDir
        }
    }

    /**
     * Create the default MMKV instance in customize process mode, with an encryption key.
     *
     * @param mode The process mode of the MMKV instance, defaults to {@link MMKV.SINGLE_PROCESS_MODE}.
     * @param cryptKey The encryption key of the MMKV instance (no more than 16 bytes).
     * @returns The default MMKV instance.
     */
    public static func defaultMMKV(
        mode!: Int32 = SINGLE_PROCESS_MODE,
        cryptKey!: ?String = None,
        aes256!: Bool = false
    ): MMKV {
        defaultMMKVWithConfig(
            MMKVConfig(mode: mode, cryptKey: cryptKey, aes256: aes256)
        )
    }

    /**
     * Create the default MMKV instance with all-in-one configuration.
     *
     * @param config The all-in-one configuration.
     * @returns The default MMKV instance.
     */
    public static func defaultMMKVWithConfig(config: MMKVConfig): MMKV {
        unsafe {
            if (_rootDir.isEmpty()) {
                throw IllegalStateException("You should Call MMKV.initialize() first.")
            }
            let cryptKey = match (config.cryptKey) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let enableKeyExpire: Int32 = match (config.enableKeyExpire) {
                case Some(v) => if (v) { 1 } else { 0 }
                case _ => -1
            }
            let recover = config.recover ?? -1
            let handle = c_getDefaultMMKV(
                config.mode,
                cryptKey,
                config.aes256,
                config.expectedCapacity,
                enableKeyExpire,
                config.expiredInSeconds,
                config.enableCompareBeforeSet,
                recover,
                config.itemSizeLimit
            )
            if (!cryptKey.isNull()) {
                LibC.free(cryptKey)
            }
            if (handle.isNull()) {
                throw IllegalStateException("Fail to create the default MMKV instance.")
            }
            MMKV(handle)
        }
    }

    /**
     * Create an MMKV instance.
     *
     * @param mmapID The unique ID of the MMKV instance.
     * @param mode The process mode of the MMKV instance, defaults to {@link MMKV.SINGLE_PROCESS_MODE}.
     * @param cryptKey The encryption key of the MMKV instance (no more than 16 bytes).
     * @param rootPath The folder of the MMKV instance, defaults to $(FilesDir)/mmkv.
     * @param expectedCapacity The file size you expected when opening or creating file.
     * @returns The MMKV instance.
     */
    public static func mmkvWithID(
        mmapID: String,
        mode!: Int32 = SINGLE_PROCESS_MODE,
        cryptKey!: ?String = None,
        rootPath!: ?String = None,
        expectedCapacity!: UIntNative = 0,
        aes256!: Bool = false
    ): MMKV {
        mmkvWithConfig(
            mmapID,
            MMKVConfig(
                mode: mode,
                cryptKey: cryptKey,
                rootPath: rootPath,
                expectedCapacity: expectedCapacity,
                aes256: aes256
            )
        )
    }

    /**
     * Creat an MMKV instance with all-in-one configuration.
     *
     * @param mmapID The unique ID of the MMKV instance.
     * @param config The all-in-one configuration.
     * @returns The MMKV instance.
     */
    public static func mmkvWithConfig(mmapID: String, config: MMKVConfig): MMKV {
        if (_rootDir.isEmpty()) {
            throw IllegalStateException("You should Call MMKV.initialize() first.")
        }

        unsafe {
            let id = LibC.mallocCString(mmapID)
            let cryptKey = match (config.cryptKey) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let rootPath = match (config.rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let enableKeyExpire: Int32 = match (config.enableKeyExpire) {
                case Some(v) => if (v) { 1 } else { 0 }
                case _ => -1
            }
            let recover = config.recover ?? -1
            let handle = c_getMMKVWithID(
                id,
                config.mode,
                cryptKey,
                rootPath,
                config.expectedCapacity,
                false,
                config.aes256,
                enableKeyExpire,
                config.expiredInSeconds,
                config.enableCompareBeforeSet,
                recover,
                config.itemSizeLimit
            )
            LibC.free(id)
            if (!cryptKey.isNull()) {
                LibC.free(cryptKey)
            }
            if (!rootPath.isNull()) {
                LibC.free(rootPath)
            }
            if (handle.isNull()) {
                throw IllegalStateException("Fail to create an MMKV instance [${mmapID}] in NAPI.")
            }
            MMKV(handle)
        }
    }

    /**
     * @returns The unique ID of the MMKV instance.
     */
    public prop mmapID: String {
        get() {
            unsafe { c_mmapID(_handle).toString() }
        }
    }

    /**
     * Set Bool value with customize expiration in seconds.
     *
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: Bool,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_encodeBool_v2(_handle, str, value, expiration)
            LibC.free(str)
            res
        }
    }

    /**
     * Get Bool value.
     *
     * @returns Bool
     */
    public func decodeBool(key: String, defaultValue!: Bool = false): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_decodeBool(_handle, str, defaultValue)
            LibC.free(str)
            res
        }
    }

    /**
     * Set Int32 value with customize expiration in seconds.
     *
     * @param value Int32
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: Int32,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_encodeInt32_v2(_handle, str, value, expiration)
            LibC.free(str)
            res
        }
    }

    /**
     * Get Int32 value.
     *
     * @returns Int32
     */
    public func decodeInt32(key: String, defaultValue!: Int32 = 0): Int32 {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_decodeInt32(_handle, str, defaultValue)
            LibC.free(str)
            res
        }
    }

    /**
     * Set Int64 value with customize expiration in seconds.
     *
     * @param value Int64
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: Int64,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_encodeInt64_v2(_handle, str, value, expiration)
            LibC.free(str)
            res
        }
    }

    /**
     * Get Int64 value.
     *
     * @returns Int64
     */
    public func decodeInt64(key: String, defaultValue!: Int64 = 0): Int64 {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_decodeInt64(_handle, str, defaultValue)
            LibC.free(str)
            res
        }
    }

    /**
     * Set Float64 value with customize expiration in seconds.
     *
     * @param value Float64
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: Float64,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_encodeDouble_v2(_handle, str, value, expiration)
            LibC.free(str)
            res
        }
    }

    /**
     * Get Float64 value.
     *
     * @returns Float64
     */
    public func decodeFloat64(
        key: String,
        defaultValue!: Float64 = 0.0
    ): Float64 {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_decodeDouble(_handle, str, defaultValue)
            LibC.free(str)
            res
        }
    }

    private func encodeBytes(
        key: String,
        value: Array<Byte>,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        unsafe {
            if (value.isEmpty()) {
            	return false
            }

            let str = LibC.mallocCString(key)
            let data = LibC.malloc<Byte>(count: value.size)
            for (i in 0..value.size) {
                data.write(i, value[i])
            }
            let res = c_encodeBytes_v2(
                _handle,
                str,
                CPointer<Unit>(data),
                UInt64(value.size),
                expiration
            )
            LibC.free(data)
            LibC.free(str)
            res
        }
    }

    /**
     * Set String value with customize expiration in seconds.
     *
     * @param value String
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: String,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        encodeBytes(key, value.toArray(), expiration: expiration)
    }

    /**
     * Get String value.
     *
     * @returns String
     */
    public func decodeString(key: String, defaultValue!: String = ""): String {
        String.fromUtf8(decodeBytes(key, defaultValue: defaultValue.toArray()))
    }

    /**
     * Set ArrayBuffer value with customize expiration in seconds.
     *
     * @param value Array<Byte>
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if failure.
     */
    public func encode(
        key: String,
        value: Array<Byte>,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        encodeBytes(key, value, expiration: expiration)
    }

    /**
     * Get Array<Byte> value.
     *
     * @returns Array<Byte>
     */
    public func decodeBytes(
        key: String,
        defaultValue!: Array<Byte> = Array<Byte>()
    ): Array<Byte> {
        unsafe {
            let str = LibC.mallocCString(key)
            let lengthPtr = LibC.malloc<UInt64>()
            let ret = c_decodeBytes(_handle, str, lengthPtr)
            LibC.free(str)

            if (ret.isNull()) {
                LibC.free(lengthPtr)
                return defaultValue
            }
            let length = lengthPtr.read()
            LibC.free(lengthPtr)

            let res = Array<Byte>(Int64(length), { i => CPointer<Byte>(ret).read(i) })
            LibC.free(ret)
            res
        }
    }

    /**
     * Set Parcelable value with customize expiration in seconds.
     *
     * @param value Parcelable
     * @param expiration override the default duration, {@link MMKV.ExpireNever} (0) means never expire.
     * @returns true if success, false if marshalling or storage fails.
     */
    public func encode(
        key: String,
        value: Parcelable,
        expiration!: UInt32 = ExpireNever
    ): Bool {
        let sequence = MessageSequence.create()
        try {
            if (!value.marshalling(sequence)) {
                return false
            }

            let size = sequence.getSize()
            if (size == 0) {
                return false
            }

            sequence.rewindRead(0)
            let bytes = sequence.readRawDataBuffer(Int64(size))
            encodeBytes(key, bytes, expiration: expiration)
        } catch (_) {
            false
        } finally {
            sequence.reclaim()
        }
    }

    /**
     * Decode a Parcelable value into an existing object.
     *
     * @param value The target object to populate.
     * @returns true if the key exists and unmarshalling succeeds, false otherwise.
     */
    public func decodeParcelable(key: String, value: Parcelable): Bool {
        let bytes = decodeBytes(key)
        if (bytes.isEmpty()) {
            return false
        }

        let sequence = MessageSequence.create()
        try {
            sequence.writeRawDataBuffer(bytes, bytes.size)
            sequence.rewindRead(0)
            value.unmarshalling(sequence)
        } catch (_) {
            false
        } finally {
            sequence.reclaim()
        }
    }

    /**
     * Check whether or not MMKV contains the key.
     *
     * @param key The key of the value.
     */
    public func containsKey(key: String): Bool {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_containsKey(_handle, str)
            LibC.free(str)
            res
        }
    }

    /**
     * Get all the key.
     *
     * @param filterExpire true to filter all non-expired keys. Note that this has costs.
     * @return Array<String>
     */
    public func allKeys(filterExpire!: Bool = false): Array<String> {
        unsafe {
            let keyArrayPtr = LibC.malloc<CPointer<CString>>()
            let sizeArrayPtr = LibC.malloc<CPointer<UInt32>>()
            let keys = ArrayList<String>()

            let count = c_allKeys(_handle, keyArrayPtr, sizeArrayPtr, filterExpire)
            if (count > 0) {
                let keyArray = keyArrayPtr.read()
                let sizeArray = sizeArrayPtr.read()
                for (i in 0..Int64(count)) {
                    let keyPtr = keyArray.read(i)
                    let size = sizeArray.read(i)
                    let bytes = Array<UInt8>(Int64(size), { e => keyPtr.getChars().read(e) })
                    keys.add(String.fromUtf8(bytes))
                    LibC.free(keyPtr)
                }
                if (keyArray.isNotNull()) {
                    LibC.free(keyArray)
                }
                if (sizeArray.isNotNull()) {
                    LibC.free(sizeArray)
                }
            }
            LibC.free(keyArrayPtr)
            LibC.free(sizeArrayPtr)
            keys.toArray()
        }
    }

    /**
     * @param filterExpire  true to filter all non-expired keys. Note that this has costs.
     * @return The total count of all the keys.
     */
    public func count(filterExpire!: Bool = false): UInt64 {
        unsafe { c_count(_handle, filterExpire) }
    }

    /**
     * Remove the value for one key.
     */
    public func removeValueForKey(key: String) {
        unsafe {
            let str = LibC.mallocCString(key)
            c_removeValueForKey(_handle, str)
            LibC.free(str)
        }
    }

    /**
     * Batch remove some keys from the MMKV instance.
     *
     * @param arrKeys Array<String> The keys to be removed.
     */
    public func removeValuesForKeys(keys: Array<String>) {
        unsafe {
            if (keys.isEmpty()) {
                return
            }

            let cstrs = keys.map { s => LibC.mallocCString(s) }

            let keyArray = LibC.malloc<CString>(count: keys.size)
            let sizeArray = LibC.malloc<UInt32>(count: keys.size)
            for (i in 0..keys.size) {
                keyArray.write(i, cstrs[i])
                sizeArray.write(i, UInt32(keys[i].toArray().size))
            }
            c_removeValuesForKeys(_handle, keyArray, sizeArray, UInt64(keys.size))

            for (cstr in cstrs) {
                LibC.free(cstr)
            }
            LibC.free(keyArray)
            LibC.free(sizeArray)
        }
    }

    /**
     * Clear all the key-values inside the MMKV instance.
     * The data file will be trimmed down to `pageSize`, and some sync operations will be called.
     *
     * @param keepSpace If you do not want to trim the file, pass true for better performance
     */
    public func clearAll(keepSpace!: Bool = false) {
        unsafe { c_clearAll(_handle, keepSpace) }
    }

    /**
     * Get the size of the underlying file. Align to the disk block size, typically 4K for an Android device.
     */
    public func totalSize(): UInt64 {
        unsafe { c_totalSize(_handle) }
    }

    /**
     * Get the actual used size of the MMKV instance.
     * This size might increase and decrease as MMKV doing insertion and full write back.
     */
    public func actualSize(): UInt64 {
        unsafe { c_actualSize(_handle) }
    }

    /**
     * Save all mmap memory to file.
     * You don't need to call this, really, I mean it.
     * Unless you worry about the device running out of battery.
     *
     * @param sync true for synchronously sync, false for asynchronously sync
     */
    public func sync(sync!: Bool = false): Unit {
        unsafe { c_mmkvSync(_handle, sync) }
    }

    /**
     * The {@link MMKV.totalSize()} of an MMKV instance won't reduce after deleting key-values,
     * call this method after lots of deleting if you care about disk usage.
     * Note that {@link MMKV.clearAll()}  has a similar effect.
     */
    public func trim(): Unit {
        unsafe { c_trim(_handle) }
    }

    /**
     * import all key-value items from src
     *
     * @returns count of items imported
     */
    public func importFrom(src: MMKV): UInt64 {
        unsafe { c_importFrom(_handle, src._handle) }
    }

    /**
     * Call this method if the MMKV instance is no longer needed in the near future.
     * Any subsequent call to any MMKV instances with the same ID is undefined behavior.
     */
    public func close(): Unit {
        unsafe { c_mmkvClose(_handle) }
    }

    /**
     * Clear memory cache of the MMKV instance.
     * You can call it on memory warning.
     * Any subsequent call to the MMKV instance will trigger all key-values loading from the file again.
     */
    public func clearMemoryCache(): Unit {
        unsafe { c_clearMemoryCache(_handle) }
    }

    /**
     * Get the actual size consumption of the key's value.
     * Note: might be a little bigger than value's length.
     *
     * @param key The key of the value.
     * @param actualSize true to get the actual size of the key's value. String's length or byte[]'s length, etc.
     */
    public func getValueSize(key: String, actualSize!: Bool = false): UInt32 {
        unsafe {
            let str = LibC.mallocCString(key)
            let res = c_valueSize(_handle, str, actualSize)
            LibC.free(str)
            res
        }
    }

    /**
     * remove the storage of the MMKV, including the data file & meta file (.crc)
     * Note: the existing instance (if any) will be closed & destroyed
     */
    public static func removeStorage(mmapID: String, rootPath!: ?String = None): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = match (rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let res = c_removeStorage(id, root)
            LibC.free(id)
            if (!root.isNull()) {
                LibC.free(root)
            }
            res
        }
    }

    /**
     * Check whether the MMKV file is valid or not on customize folder.
     *
     * @param mmapID   The unique ID of the MMKV instance.
     * @param rootPath The folder of the MMKV instance, defaults to $(FilesDir)/mmkv.
     */
    public static func isFileValid(mmapID: String, rootPath!: ?String = None): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = match (rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let res = c_isFileValid(id, root)
            LibC.free(id)
            if (!root.isNull()) {
                LibC.free(root)
            }
            res
        }
    }

    /**
     * @return The encryption key (no more than 16 bytes).
     */
    public prop cryptKey: ?String {
        get() {
            unsafe {
                let lengthPtr = LibC.malloc<UInt64>()
                let ret = c_cryptKey(_handle, lengthPtr)
                if (ret.isNull()) {
                    LibC.free(lengthPtr)
                    return None
                }

                let length = lengthPtr.read()
                LibC.free(lengthPtr)

                let res = String.fromUtf8(Array<Byte>(Int64(length), { i =>
                    CPointer<Byte>(ret).read(i)
                }))
                LibC.free(ret)
                res
            }
        }
    }

    /**
     * Transform plain text into encrypted text, or vice versa by passing a null encryption key.
     * You can also change existing crypt key with a different cryptKey.
     *
     * @param cryptKey The new encryption key (no more than 16 bytes).
     * @return true if success, otherwise false.
     */
    public func reKey(cryptKey!: ?String = None, aes256!: Bool = false): Bool {
        unsafe {
            if (let Some(key) <- cryptKey && !key.isEmpty()) {
                let str = LibC.mallocCString(key)
                let res = c_reKey(_handle, str, UInt64(key.toArray().size), aes256)
                LibC.free(str)
                res
            } else {
                c_reKey(_handle, CString(CPointer<UInt8>()), 0, false)
            }
        }
    }

    /**
     * Just reset the encryption key (will not encrypt or decrypt anything).
     * Usually you should call this method after another process has {@link MMKV.reKey(String)} the multi-process MMKV instance.
     *
     * @param cryptKey The new encryption key (no more than 16 bytes).
     */
    public func checkReSetCryptKey(
        cryptKey!: ?String = None,
        aes256!: Bool = false
    ) {
        unsafe {
            if (let Some(key) <- cryptKey && !key.isEmpty()) {
                let str = LibC.mallocCString(key)
                c_checkReSetCryptKey(_handle, str, UInt64(key.toArray().size), aes256)
                LibC.free(str)
            } else {
                c_checkReSetCryptKey(_handle, CString(CPointer<UInt8>()), 0, false)
            }
        }
    }

    /**
     * Get an backed-up MMKV instance.
     *
     * @param mmapID   The unique ID of the MMKV instance.
     * @param rootPath The backup folder of the MMKV instance.
     * @param mode     The process mode of the MMKV instance, defaults to {@link #SINGLE_PROCESS_MODE}.
     * @param cryptKey The encryption key of the MMKV instance (no more than 16 bytes).
     */
    public static func backedUpMMKVWithID(
        mmapID: String,
        rootPath: String,
        mode!: ?Int32 = None,
        cryptKey!: ?String = None
    ): MMKV {
        if (_rootDir.isEmpty()) {
            throw IllegalStateException("You should Call MMKV.initialize() first.")
        }
        let realMode = (mode ?? SINGLE_PROCESS_MODE) | BACKUP_MODE
        mmkvWithID(
            mmapID,
            mode: realMode,
            cryptKey: cryptKey,
            rootPath: rootPath
        )
    }

    /**
     * backup one MMKV instance to dstDir
     *
     * @param mmapID   the MMKV ID to backup
     * @param dstDir   the backup destination directory
     * @param rootPath the customize root path of the MMKV, if null then backup from the root dir of MMKV
     */
    public static func backupOneToDirectory(
        mmapID: String,
        dstDir: String,
        rootPath!: ?String = None
    ): Bool {
        unsafe {
            if (_rootDir.isEmpty()) {
                throw IllegalStateException("You should Call MMKV.initialize() first.")
            }
            let id = LibC.mallocCString(mmapID)
            let dir = LibC.mallocCString(dstDir)
            let root = match (rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let res = c_backupOne(id, dir, root)
            LibC.free(id)
            LibC.free(dir)
            if (!root.isNull()) {
                LibC.free(root)
            }
            res
        }
    }

    /**
     * restore one MMKV instance from srcDir
     *
     * @param mmapID   the MMKV ID to restore
     * @param srcDir   the restore source directory
     * @param rootPath the customize root path of the MMKV, if null then restore to the root dir of MMKV
     */
    public static func restoreOneFromDirectory(
        mmapID: String,
        srcDir: String,
        rootPath!: ?String = None
    ): Bool {
        unsafe {
            if (_rootDir.isEmpty()) {
                throw IllegalStateException("You should Call MMKV.initialize() first.")
            }
            let id = LibC.mallocCString(mmapID)
            let dir = LibC.mallocCString(srcDir)
            let root = match (rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let res = c_restoreOne(id, dir, root)
            LibC.free(id)
            LibC.free(dir)
            if (!root.isNull()) {
                LibC.free(root)
            }
            res
        }
    }

    /**
     * backup all MMKV instance to dstDir
     *
     * @param dstDir the backup destination directory
     * @return count of MMKV successfully backup
     */
    public static func backupAllToDirectory(dstDir: String): UInt64 {
        unsafe {
            if (_rootDir.isEmpty()) {
                throw IllegalStateException("You should Call MMKV.initialize() first.")
            }
            let dir = LibC.mallocCString(dstDir)
            let res = c_backupAll(dir)
            LibC.free(dir)
            res
        }
    }

    /**
     * restore all MMKV instance from srcDir
     *
     * @param srcDir the restore source directory
     * @return count of MMKV successfully restored
     */
    public static func restoreAllFromDirectory(srcDir: String): UInt64 {
        unsafe {
            if (_rootDir.isEmpty()) {
                throw IllegalStateException("You should Call MMKV.initialize() first.")
            }
            let dir = LibC.mallocCString(srcDir)
            let res = c_restoreAll(dir)
            LibC.free(dir)
            res
        }
    }

    /**
     * Enable auto key expiration. This is a upgrade operation, the file format will change.
     * And the file won't be accessed correctly by older version (v1.2.16) of MMKV.
     * NOTICE: enableCompareBeforeSet will be invalid when Expiration is on
     *
     * @param expireDurationInSecond the expire duration for all keys, {@link MMKV.ExpireNever} (0) means no default duration
     * (aka each key will have it's own expire date)
     */
    public func enableAutoKeyExpire(expireDurationInSecond: UInt32): Bool {
        unsafe { c_enableAutoExpire(_handle, expireDurationInSecond) }
    }

    /**
     * Disable auto key expiration. This is a downgrade operation.
     */
    public func disableAutoKeyExpire(): Bool {
        unsafe { c_disableAutoExpire(_handle) }
    }

    /**
     * Enable data compare before set, for better performance.
     * If data for key seldom changes, use it.
     * When encryption or expiration is on, compare-before-set will be invalid.
     * For encryption, compare operation must decrypt data which is time consuming.
     * For expiration, compare is useless because in most cases the expiration time changes every time.
     */
    public func enableCompareBeforeSet(): Unit {
        unsafe { c_enableCompareBeforeSet(_handle) }
    }

    /**
     * Disable data compare before set
     * disabled at default
     */
    public func disableCompareBeforeSet(): Unit {
        unsafe { c_disableCompareBeforeSet(_handle) }
    }

    public func isMultiProcess(): Bool {
        unsafe { c_isMultiProcess(_handle) }
    }

    public func isReadOnly(): Bool {
        unsafe { c_isReadOnly(_handle) }
    }

    public func checkContentChanged(): Unit {
        unsafe { c_checkContentChanged(_handle) }
    }

    public static func checkExist(mmapID: String, rootPath!: ?String = None): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = match (rootPath) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let res = c_checkExist(id, root)
            LibC.free(id)
            if (!root.isNull()) {
                LibC.free(root)
            }
            res
        }
    }
}

/**
 * A wrapper for customize root path.
 */
public class NameSpace {
    private let _rootDir: String

    init(rootDir: String) {
        _rootDir = rootDir
    }

    /**
     * @returns The root folder of NameSpace.
     */
    public prop rootDir: String {
        get() {
            _rootDir
        }
    }

    /**
     * Create an MMKV instance on customize folder.
     *
     * @param mmapID The unique ID of the MMKV instance.
     * @param mode The process mode of the MMKV instance, defaults to {@link MMKV.SINGLE_PROCESS_MODE}.
     * @param cryptKey The encryption key of the MMKV instance (no more than 16 bytes).
     * @param expectedCapacity The file size you expected when opening or creating file.
     * @returns The MMKV instance.
     */
    public func mmkvWithID(
        mmapID: String,
        mode!: Int32 = MMKV.SINGLE_PROCESS_MODE,
        cryptKey!: ?String = None,
        expectedCapacity!: UIntNative = 0,
        aes256!: Bool = false
    ): MMKV {
        mmkvWithConfig(
            mmapID,
            MMKVConfig(
                mode: mode,
                cryptKey: cryptKey,
                expectedCapacity: expectedCapacity,
                aes256: aes256
            )
        )
    }

    /**
     * Creat an MMKV instance with all-in-one configuration
     *
     * @param mmapID The unique ID of the MMKV instance.
     * @param config The all-in-one configuration.
     * @returns The MMKV instance.
     */
    public func mmkvWithConfig(mmapID: String, config: MMKVConfig): MMKV {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let cryptKey = match (config.cryptKey) {
            	case Some(s) => LibC.mallocCString(s)
            	case _ => CString(CPointer<UInt8>())
            }
            let rootPath = LibC.mallocCString(_rootDir)
            let enableKeyExpire: Int32 = match (config.enableKeyExpire) {
                case Some(v) => if (v) { 1 } else { 0 }
                case _ => -1
            }
            let recover = config.recover ?? -1
            let handle = c_getMMKVWithID(
                id,
                config.mode,
                cryptKey,
                rootPath,
                config.expectedCapacity,
                true,
                config.aes256,
                enableKeyExpire,
                config.expiredInSeconds,
                config.enableCompareBeforeSet,
                recover,
                config.itemSizeLimit
            )
            LibC.free(id)
            if (!cryptKey.isNull()) {
                LibC.free(cryptKey)
            }
            if (!rootPath.isNull()) {
                LibC.free(rootPath)
            }
            if (handle.isNull()) {
                throw IllegalStateException("Fail to create an MMKV instance [${mmapID}] in NAPI.")
            }
            MMKV(handle)
        }
    }

    /**
     * remove the storage of the MMKV, including the data file & meta file (.crc)
     * Note: the existing instance (if any) will be closed & destroyed
     */
    public func removeStorage(mmapID: String): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = LibC.mallocCString(_rootDir)
            let res = c_removeStorage(id, root)
            LibC.free(id)
            LibC.free(root)
            res
        }
    }

    /**
     * Check whether the MMKV file is valid or not on customize folder.
     *
     * @param mmapID   The unique ID of the MMKV instance.
     */
    public func isFileValid(mmapID: String): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = LibC.mallocCString(_rootDir)
            let res = c_isFileValid(id, root)
            LibC.free(id)
            LibC.free(root)
            res
        }
    }

    /**
     * backup one MMKV instance the customize root path to dstDir
     *
     * @param mmapID   the MMKV ID to backup
     * @param dstDir   the backup destination directory
     */
    public func backupOneToDirectory(mmapID: String, dstDir: String): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let dir = LibC.mallocCString(dstDir)
            let root = LibC.mallocCString(_rootDir)
            let res = c_backupOne(id, dir, root)
            LibC.free(id)
            LibC.free(dir)
            LibC.free(root)
            res
        }
    }

    /**
     * restore one MMKV instance from srcDir to the customize root path
     *
     * @param mmapID   the MMKV ID to restore
     * @param srcDir   the restore source directory
     */
    public func restoreOneFromDirectory(mmapID: String, srcDir: String): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let dir = LibC.mallocCString(srcDir)
            let root = LibC.mallocCString(_rootDir)
            let res = c_restoreOne(id, dir, root)
            LibC.free(id)
            LibC.free(dir)
            LibC.free(root)
            res
        }
    }

    /**
     * Check the existence of the MMKV file.
     *
     * @param mmapID   The unique ID of the MMKV instance.
     */
    public func checkExist(mmapID: String): Bool {
        unsafe {
            let id = LibC.mallocCString(mmapID)
            let root = LibC.mallocCString(_rootDir)
            let res = c_checkExist(id, root)
            LibC.free(id)
            LibC.free(root)
            res
        }
    }
}
