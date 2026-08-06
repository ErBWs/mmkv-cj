/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv_test

import std.unittest.TestClass
import std.unittest.TestPackage
import std.unittest.TestSuite
import std.unittest.UnitTestCase
import std.unittest.common.Configuration
import std.unittest.testmacro.Test
import std.unittest.testmacro.TestCase

@Test
class MMKVTest {
    @TestCase
    func functionalRoundTripAndLifecycle(): Unit {
        testFunctionalRoundTripAndLifecycle()
    }

    @TestCase
    func reKey(): Unit {
        testReKey()
    }

    @TestCase
    func importWithExpiration(): Unit {
        testImportWithExpiration()
    }

    @TestCase
    func backupAndRestore(): Unit {
        testBackupAndRestore()
    }

    @TestCase
    func autoExpiration(): Unit {
        testAutoExpiration()
    }

    @TestCase
    func compareBeforeSet(): Unit {
        testCompareBeforeSet()
    }

    @TestCase
    func readOnlyMode(): Unit {
        testReadOnlyMode()
    }
}
