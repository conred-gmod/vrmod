if SERVER then return end
local ply = LocalPlayer()
-- VRアクションからキーコードへのマッピング
local vrToKeyMap = {
    ["boolean_primaryfire"] = KEY_LSHIFT,
    ["boolean_secondaryfire"] = KEY_RSHIFT,
    ["boolean_forword"] = KEY_UP,
    ["boolean_back"] = KEY_DOWN,
    ["boolean_left"] = KEY_LEFT,
    ["boolean_right"] = KEY_RIGHT,
    ["boolean_use"] = KEY_E,
    ["boolean_reload"] = KEY_R,
    ["boolean_jump"] = KEY_SPACE,
    ["boolean_sprint"] = KEY_LSHIFT,
    ["boolean_duck"] = KEY_LCONTROL,
    ["boolean_flashlight"] = KEY_F,
    ["boolean_undo"] = KEY_Z,
    ["boolean_spawnmenu"] = KEY_Q,
    ["boolean_chat"] = KEY_Y,
    ["boolean_walkkey"] = KEY_LALT,
    ["boolean_menucontext"] = KEY_C,
    ["boolean_slot1"] = KEY_1,
    ["boolean_slot2"] = KEY_2,
    ["boolean_slot3"] = KEY_3,
    ["boolean_slot4"] = KEY_4,
    ["boolean_slot5"] = KEY_5,
    ["boolean_slot6"] = KEY_6,
    ["boolean_invnext"] = KEY_RBRACKET,
    ["boolean_invprev"] = KEY_LBRACKET
}

-- VRの入力状態を追跡
local VRKeyStates = {}
-- キーイベントをシミュレートする関数
local function SimulateKeyPress(keyCode, pressed)
    if not keyCode then return end
    -- キー状態を保存
    VRKeyStates[keyCode] = pressed
    -- PlayerButtonDown/Upイベントを発火
    hook.Run(pressed and "PlayerButtonDown" or "PlayerButtonUp", LocalPlayer(), keyCode)
    -- KeyPress/Releaseイベントも発火
    hook.Run(pressed and "KeyPress" or "KeyRelease", LocalPlayer(), keyCode)
end

-- input.IsKeyDown をオーバーライド
local original_IsKeyDown = input.IsKeyDown
function input.IsKeyDown(key)
    if VRKeyStates[key] == true then return true end

    return original_IsKeyDown(key)
end

hook.Add(
    "VRMod_Input",
    "vrutil_keypress_sim",
    function(action, pressed)
        if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
        -- キーマッピングに従ってシミュレート
        local mappedKey = vrToKeyMap[action]
        if mappedKey then
            SimulateKeyPress(mappedKey, pressed)
        end
    end
)

-- VRの入力状態の変化を検出してクリアするためのThinkフック
hook.Add(
    "Think",
    "vrmod_key_simulation",
    function()
        if not g_VR or not g_VR.active then return end
        -- 入力アクションの変更を検出して処理
        for action, keyCode in pairs(vrToKeyMap) do
            if g_VR.changedInputs and g_VR.changedInputs[action] ~= nil then
                local isPressed = g_VR.input[action] and true or false
                -- キー状態を更新する前にここで追加の処理が必要な場合
                -- たとえば、デバッグ情報の表示などを行う場合はここに追加
            end
        end

        -- 1秒に1回、使われていないキー状態をクリア（メモリリーク防止）
        if not VRKeyStates._lastCleanup or VRKeyStates._lastCleanup < CurTime() - 1 then
            VRKeyStates._lastCleanup = CurTime()
            for key, state in pairs(VRKeyStates) do
                if type(key) == "number" and not vrToKeyMap[key] then
                    -- 10秒以上前から状態が変わっていないキーはクリア
                    if state._lastChanged and state._lastChanged < CurTime() - 10 then
                        VRKeyStates[key] = nil
                    end
                end
            end
        end
    end
)