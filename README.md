# What is it?

I recently bought [this](https://www.ebay.com/itm/186334016423) for the car since it has issues with draining battery. It came with instructions to download the android app as APK from a chinese server. 
I did not want any unknown apk on my phone and decided to make my own app for it. Since I have no idea about android app development I decided to use flutter.
All Technical details I think are correct are below. 

# This repository

The code looks really messy. I apologize but again I have no idea what I'm doing 🙈

# Technical details

It's a BLE (Bluetooth Low Energy Device) has the MAC `00:00:00:D1:0A:84` and name `Battery Asst`.

It sends some `ae02` as UUID? which is the battery voltage.

I wrote a proof of concept using Python:
```python
import asyncio
from bleak import BleakScanner, BleakClient, BleakError, BleakGATTCharacteristic
import time
from decimal import Decimal, ROUND_HALF_UP

time_get_data = 0


async def set_characteristic(characteristic):
    print(characteristic)
    pass

async def notify_callback(sender, data):
    try:
        hex_string = data[1:3].hex()
        await add_text(hex_string)
    except Exception as e:
        print(e)

async def add_text(hex_string):
    global time_get_data
    value = int(hex_string, 16) / 62.0
    format_value = Decimal(value).quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)

    if time.time() * 1000 - time_get_data > 500:
        time_get_data = time.time() * 1000
        event_message = {"code": 102, "message": str(format_value)}
        volt_point = {"time": time.time() * 1000, "voltage": float(format_value)}
        print(volt_point)

def callback(sender: BleakGATTCharacteristic, data: bytearray):
    print(f"{sender}: {data}")

async def read(device_address):
    async with BleakClient(device_address) as client:
        for service in client.services:
            for characteristic in service.characteristics:
                if "ae02" in str(characteristic.uuid):
                    await set_characteristic(characteristic)
                    await client.start_notify(characteristic, notify_callback)
                else:
                    print(f"Skipping {characteristic.uuid}: {characteristic}")

        await client.disconnect()
        await asyncio.sleep(1)

async def main():
    scanner = BleakScanner()
    try:
        devices = await scanner.discover()
        for d in devices:
            if d.address == '00:00:00:D1:0A:84':
                await read(d.address)
                break
    except BleakError as e:
        print(f"BLE operation failed: {e}", e)
    finally:
        await scanner.stop()

"""
Equivalent java code:
public void read() {
        Iterator<BluetoothGattService> it = BleManager.getInstance().getBluetoothGatt(this.mDevice).getServices().iterator();
        while (it.hasNext()) {
            for (BluetoothGattCharacteristic bluetoothGattCharacteristic : it.next().getCharacteristics()) {
                if (bluetoothGattCharacteristic.getUuid().toString().contains("ae02")) {
                    setCharacteristic(bluetoothGattCharacteristic);
                }
            }
        }
        BleManager.getInstance().notify(this.mDevice, this.characteristic.getService().getUuid().toString(), this.characteristic.getUuid().toString(), new BleNotifyCallback() { // from class: com.ifly.battery.MainActivity.7
            @Override // com.clj.fastble.callback.BleNotifyCallback
            public void onNotifySuccess() {
                MainActivity.this.runOnUiThread(new Runnable() { // from class: com.ifly.battery.MainActivity.7.1
                    @Override // java.lang.Runnable
                    public void run() {
                        LogUtils.e("读取成功");
                    }
                });
            }

            @Override // com.clj.fastble.callback.BleNotifyCallback
            public void onNotifyFailure(BleException bleException) {
                MainActivity.this.runOnUiThread(new Runnable() { // from class: com.ifly.battery.MainActivity.7.2
                    @Override // java.lang.Runnable
                    public void run() {
                        LogUtils.e("读取失败");
                    }
                });
            }

            @Override // com.clj.fastble.callback.BleNotifyCallback
            public void onCharacteristicChanged(final byte[] bArr) {
                MainActivity.this.runOnUiThread(new Runnable() { // from class: com.ifly.battery.MainActivity.7.3
                    @Override // java.lang.Runnable
                    public void run() {
                        try {
                            MainActivity.this.addText(HexUtil.formatHexString(new byte[]{bArr[1], bArr[2]}));
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        });
    }
"""


asyncio.run(main())
```
