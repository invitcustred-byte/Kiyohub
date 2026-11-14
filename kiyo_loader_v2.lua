-- Kiyo Hub | Loader v2 | Dev: Fartzy
-- Pakai endpoint Cloudflare Worker (ganti URL setelah deploy)
local _G_ENV = typeof(getgenv)=="function" and getgenv() or _G

-- ── GANTI URL INI setelah deploy Cloudflare Worker ──
-- Format: https://YOUR_WORKER.YOUR_SUBDOMAIN.workers.dev
local BASE_URL   = ""
local SCRIPT_EP  = BASE_URL .. "/s"   -- endpoint script
local KEY_EP     = BASE_URL .. "/k"   -- endpoint key list

-- ── HWID Generator ──
local function GetHWID()
    local plr = game:GetService("Players").LocalPlayer
    local raw = tostring(plr.UserId)..tostring(game.PlaceId)..tostring(game.JobId):sub(1,8)
    local h = 0
    for i=1,#raw do
        h = bit32.bxor(h*31+string.byte(raw,i), 0xDEADBEEF) % 0xFFFFFFFF
    end
    return string.format("KIYO-%08X-%s", h, tostring(plr.UserId))
end

-- ── Key Storage ──
local KF = "KiyoHub_Keys"
local KT = KF.."/key.txt"

local function LoadKey()
    local ok,data = pcall(function()
        if isfile(KT) then return readfile(KT) end
    end)
    if ok and data then
        local k,hid,ts = data:match("^(.+)|(.+)|(%d+)$")
        return k, hid, tonumber(ts)
    end
end

local function SaveKey(k, hid)
    pcall(function()
        if not isfolder(KF) then makefolder(KF) end
        writefile(KT, k.."|"..hid.."|"..tostring(os.time()))
    end)
end

-- ── Lootlabs Link Rotator (ganti dengan link milik darling) ──
local LINKS = {
    "https://lootlabs.gg/land/YOUR_LINK_1",
    "https://lootlabs.gg/land/YOUR_LINK_2",
    "https://lootlabs.gg/land/YOUR_LINK_3",
}
local function GetLink(hid)
    local n=0
    for i=1,#hid do n=(n+string.byte(hid,i))%#LINKS end
    return LINKS[n+1]
end

