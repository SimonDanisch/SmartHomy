const smbus2 = pyimport("smbus2")
const i2c_msg = smbus2.i2c_msg
const SMBusWrapper = smbus2.SMBusWrapper

const HM3301__DEFAULT_I2C_ADDR = 0x40
const SELECT_I2C_ADDR = 0x88
const DATA_CNT = 29

struct HM3301 <: AbstractSensor
    i2c_address::UInt8
    select_i2c_address::UInt8
    data_count::Int
    data::SensorData
end

function HM3301(i2c_address=0x40, select_i2c_address=0x88, data_count=29)
    sensor = HM3301(i2c_address, select_i2c_address, data_count, SensorData())
    @pywith SMBusWrapper(1) as bus begin
        write = i2c_msg.write(i2c_address, [select_i2c_address])
        bus.i2c_rdwr(write)
    end
    return sensor
end

function read_sensor(sensor::HM3301)
    @pywith SMBusWrapper(1) as bus begin
        read = i2c_msg.read(sensor.i2c_address, sensor.data_count)
        bus.i2c_rdwr(read)
        return py"list"(read)
    end
end

function check_crc(data)
    s = sum(@view(data[1:end-1]))
    s = s & 0xff
    return s == data[29]
end

function Base.read!(sensor::HM3301)
    data = read_sensor(sensor)
    check_crc(data) || error("Checksum failure for HM3301")

    set!(sensor, :pm1, data[5]<<8 | data[6])
    set!(sensor, :pm2_5, data[7]<<8 | data[8])
    set!(sensor, :pm10, data[9]<<8 | data[10])

    set!(sensor, :pm1_atmospheric, data[11]<<8 | data[12])
    set!(sensor, :pm2_5_atmospheric, data[13]<<8 | data[14])
    set!(sensor, :pm10_atmospheric, data[15]<<8 | data[16])

    return
end

function units(sensor::HM3301)
    return "µg/m³"
end
