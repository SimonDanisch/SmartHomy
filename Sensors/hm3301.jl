using SmartHomy: set!, device, μg_m³
using SmartHomy: DustSensor
using PyCall
const smbus2 = pyimport("smbus2")
const i2c_msg = smbus2.i2c_msg
const SMBusWrapper = smbus2.SMBusWrapper

const HM3301__DEFAULT_I2C_ADDR = 0x40
const SELECT_I2C_ADDR = 0x88
const DATA_CNT = 29

struct HM3301Connection
    i2c_address::UInt8
    select_i2c_address::UInt8
    data_count::Int
end

function HM3301Connection(i2c_address=0x40, select_i2c_address=0x88, data_count=29)
    sensor = HM3301Connection(i2c_address, select_i2c_address, data_count)
    @pywith SMBusWrapper(1) as bus begin
        write = i2c_msg.write(i2c_address, [select_i2c_address])
        bus.i2c_rdwr(write)
    end
    return sensor
end

function HM3301(i2c_address=0x40, select_i2c_address=0x88, data_count=29)
    conn = HM3301Connection(i2c_address, select_i2c_address, data_count)
    return DustSensor(conn)
end

function read_sensor(io::HM3301Connection)
    @pywith SMBusWrapper(1) as bus begin
        read = i2c_msg.read(io.i2c_address, io.data_count)
        bus.i2c_rdwr(read)
        return py"list"(read)
    end
end

function check_crc(data)
    println(data)
    s = sum(@view(data[1:end-1]))
    s = s & 0xff
    return s == data[29]
end

function Base.read!(sensor::DustSensor{HM3301Connection})
    conn = device(sensor)
    data = read_sensor(conn)
    # check_crc(data) || error("Checksum failure for HM3301")

    SmartHomy.set!(sensor, :pm1, (data[5]<<8 | data[6]) * μg_m³)
    SmartHomy.set!(sensor, :pm2_5, (data[7]<<8 | data[8]) * μg_m³)
    SmartHomy.set!(sensor, :pm10, (data[9]<<8 | data[10]) * μg_m³)

    # SmartHomy.set!(io, :pm1_atmospheric, data[11]<<8 | data[12])
    # SmartHomy.set!(io, :pm2_5_atmospheric, data[13]<<8 | data[14])
    # SmartHomy.set!(io, :pm10_atmospheric, data[15]<<8 | data[16])
    return
end
