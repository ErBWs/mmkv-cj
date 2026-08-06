/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv_test

import kit.IPCKit.MessageSequence
import kit.IPCKit.Parcelable
import ohos_app_cangjie_mmkv.*
import std.unittest.expectEqual
import std.unittest.testmacro.Expect

private class TestParcelable <: Parcelable {
    var number: Int32
    var text: String

    init(number: Int32, text: String) {
        this.number = number
        this.text = text
    }

    public func marshalling(sequence: MessageSequence): Bool {
        sequence.writeInt(number)
        sequence.writeString(text)
        true
    }

    public func unmarshalling(sequence: MessageSequence): Bool {
        number = sequence.readInt()
        text = sequence.readString()
        true
    }
}

private func freshMMKV(mmapID: String, mode!: Int32 = MMKV.SINGLE_PROCESS_MODE): MMKV {
    MMKV.removeStorage(mmapID)
    let kv = MMKV.mmkvWithID(mmapID, mode: mode)
    kv.clearAll()
    kv
}

func testFunctionalRoundTripAndLifecycle(): Unit {
    let mmapID = "mmkv_cj_functional_test"
    let cryptKey = "encrypt_key"
    MMKV.removeStorage(mmapID)
    let kv = MMKV.mmkvWithID(
        mmapID,
        mode: MMKV.MULTI_PROCESS_MODE,
        cryptKey: cryptKey
    )
    kv.clearAll()

    @Expect(kv.mmapID, mmapID)
    @Expect(kv.isMultiProcess())
    @Expect(!kv.isReadOnly())
    @Expect((kv.cryptKey ?? ""), cryptKey)
    @Expect(kv.encode("bool", true))
    @Expect(kv.decodeBool("bool"))
    @Expect(!kv.decodeBool("non-bool"))
    @Expect(kv.decodeBool("non-bool", defaultValue: true))

    let int32Max: Int32 = 2147483647
    let int32Min: Int32 = -int32Max - 1
    @Expect(kv.encode("int32", int32Max))
    @Expect(kv.decodeInt32("int32"), int32Max)
    @Expect(kv.encode("int32", int32Min))
    @Expect(kv.decodeInt32("int32"), int32Min)
    @Expect(kv.decodeInt32("non-int32", defaultValue: Int32(7)), Int32(7))

    let int64Max: Int64 = 9223372036854775807
    let int64Min: Int64 = -int64Max - 1
    @Expect(kv.encode("int64", int64Max))
    @Expect(kv.decodeInt64("int64"), int64Max)
    @Expect(kv.encode("int64", int64Min))
    @Expect(kv.decodeInt64("int64"), int64Min)
    @Expect(kv.decodeInt64("non-int64", defaultValue: Int64(9)), Int64(9))

    let float64Max: Float64 = 1.7976931348623157e308
    let float64Min: Float64 = 5.0e-324
    @Expect(kv.encode("float64", float64Max))
    @Expect(kv.decodeFloat64("float64"), float64Max)
    @Expect(kv.encode("float64", float64Min))
    @Expect(kv.decodeFloat64("float64"), float64Min)
    @Expect(kv.decodeFloat64("non-float64", defaultValue: 2.5), 2.5)

    let text = "Hello world to OpenHarmony!"
    @Expect(kv.encode("string", text))
    @Expect(kv.decodeString("string"), text)
    let json = "{\"courseId\":39575,\"name\":\"通识课测试2\",\"status\":1}"
    @Expect(kv.encode("json", json))
    @Expect(kv.decodeString("json"), json)
    @Expect(kv.decodeString("non-string", defaultValue: "default_value"), "default_value")

    let bytes = "This is a string 转换成 a Uint8Array 💯".toArray()
    @Expect(kv.encode("bytes", bytes))
    @Expect(kv.decodeBytes("bytes"), bytes)
    @Expect(kv.getValueSize("bytes", actualSize: true), UInt32(bytes.size))
    @Expect(kv.containsKey("bytes"))
    @Expect(!kv.containsKey("bytes-not-exist"))

    let keys = kv.allKeys()
    @Expect(keys.contains("bool"))
    @Expect(keys.contains("int32"))
    @Expect(keys.contains("int64"))
    @Expect(keys.contains("float64"))
    @Expect(keys.contains("string"))
    @Expect(keys.contains("json"))
    @Expect(keys.contains("bytes"))
    @Expect(kv.totalSize() > UInt64(0))
    @Expect(kv.actualSize() > UInt64(0))

    kv.removeValueForKey("bytes")
    @Expect(!kv.containsKey("bytes"))
    kv.removeValuesForKeys(["bool", "int32"])
    @Expect(!kv.containsKey("bool"))
    @Expect(!kv.containsKey("int32"))

    kv.trim()
    kv.sync(sync: true)
    kv.clearMemoryCache()
    @Expect(kv.decodeString("string"), text)
    kv.checkContentChanged()
    kv.clearAll()
    @Expect(kv.count(), UInt64(0))

    kv.close()
    @Expect(MMKV.isFileValid(mmapID))
    @Expect(MMKV.checkExist(mmapID))
    @Expect(MMKV.removeStorage(mmapID))
    @Expect(!MMKV.checkExist(mmapID))
}

