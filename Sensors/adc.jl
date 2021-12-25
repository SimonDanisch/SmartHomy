#
# The MIT License (MIT)
# Copyright (C) 2018  Seeed Technology Co.,Ltd.
#
# This is the ADC library for Grove Base Hat
# which used to connect grove sensors for raspberry pi.
# ported to Julia by Simon Danisch

using BaremetalPi

const RPI_HAT_PID = 0x0004
const RPI_ZERO_HAT_PID = 0x0005
const RPI_HAT_NAME = "Grove Base Hat RPi"

function get_i2c_bus()
    if BaremetalPi.objects.i2c_init
        return 1
    else
        init_i2c("/dev/i2c-1")
        return 1
    end
end

struct ADC
    address::Int
    bus::Int
end

function ADC(address=0x04)
    ADC(address, get_i2c_bus())
end

# read 16 bits register
"""
Read the ADC Core (through I2C) registers
Grove Base Hat for RPI I2C Registers
    - 0x00 ~ 0x01:
    - 0x10 ~ 0x17: ADC raw data
    - 0x20 ~ 0x27: input voltage
    - 0x29: output voltage (Grove power supply voltage)
    - 0x30 ~ 0x37: input voltage / output voltage
Args:
    n(int): register address.
Returns:
(int) : 16-bit register value.
"""
function read_register(adc::ADC, n)
    i2c_slave(adc.bus, adc.address)
    i2c_smbus_write_byte(adc.bus, n)
    return i2c_smbus_read_word_data(adc.bus, n)
end

"""
Read the raw data of ADC unit, with 12 bits resolution.
Args:
    channel (int): 0 - 7, specify the channel to read
Returns:
    (int): the adc result, in [0 - 4095]
"""
function read_raw(adc::ADC, channel)
    return read_register(adc, 0x10 + channel)
end

"""
Read the voltage data of ADC unit.
Args:
    channel (int): 0 - 7, specify the channel to read
Returns:
    (int): the voltage result, in mV
"""
function read_voltage(adc::ADC, channel)
    return read_register(adc, 0x20 + channel)
end

"""
Read the ratio between channel input voltage and power voltage (most time it's 3.3V).
Args:
    channel (int): 0 - 7, specify the channel to read
Returns:
    (int): the ratio, in 0.1%
"""
function Base.read(adc::ADC, channel)
    return read_register(adc, 0x30 + channel)
end

"""
Get the Hat name.
Returns:
    (string): could be :class:`RPI_HAT_NAME` or :class:`RPI_ZERO_HAT_NAME`
"""
function name(adc::ADC)
    id = read_register(adc, 0x0)
    if id == RPI_HAT_PID
        return RPI_HAT_NAME
    elseif id == RPI_ZERO_HAT_PID
        return RPI_ZERO_HAT_NAME
    end
end

"""
Get the Hat firmware version.
Returns:
    (int): firmware version
"""
version(adc::ADC) = read_register(adc, 0x3)
