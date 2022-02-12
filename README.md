This build and guide is based on [this](https://gitlab.com/ubports/community-ports/android9/xiaomi-redmi-note-7-pro/xiaomi-violet).

To build do the following:
```
export DTC_EXT=dtc
./build.sh -b bd  # bd is the name of the build directory
./build/prepare-fake-ota.sh out/device_davinci.tar.xz ota
./build/system-image-from-ota.sh ota/ubuntu_command out
```


After image is built, the image needs to be converted to ext4 (use https://github.com/anestisb/android-simg2img)
```
simg2img out/system.img ubuntu.img
```
Copy ubuntu.img to /data

Flash boot.img

Done.