func testReKey(): Unit {
    let mmapID = "mmkv_cj_rekey_test"
    let firstKey = "Key_seq_1"
    let aes256Key = "Key_Seq_Very_Looooooooong"
    MMKV.removeStorage(mmapID)
    let kv = MMKV.mmkvWithID(mmapID)
    kv.clearAll()
    @Expect(kv.encode("bool", true))
    @Expect(kv.encode("int32", Int32(-2147483647)))
    @Expect(kv.encode("string", "reKey keeps stored values"))

    @Expect(kv.reKey(cryptKey: firstKey))
    kv.clearMemoryCache()
    @Expect((kv.cryptKey ?? ""), firstKey)
    @Expect(kv.decodeBool("bool"))
    @Expect(kv.decodeInt32("int32"), Int32(-2147483647))
    @Expect(kv.decodeString("string"), "reKey keeps stored values")

    @Expect(kv.reKey(cryptKey: aes256Key, aes256: true))
    kv.clearMemoryCache()
    @Expect((kv.cryptKey ?? ""), aes256Key)
    @Expect(kv.decodeBool("bool"))
    @Expect(kv.decodeString("string"), "reKey keeps stored values")

    @Expect(kv.reKey())
    kv.clearMemoryCache()
    @Expect(match (kv.cryptKey) {
        case None => true
        case _ => false
    })
    @Expect(kv.decodeBool("bool"))
    @Expect(kv.decodeString("string"), "reKey keeps stored values")

    kv.close()
    @Expect(MMKV.removeStorage(mmapID))
}

func testImportWithExpiration(): Unit {
    let sourceID = "mmkv_cj_import_source_test"
    let destinationID = "mmkv_cj_import_destination_test"
    let source = freshMMKV(sourceID)
    MMKV.removeStorage(destinationID)
    let destination = MMKV.mmkvWithConfig(
        destinationID,
        MMKVConfig(enableKeyExpire: true, expiredInSeconds: 1)
    )
    destination.clearAll()

    let int32Min: Int32 = -2147483647 - 1
    let int64Max: Int64 = 9223372036854775807
    @Expect(source.encode("bool", true))
    @Expect(source.encode("int32", int32Min))
    @Expect(source.encode("int64", int64Max))
    @Expect(source.encode("string", "test import"))

    @Expect(destination.encode("bool", false))
    @Expect(destination.encode("int32", Int32(-1)))
    @Expect(destination.encode("int64", Int64(0)))
    @Expect(destination.encode("string", sourceID))
    @Expect(destination.importFrom(source), UInt64(4))
    @Expect(destination.count(), UInt64(4))
    @Expect(destination.decodeBool("bool"))
    @Expect(destination.decodeInt32("int32"), int32Min)
    @Expect(destination.decodeInt64("int64"), int64Max)
    @Expect(destination.decodeString("string"), "test import")

    sleep(Duration.second * 2)
    @Expect(destination.count(filterExpire: true), UInt64(0))

    source.close()
    destination.close()
    @Expect(MMKV.removeStorage(sourceID))
    @Expect(MMKV.removeStorage(destinationID))
}

func testBackupAndRestore(): Unit {
    let mmapID = "mmkv_cj_backup_test"
    let backupDir = MMKV.rootDir + "_single_backup"
    MMKV.removeStorage(mmapID)
    MMKV.removeStorage(mmapID, rootPath: backupDir)

    let original = MMKV.mmkvWithID(mmapID)
    original.clearAll()
    @Expect(original.encode("value", "before backup"))
    original.sync(sync: true)
    original.close()

    @Expect(MMKV.backupOneToDirectory(mmapID, backupDir))
    let backup = MMKV.backedUpMMKVWithID(mmapID, backupDir)
    @Expect(backup.decodeString("value"), "before backup")
    backup.close()

    let changed = MMKV.mmkvWithID(mmapID)
    @Expect(changed.encode("value", "after backup"))
    changed.sync(sync: true)
    changed.close()
    @Expect(MMKV.restoreOneFromDirectory(mmapID, backupDir))

    let restored = MMKV.mmkvWithID(mmapID)
    @Expect(restored.decodeString("value"), "before backup")
    restored.close()
    @Expect(MMKV.removeStorage(mmapID))
    @Expect(MMKV.removeStorage(mmapID, rootPath: backupDir))

    let firstID = "mmkv_cj_backup_all_first"
    let secondID = "mmkv_cj_backup_all_second"
    let allBackupDir = MMKV.rootDir + "_all_backup"
    MMKV.removeStorage(firstID)
    MMKV.removeStorage(secondID)
    MMKV.removeStorage(firstID, rootPath: allBackupDir)
    MMKV.removeStorage(secondID, rootPath: allBackupDir)
    let first = MMKV.mmkvWithID(firstID)
    let second = MMKV.mmkvWithID(secondID)
    @Expect(first.encode("value", Int32(1)))
    @Expect(second.encode("value", Int32(2)))
    first.sync(sync: true)
    second.sync(sync: true)
    first.close()
    second.close()

    @Expect(MMKV.backupAllToDirectory(allBackupDir) >= UInt64(2))
    @Expect(MMKV.removeStorage(firstID))
    @Expect(MMKV.removeStorage(secondID))
    @Expect(MMKV.restoreAllFromDirectory(allBackupDir) >= UInt64(2))
    let restoredFirst = MMKV.mmkvWithID(firstID)
    let restoredSecond = MMKV.mmkvWithID(secondID)
    @Expect(restoredFirst.decodeInt32("value"), Int32(1))
    @Expect(restoredSecond.decodeInt32("value"), Int32(2))
    restoredFirst.close()
    restoredSecond.close()
    @Expect(MMKV.removeStorage(firstID))
    @Expect(MMKV.removeStorage(secondID))
    @Expect(MMKV.removeStorage(firstID, rootPath: allBackupDir))
    @Expect(MMKV.removeStorage(secondID, rootPath: allBackupDir))
}

