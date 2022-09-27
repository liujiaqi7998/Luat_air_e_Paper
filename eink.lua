--- 模块功能：E2417JS0D1驱动芯片墨水屏命令配置
module(..., package.seeall)
require "pins"

-- 墨水屏基本配置
-- 这是需要你修改的地方
local para = {
    width = 400, -- 分辨率宽度，400像素
    height = 300, -- 分辨率高度，300像素
    bpp = 1, -- 位深度，彩屏仅支持16位
    bus = disp.BUS_SPI4LINE, -- LCD专用SPI引脚接口，不可修改
    freq = 9000000, -- spi时钟频率，墨水屏最大10MHz，支持110K到13M（即110000到13000000）之间的整数（包含110000和13000000）
    hwfillcolor = 0x00, -- 填充色，白色
    pinrst = pio.P0_11, -- reset，复位引脚
    pinrs = pio.P0_1, -- DC，命令/数据选择引脚
    pinbusy = pio.P0_4, -- busy，忙引脚
    -- 初始化命令,空着不填
    initcmd = {}
}

-- 新建eink空对象
eink = {
    MIRROR_NONE = 0x00,
    MIRROR_HORIZONTAL = 0x01,
    MIRROR_VERTICAL = 0x02,
    MIRROR_ORIGIN = 0x03,
    ROTATE_0 = 0,
    ROTATE_90 = 90,
    ROTATE_180 = 180,
    ROTATE_270 = 270
}

-- 图片缓冲区
Paint = {
    Image = {},
    Width = 0,
    Height = 0,
    WidthMemory = 0,
    HeightMemory = 0,
    Color = 0,
    Rotate = 0,
    Mirror = 0,
    WidthByte = 0,
    HeightByte = 0,
    Scale = 0
}

-- local setGpio11Fnc = pins.setup(para.pinrst, 0) -- REST
-- local getGpio4Fnc = pins.setup(para.pinbusy, 0) -- Busy

--[[
函数名：ReadBusy
功能  ：读忙等待
参数  ：无
返回值：无
2022-9-28 校验通过
]]
disp.ReadBusy = function()
    log.debug("e-Paper busy")
    -- while (getGpio4Fnc() == 0) do
    --     disp.write(0x00010100) -- DelayMs 100 
    -- end
    log.debug("e-Paper busy release")
end

--[[
函数名：Reset
功能  ：屏幕电源复位
参数  ：无
返回值：无
2022-9-28 校验通过
]]
disp.Reset = function()
    log.debug("e-Paper Reset")
    pmd.ldoset(15, pmd.LDO_VLCD)
    -- setGpio11Fnc(1)
    -- disp.write(0x00010005) -- DelayMs 5 
    -- setGpio11Fnc(0)
    -- disp.write(0x00010010) -- DelayMs 10 
    -- setGpio11Fnc(1)
    -- disp.write(0x00010005) -- DelayMs 5 

    -- Soft-rest
    disp.write(0x00) -- C: 00
    disp.write(0x0002000E) -- D: 0E
    disp.write(0x00010005) -- DelayMs 5 
end

--[[
函数名：TurnOnDisplay
功能  ：打开显示
参数  ：无
返回值：无
]]
disp.TurnOnDisplay = function()
    log.debug("e-Paper Turn On Display")
    disp.write(0x04) -- DISPLAY_REFRESH
    disp.write(0x00030000)
    disp.ReadBusy()
    disp.write(0x12) -- DISPLAY_REFRESH
    disp.write(0x00030000)
    disp.write(0x00010100) -- 延时100
    disp.ReadBusy()
end

--[[
函数名：sleep
功能  ：休眠
参数  ：无
返回值：无
]]
disp.sleep = function()
    log.debug("e-Paper sleep")
    disp.write(0x02) -- POWER_OFF
    disp.ReadBusy()
    disp.write(0x07) -- DEEP_SLEEP
    disp.write(0x000300A5)
    pmd.ldoset(0, pmd.LDO_VLCD)
end

--[[
函数名：displayRefresh
功能  ：显示墨水屏缓存区数据
参数  ：无
返回值：无
2022-9-28 校验通过
]]
disp.displayRefresh = function()
    log.debug("e-Paper display Refresh")
    disp.write(0x00010002) -- DelayMs 2 

    disp.write(0x00020004) -- CMD:DISPLAY_REFRESH
    disp.ReadBusy()
    disp.write(0x00020012) -- CMD:DISPLAY_REFRESH

    disp.write(0x00010100) -- DelayMs 100 
    disp.ReadBusy()
end

