# credit where it's due: https://github.com/esphome/esphome/blob/dev/esphome/components/xiaomi_ble/xiaomi_ble.cpp
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_data(0x16, bytes('95FE'), 0)
  if size(elements)
    var data = elements[0].data[2..]
    if blerry_helpers.bitval(data[0], 6) == 0 # is there data in packet
      return false
    end
    if blerry_helpers.bitval(data[0], 3) == 1 # encrypted
      return false
    end
    if data[2..3] != bytes('AA01') # LYWSDCGQ
      return false
    end
    var offset = 11 + blerry_helpers.bitval(data[0], 5) # offset to data point
    if data[offset+1] != 0x10 # no magic byte in data point
      return false
    end
    var dp_type = data[offset]
    var dp_len = data[offset+2]
    var dp_data = data[offset+3..]
    if (dp_type == 0x04) && (dp_len == 2)
      device.add_sensor('Temperature', dp_data.geti(0,2)/10.0,  'temperature', '°C')
    elif (dp_type == 0x06) && (dp_len == 2)
      device.add_sensor('Humidity', dp_data.geti(0,2)/10.0,  'humidity', '%')
    elif (dp_type == 0x0A) && (dp_len == 1)
      device.add_sensor('Battery', dp_data[0],  'battery', '%')
    elif (dp_type == 0x0d) && (dp_len == 4)
      var t = dp_data.geti(0,2)/10.0
      var h = dp_data.geti(2,2)/10.0
      var dewp = blerry_helpers.get_dewpoint(t, h)
      device.add_sensor('Temperature', t,  'temperature', '°C')
      device.add_sensor('Humidity', h, 'humidity', '%')
      device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    else
      print(string.format('BLY: Xiaomi: Unsupported Data Type & Length: Type: 0x%X, Length: %d, Data: %s', dp_type, dp_len, dp_data))
    end
  else
    return false
  end
  return true
end
blerry_active = false