func testAutoExpiration(): Unit {
    let mmapID = "mmkv_cj_auto_expire_test"
    MMKV.removeStorage(mmapID)
    let kv = MMKV.mmkvWithConfig(
        mmapID,
        MMKVConfig(enableKeyExpire: true, expiredInSeconds: 1)
    )
    kv.clearAll()

    @Expect(kv.encode("auto-bool", true))
    @Expect(kv.encode("int32", Int32(2147483647), expiration: 1))
    @Expect(kv.encode("int64", Int64(9223372036854775807), expiration: 1))
    @Expect(kv.encode("float64", 1.7976931348623157e308, expiration: 1))
    @Expect(kv.encode("string", "expires", expiration: 1))
    @Expect(kv.encode("bytes", "expires too".toArray(), expiration: 1))
    @Expect(kv.encode("never", true, expiration: MMKV.ExpireNever))

    sleep(Duration.second * 2)
    @Expect(!kv.containsKey("auto-bool"))
    @Expect(!kv.containsKey("int32"))
    @Expect(!kv.containsKey("int64"))
    @Expect(!kv.containsKey("float64"))
    @Expect(!kv.containsKey("string"))
    @Expect(!kv.containsKey("bytes"))
    @Expect(kv.containsKey("never"))
    @Expect(kv.count(filterExpire: true), UInt64(1))
    @Expect(kv.allKeys(filterExpire: true).contains("never"))

    @Expect(kv.disableAutoKeyExpire())
    @Expect(kv.encode("after-disable", "persistent"))
    sleep(Duration.second * 2)
    @Expect(kv.decodeString("after-disable"), "persistent")

    kv.close()
    @Expect(MMKV.removeStorage(mmapID))
}

func testCompareBeforeSet(): Unit {
    let mmapID = "mmkv_cj_compare_before_set_test"
    let kv = freshMMKV(mmapID)
    kv.enableCompareBeforeSet()

    let intValue: Int32 = 12345
    @Expect(kv.encode("int", intValue))
    let intSize = kv.actualSize()
    @Expect(kv.encode("int", intValue))
    @Expect(kv.actualSize(), intSize)
    @Expect(kv.encode("int", intValue * 23))
    @Expect(kv.decodeInt32("int"), intValue * 23)

    let stringValue = "w012A🏊🏻good"
    @Expect(kv.encode("string", stringValue))
    let stringSize = kv.actualSize()
    @Expect(kv.encode("string", stringValue))
    @Expect(kv.actualSize(), stringSize)
    @Expect(kv.encode("string", "temp data 👩🏻‍🏫"))
    @Expect(kv.decodeString("string"), "temp data 👩🏻‍🏫")

    kv.disableCompareBeforeSet()
    kv.close()
    @Expect(MMKV.removeStorage(mmapID))
}

func testReadOnlyMode(): Unit {
    let mmapID = "mmkv_cj_read_only_test"
    let cryptKey = "ReadOnly+Key"
    MMKV.removeStorage(mmapID)
    let writable = MMKV.mmkvWithID(mmapID, cryptKey: cryptKey)
    writable.clearAll()
    @Expect(writable.encode("bool", true))
    @Expect(writable.encode("int32", Int32(-2147483647)))
    @Expect(writable.encode("string", "read-only value"))
    writable.sync(sync: true)
    writable.close()

    let readOnly = MMKV.mmkvWithID(
        mmapID,
        mode: MMKV.SINGLE_PROCESS_MODE | MMKV.READ_ONLY_MODE,
        cryptKey: cryptKey
    )
    @Expect(readOnly.isReadOnly())
    @Expect(readOnly.decodeBool("bool"))
    @Expect(readOnly.decodeInt32("int32"), Int32(-2147483647))
    @Expect(readOnly.decodeString("string"), "read-only value")
    @Expect(!readOnly.encode("blocked-write", "value"))
    @Expect(!readOnly.containsKey("blocked-write"))

    readOnly.close()
    @Expect(MMKV.removeStorage(mmapID))
}