--[[
函数名：update
功能  ：上传并刷新屏幕显示
参数  ：无
返回值：无
2022-9-28 校验通过
]]
disp.update = function(Black_raw, Red_raw)
    log.debug("e-Paper Update")
    -- 先进行一下复位 ------------------------------------
    disp.Reset()
    -- 激活:普通更新 ------------------------------------
    disp.write(0xe5) -- CMD:temperature 输入温度
    disp.write(0x00030019) -- DATA:25 C
    disp.write(0xe0) -- CMD:temperature 激活温度
    disp.write(0x00030002) -- DATA:0x02 激活温度
    disp.ReadBusy()
    disp.write(0x00) -- CMD:Panel Setting (PSR)  面板设置
    disp.write(0x0003000F) -- DATA: 4.2"
    disp.write(0x00030089) -- DATA: 4.2"
    -- 上传黑色图片到缓存区 -----------------------------
    disp.write(0x00020010) -- CMD:DATA_START_TRANSMISSION_1 ; black
    for i = 1, #Black_raw do -- 发数据
        disp.write(0x00030000 + Black_raw[i])
    end
    -- 上传红色图片到缓存区 -----------------------------
    disp.write(0x00020013) -- CMD:DATA_START_TRANSMISSION_1 ; red
    for i = 1, #Red_raw do -- 发数据
        disp.write(0x00030000 + Red_raw[i])
    end
    -- 刷新一下屏幕 -------------------------------------
    disp.displayRefresh()
    ----- 休眠 ------------------------------------------
    disp.sleep()
    ----------------------------------------------------
end

--[[
函数名：Fastupdate
功能  ：快速上传并刷新屏幕显示
参数  ：无
返回值：无
2022-9-28 校验通过
]]
disp.Fast_update = function(Black_raw, Red_raw)
    log.debug("e-Paper Fastupdate")
    -- 先进行一下复位 ------------------------------------
    disp.Reset()
    -- 激活:普通更新 ------------------------------------
    disp.write(0xe5) -- CMD:temperature 输入温度
    disp.write(0x00030059) -- DATA:25 C 0x19 + 0x40
    disp.write(0xe0) -- CMD:temperature 激活温度
    disp.write(0x00030002) -- DATA:0x02 激活温度
    disp.ReadBusy()
    disp.write(0x00) -- CMD:Panel Setting (PSR)  面板设置
    disp.write(0x0003001f) -- DATA: 4.2" 0x0F | 0x10
    disp.write(0x0003008b) -- DATA: 4.2" 0x89 | 0x02
    disp.write(0x50) -- CMD:Vcom and data interva Setting VCOM和数据间隔设置
    disp.write(0x00030007) -- DATA:0x07 VCOM和数据间隔设置

    disp.write(0x50) -- CMD:Vcom and data interva Setting VCOM和数据间隔设置
    disp.write(0x00030027) -- DATA:0x27 Fast Update CDl1
    -- 上传黑色图片到缓存区 -----------------------------
    disp.write(0x00020010) -- CMD:DATA_START_TRANSMISSION_1 ; black
    for i = 1, #Black_raw do -- 发数据
        disp.write(0x00030000 + Black_raw[i])
    end
    -- 上传红色图片到缓存区 -----------------------------
    disp.write(0x00020013) -- CMD:DATA_START_TRANSMISSION_1 ; red
    for i = 1, #Red_raw do -- 发数据
        disp.write(0x00030000 + Red_raw[i])
    end
    -- 刷新一下屏幕 -------------------------------------
    disp.write(0x50) -- CMD:Vcom and data interva Setting VCOM和数据间隔设置
    disp.write(0x00030007) -- DATA:0x27 Fast Update CDl2
    disp.displayRefresh()
    ----- 休眠 ------------------------------------------
    disp.sleep()
    ----------------------------------------------------
end

--[[
函数名： Create Image
参数:
    image   :   指向图像缓存的指针
    width   :   图片的宽度
    Height  :   图片的高度
    Rotate   :   图片方向 eg: eink.ROTATE_0, eink.ROTATE_90 ...
    Color   :   图片颜色
]]
eink.Paint_NewImage = function(image, Width, Height, Rotate, Color)
    Paint.Image = {} -- 清空图像缓存区，放心，lua据说有内存回收机制
    Paint.Image = image

    Paint.WidthMemory = Width
    Paint.HeightMemory = Height
    Paint.Color = Color;
    Paint.Scale = 2

    Paint.WidthByte = math.ceil(Width / 8) -- 向正取整（不足+1）
    Paint.HeightByte = Height;

    Paint.Rotate = Rotate;
    Paint.Mirror = eink.MIRROR_NONE;

    if Rotate == eink.ROTATE_0 or Rotate == eink.ROTATE_180 then
        Paint.Width = Width;
        Paint.Height = Height;
    else
        Paint.Width = Height;
        Paint.Height = Width;
    end
end

--[[
函数名： Select Image
参数:
    image   :   指向图像缓存的指针
]]
eink.Paint_SelectImage = function(image) Paint.Image = image; end

--[[
函数名： Select Image Rotate
参数:
    Rotate   :   图片方向 eg: eink.ROTATE_0, eink.ROTATE_90 ...
]]
eink.Paint_SetRotate = function(Rotate)
    if Rotate == eink.ROTATE_0 or Rotate == eink.ROTATE_90 or Rotate ==
        eink.ROTATE_180 or Rotate == eink.ROTATE_270 then
        Paint.Rotate = Rotate;
        log.debug("Set image Rotate", Rotate)
    else
        log.info("Error image Rotate : rotate = 0, 90, 180, 270", Rotate)
    end
end

