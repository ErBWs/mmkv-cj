/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv

import std.sync.Mutex
import kit.PerformanceAnalysisKit.Hilog
import ohos_app_cangjie_mmkv.native as native

/**
 * The recover strategic of MMKV on errors.
 */
public type MMKVRecoverStrategic = Int32
/**
 * The default strategic is to discard everything on errors.
 */
public let OnErrorDiscard: MMKVRecoverStrategic = 0
/**
 * The recover strategic will try to recover as much data as possible.
 */
public let OnErrorRecover: MMKVRecoverStrategic = 1

/**
 * Callback handler for MMKV.
 * Callback is called on the operating thread of the MMKV instance.
 */
public abstract class MMKVHandler {
    /**
     * @return Return true if you want log redirecting.
     */
    public open func wantLogRedirect(): Bool { false }

    /**
     * Log Redirecting.
     * @param level The level of this log.
     * @param file The file name of this log.
     * @param line The line of code of this log.
     * @param function The function name of this log.
     * @param message The content of this log.
     */
    public open func mmkvLog(
        level: MMKVLogLevel,
        file: String,
        line: Int32,
        funcname: String,
        message: String
    ) {}

    /**
     * By default MMKV will discard all data on crc32-check failure. {@link MMKVRecoverStrategic#OnErrorDiscard}
     * @param mmapID The unique ID of the MMKV instance.
     * @return Return {@link MMKVRecoverStrategic#OnErrorRecover} to recover any data on the file.
     */
    public open func onMMKVCRCCheckFail(mmapID: String): MMKVRecoverStrategic { OnErrorDiscard }

    /**
     * By default MMKV will discard all data on file length mismatch. {@link MMKVRecoverStrategic#OnErrorDiscard}
     * @param mmapID The unique ID of the MMKV instance.
     * @return Return {@link MMKVRecoverStrategic#OnErrorRecover} to recover any data on the file.
     */
    public open func onMMKVFileLengthError(mmapID: String): MMKVRecoverStrategic { OnErrorDiscard }

    /**
     * @return Return true to enable inter-process content change notification
     */
    public open func wantContentChangeNotification(): Bool { false }

    /**
     * Inter-process content change notification.
     * Triggered by any method call, such as getXXX() or setXXX() or {@link MMKV#checkContentChangedByOuterProcess()}.
     * @param mmapID The unique ID of the changed MMKV instance.
     */
    public open func onContentChangedByOuterProcess(mmapID: String) {}

    /**
     * Called when an MMKV file is loaded successfully.
     * @param mmapID The unique ID of the loaded MMKV instance.
     */
    public open func onMMKVContentLoadSuccessfully(mmapID: String) {}
}

private var handler: ?MMKVHandler = None
private let mtx = Mutex()

func setHandler(val: ?MMKVHandler) {
    synchronized(mtx) {
	    handler = val
    }
}

private func getHandler(): ?MMKVHandler {
    synchronized(mtx) {
	    return handler
    }
}

@C
func defaultLogCallback(
    level: UInt32,
    file: CString,
    line: Int32,
    funcname: CString,
    message: CString
): Unit {
    let log = "<${file}:${line}::${funcname}> ${message}"
    match (level) {
        case 0 => Hilog.debug(0, "mmkv", log)
        case 1 => Hilog.info(0, "mmkv", log)
        case 2 => Hilog.warn(0, "mmkv", log)
        case 3 => Hilog.error(0, "mmkv", log)
        case _ => ()
    }
}

@C
func logCallback(
    level: UInt32,
    file: CString,
    line: Int32,
    funcname: CString,
    message: CString
): Unit {
    if (let Some(handler) <- getHandler()) {
        handler.mmkvLog(Int32(level), file.toString(), line, funcname.toString(), message.toString())
    }
}

func registerCallbacks(): Unit {
    unsafe {
        if (let Some(value) <- getHandler()) {
            native.c_registerErrorHandler(errorCallback)
            if (value.wantContentChangeNotification()) {
                native.c_registerContentChangeNotify(contentChangeCallback)
                native.c_registerContentLoadedNotify(contentLoadCallback)
            }
        }
    }
}

@C
private func errorCallback(mmapID: CString, errorType: Int32): Int32 {
    if (let Some(handler) <- getHandler()) {
        let strategy = if (errorType == 0) {
            handler.onMMKVCRCCheckFail(mmapID.toString())
        } else {
            handler.onMMKVFileLengthError(mmapID.toString())
        }
        return strategy
    }
    return 0
}

@C
private func contentChangeCallback(mmapID: CString): Unit {
    if (let Some(handler) <- getHandler()) {
        handler.onContentChangedByOuterProcess(mmapID.toString())
    }
}

@C
private func contentLoadCallback(mmapID: CString): Unit {
    if (let Some(handler) <- getHandler()) {
        handler.onContentChangedByOuterProcess(mmapID.toString())
    }
}