-- ── Key UI ──
local function ShowUI(hid, cb)
    local gp = pcall(gethui) and gethui() or game:GetService("CoreGui")
    local old = gp:FindFirstChild("KiyoKeyUI")
    if old then old:Destroy() end

    local sg=Instance.new("ScreenGui");sg.Name="KiyoKeyUI"
    sg.ResetOnSpawn=false;sg.IgnoreGuiInset=true;sg.DisplayOrder=9999
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;sg.Parent=gp

    local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1)
    bg.BackgroundColor3=Color3.fromRGB(0,0,0);bg.BackgroundTransparency=0.5;bg.Parent=sg

    local p=Instance.new("Frame");p.Size=UDim2.fromOffset(340,230)
    p.Position=UDim2.new(0.5,-170,0.5,-115)
    p.BackgroundColor3=Color3.fromRGB(12,12,16);p.Parent=sg
    Instance.new("UICorner",p).CornerRadius=UDim.new(0,14)
    local sk=Instance.new("UIStroke",p);sk.Color=Color3.fromRGB(90,50,220);sk.Thickness=1.5

    -- Title
    local tl=Instance.new("TextLabel");tl.Size=UDim2.new(1,0,0,32)
    tl.Position=UDim2.fromOffset(0,12);tl.BackgroundTransparency=1
    tl.Font=Enum.Font.GothamBold;tl.TextSize=17
    tl.TextColor3=Color3.fromRGB(255,255,255);tl.Text="Kiyo Hub";tl.Parent=p

    local dl=Instance.new("TextLabel");dl.Size=UDim2.new(1,0,0,14)
    dl.Position=UDim2.fromOffset(0,44);dl.BackgroundTransparency=1
    dl.Font=Enum.Font.Gotham;dl.TextSize=11
    dl.TextColor3=Color3.fromRGB(100,70,180);dl.Text="by Fartzy";dl.Parent=p

    local hl=Instance.new("TextLabel");hl.Size=UDim2.new(1,-24,0,13)
    hl.Position=UDim2.fromOffset(12,64);hl.BackgroundTransparency=1
    hl.Font=Enum.Font.RobotoMono;hl.TextSize=10
    hl.TextColor3=Color3.fromRGB(60,60,80);hl.TextXAlignment=Enum.TextXAlignment.Left
    hl.Text="HWID: "..hid:sub(1,22).."...";hl.Parent=p

    -- Input
    local ib=Instance.new("Frame");ib.Size=UDim2.new(1,-24,0,38)
    ib.Position=UDim2.fromOffset(12,84);ib.BackgroundColor3=Color3.fromRGB(20,20,28);ib.Parent=p
    Instance.new("UICorner",ib).CornerRadius=UDim.new(0,8)
    local is2=Instance.new("UIStroke",ib);is2.Color=Color3.fromRGB(50,50,70);is2.Thickness=1

    local inp=Instance.new("TextBox");inp.Size=UDim2.new(1,-16,1,0)
    inp.Position=UDim2.fromOffset(8,0);inp.BackgroundTransparency=1
    inp.Font=Enum.Font.GothamMedium;inp.TextSize=13
    inp.TextColor3=Color3.fromRGB(220,220,240)
    inp.PlaceholderText="Enter key...";inp.PlaceholderColor3=Color3.fromRGB(60,60,80)
    inp.Text="";inp.ClearTextOnFocus=false;inp.Parent=ib

    -- Status
    local st=Instance.new("TextLabel");st.Size=UDim2.new(1,-24,0,14)
    st.Position=UDim2.fromOffset(12,130);st.BackgroundTransparency=1
    st.Font=Enum.Font.Gotham;st.TextSize=11
    st.TextColor3=Color3.fromRGB(90,90,110);st.Text="Paste your key above";st.Parent=p

    -- Btn Get Key
    local bg2=Instance.new("TextButton");bg2.Size=UDim2.new(0.46,0,0,34)
    bg2.Position=UDim2.fromOffset(12,152);bg2.BackgroundColor3=Color3.fromRGB(70,35,160)
    bg2.Font=Enum.Font.GothamBold;bg2.TextSize=13
    bg2.TextColor3=Color3.fromRGB(255,255,255);bg2.Text="Get Key";bg2.Parent=p
    Instance.new("UICorner",bg2).CornerRadius=UDim.new(0,8)

    -- Btn Verify
    local bv=Instance.new("TextButton");bv.Size=UDim2.new(0.46,0,0,34)
    bv.Position=UDim2.new(0.5,2,0,152);bv.BackgroundColor3=Color3.fromRGB(30,140,70)
    bv.Font=Enum.Font.GothamBold;bv.TextSize=13
    bv.TextColor3=Color3.fromRGB(255,255,255);bv.Text="Verify";bv.Parent=p
    Instance.new("UICorner",bv).CornerRadius=UDim.new(0,8)

    bg2.MouseButton1Click:Connect(function()
        local lnk=GetLink(hid)
        pcall(setclipboard,lnk)
        st.Text="Link copied! Open in browser."
        st.TextColor3=Color3.fromRGB(80,180,255)
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(lnk) end)
    end)

    bv.MouseButton1Click:Connect(function()
        local ek=inp.Text:match("^%s*(.-)%s*$")
        if #ek<4 then
            st.Text="Key too short!";st.TextColor3=Color3.fromRGB(255,70,70);return
        end
        st.Text="Checking...";st.TextColor3=Color3.fromRGB(200,200,80)
        bv.Active=false

        -- Fetch key list dari Worker endpoint
        local ok2,raw=pcall(function()
            return game:HttpGet(KEY_EP,true)
        end)
        if not ok2 or not raw then
            st.Text="Server error. Try again.";st.TextColor3=Color3.fromRGB(255,70,70)
            bv.Active=true;return
        end

        local valid={}
        for line in raw:gmatch("[^\r\n]+") do
            local k2=line:match("^%s*(.-)%s*$")
            if k2 and #k2>0 and k2:sub(1,2)~="--" then valid[k2]=true end
        end

        if valid[ek] then
            SaveKey(ek,hid)
            st.Text="✓ Valid! Loading Kiyo Hub..."
            st.TextColor3=Color3.fromRGB(60,220,100)
            is2.Color=Color3.fromRGB(40,180,70)
            task.delay(0.8,function()
                pcall(sg.Destroy,sg)
                cb()
            end)
        else
            st.Text="✗ Invalid key."
            st.TextColor3=Color3.fromRGB(255,70,70)
            is2.Color=Color3.fromRGB(220,50,50)
            bv.Active=true
        end
    end)
end

-- ── Main ──
local function Main()
    -- Fetch dan load script dari Worker
    local ok,src=pcall(function()
        return game:HttpGet(SCRIPT_EP,true)
    end)
    if ok and src and #src>100 then
        loadstring(src)()
    else
        warn("[KiyoHub] Failed to fetch script")
    end
end

local function Run()
    local hid=GetHWID()
    local k,hid2,ts=LoadKey()
    -- Key valid: ada, HWID cocok, belum expired (24 jam)
    if k and hid2==hid and ts and (os.time()-ts)<86400 then
        task.defer(Main)
    else
        ShowUI(hid, Main)
    end
end

Run()