--[[
函数名： Set Scale Input parameter
参数:
    scale   :   图片比例 eg: 2 4 7
]]
eink.Paint_SetScale = function(scale)
    if scale == 2 then
        Paint.Scale = scale;
        Paint.WidthByte = math.ceil(Paint.WidthMemory / 8)
    elseif scale == 4 then
        Paint.Scale = scale;
        Paint.WidthByte = math.ceil(Paint.WidthMemory / 4)
    elseif scale == 7 then
        Paint.Scale = scale;
        Paint.WidthByte = math.ceil(Paint.WidthMemory / 2)
    else
        log.info("Set Scale Input parameter error : Scale Only support: 2 4 7",
                 scale)
    end
end

--[[
函数名： Select Image mirror
参数:
    mirror   :   不是镜子，水平镜子，垂直镜子，原点镜
]]
eink.Paint_SetMirroring = function(mirror)
    if mirror == eink.MIRROR_NONE or mirror == eink.MIRROR_HORIZONTAL or mirror ==
        eink.MIRROR_VERTICAL or mirror == eink.MIRROR_ORIGIN then
        Paint.Mirror = mirror;
    else
        log.info(
            "mirror should be MIRROR_NONE, MIRROR_HORIZONTAL,MIRROR_VERTICAL or MIRROR_ORIGIN",
            mirror)
    end
end

--[[
函数名： Draw Pixels
参数:
    Xpoint : X坐标
    Ypoint : Y坐标
    Color  : 颜色
]]
eink.Paint_SetPixel = function(Xpoint, Ypoint, Color)

    if Xpoint > Paint.Width or Ypoint > Paint.Height then
        log.debug("Exceeding display boundaries");
        return;
    end

    X = 0
    Y = 0

    ---以匿名函数实现
    local _switch_anonymous = {
        [0] = function()
            X = Xpoint;
            Y = Ypoint;
        end,
        [90] = function()
            X = Paint.WidthMemory - Ypoint - 1;
            Y = Xpoint;
        end,
        [180] = function()
            X = Paint.WidthMemory - Xpoint - 1;
            Y = Paint.HeightMemory - Ypoint - 1;
        end,
        [270] = function()
            X = Ypoint;
            Y = Paint.HeightMemory - Xpoint - 1;
        end
    }
    local _switch_function = _switch_anonymous[Paint.Rotate]
    if (_switch_function) then
        _switch_function()
    else -- for case default
        return
    end

    local _switch_anonymous = {
        [eink.MIRROR_NONE] = function() end,
        [eink.MIRROR_HORIZONTAL] = function()
            X = Paint.WidthMemory - X - 1;
        end,
        [eink.MIRROR_VERTICAL] = function()
            Y = Paint.HeightMemory - Y - 1;
        end,
        [eink.MIRROR_ORIGIN] = function()
            X = Paint.WidthMemory - X - 1;
            Y = Paint.HeightMemory - Y - 1;
        end
    }
    local _switch_function = _switch_anonymous[Paint.Mirror]
    if (_switch_function) then
        _switch_function()
    else -- for case default
        return
    end

    if X > Paint.WidthMemory or Y > Paint.HeightMemory then
        log.debug("Exceeding display boundaries");
        return;
    end

    if Paint.Scale == 2 then
        Addr = math.floor(X / 8) + Y * Paint.WidthByte;
        Rdata = Paint.Image[Addr];
        if Color == BLACK then
            Paint.Image[Addr] = bit.band(Rdata,
                                         bit.bnot(bit.rshift(0x80, (X % 8)))) -- Rdata & ~(0x80 >> (X % 8));
        else
            Paint.Image[Addr] = bit.bor(Rdata, bit.rshift(0x80, (X % 8))) -- Rdata | (0x80 >> (X % 8));
        end
    elseif Paint.Scale == 4 then
        Addr = math.floor(X / 4) + Y * Paint.WidthByte;
        Color = Color % 4; -- Guaranteed color scale is 4  --- 0~3
        Rdata = Paint.Image[Addr];
        Rdata = bit.band(Rdata, bit.bnot(bit.rshift(0xC0, ((X % 4) * 2)))) -- Rdata & (~(0xC0 >> ((X % 4)*2)));
        Paint.Image[Addr] = bit.bor(Rdata, bit.rshift(bit.lshift(Color, 6),
                                                      ((X % 4) * 2))) -- Rdata | ((Color << 6) >> ((X % 4) * 2))
    elseif Paint.Scale == 7 then
        Addr = math.floor(X / 2) + Y * Paint.WidthByte;
        Rdata = Paint.Image[Addr];
        -- Rdata = Rdata & (~(0xF0 >> ((X % 2)*4)));//Clear first, then set value
        Rdata = bit.band(Rdata, bit.bnot(bit.rshift(0xF0, ((X % 2) * 4))))
        -- Paint.Image[Addr] = Rdata | ((Color << 4) >> ((X % 2) * 4));
        Paint.Image[Addr] = bit.bor(Rdata, bit.rshift(bit.lshift(Color, 4),
                                                      ((X % 2) * 4)))
        -- printf("Add =  %d ,data = %d\r\n",Addr,Rdata);
    end
end

disp.init(para)
