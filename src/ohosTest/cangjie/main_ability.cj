/**
 * Copyright (C) 2026. Bao Han <erbws@qq.com>
 */

package ohos_app_cangjie_mmkv_test

import ohos.ability.Want
import ohos.ability.UIAbility
import ohos.ability.LaunchParam
import ohos_app_cangjie_mmkv.MMKV

class MainAbility <: UIAbility {
    public init() {
        super()
        registerSelf()
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        MMKV.initialize(context.getApplicationContext())
    }
}
