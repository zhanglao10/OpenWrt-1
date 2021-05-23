#/bin/bash
echo
echo
echo "本脚本仅适用于在Ubuntu环境下编译 https://github.com/garypang13/Actions-OpenWrt"
echo
echo
sleep 2s
sudo apt-get update
sudo apt-get upgrade

sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs gcc-multilib g++-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler ccache xsltproc rename antlr3 gperf curl screen upx



clear 
echo
echo 
echo 
echo "|*******************************************|"
echo "|                                           |"
echo "|                                           |"
echo "|           基本环境部署完成......          |"
echo "|                                           |"
echo "|                                           |"
echo "|*******************************************|"
echo
echo


if [ "$USER" == "admin" ]; then
	echo
	echo
	echo "请勿使用root用户编译，换一个普通用户吧~~"
	sleep 3s
	exit 0
fi





rm -Rf openwrt

echo "

1. X86_64

2. K2p

3. K2p 32M

4. RedMi_AC2100

5. r2s

6. r4s

7. newifi-d2

8. XY-C5

9. Exit

"

while :; do

read -p "你想要编译哪个固件？ " CHOOSE

case $CHOOSE in
	1)
		firmware="x86_64"
	break
	;;
	2)
		firmware="phicomm-k2p"
	break
	;;
	3)
		firmware="k2p-32m-usb"
	break
	;;
	4)
		firmware="redmi-ac2100"
	break
	;;
	5)
		firmware="nanopi-r2s"
	break
	;;
	6)
		firmware="nanopi-r4s"
	break
	;;
	7)
		firmware="newifi-d2"
	break
	;;
	8)
		firmware="XY-C5"
	break
	;;
	9)	exit 0
	;;

esac
done

if [[ $firmware =~ (redmi-ac2100|phicomm-k2p|newifi-d2|k2p-32m-usb|XY-C5|xiaomi-r3p) ]]; then
		git clone -b openwrt-21.02 --depth 1 https://github.com/openwrt/openwrt
		svn co https://github.com/garypang13/Actions-OpenWrt/trunk/devices openwrt/devices
		cd openwrt
		wget -cO sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/21.02-SNAPSHOT/targets/ramips/mt7621/openwrt-sdk-21.02-SNAPSHOT-ramips-mt7621_gcc-8.4.0_musl.Linux-x86_64.tar.xz
elif [[ $firmware =~ (nanopi-r2s|nanopi-r4s) ]]; then
		git clone -b openwrt-21.02 --depth 1 https://github.com/openwrt/openwrt
		svn co https://github.com/garypang13/Actions-OpenWrt/trunk/devices openwrt/devices
		cd openwrt
		wget -cO sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/21.02-SNAPSHOT/targets/rockchip/armv8/openwrt-sdk-21.02-SNAPSHOT-rockchip-armv8_gcc-8.4.0_musl.Linux-x86_64.tar.xz
elif [[ $firmware == "x86_64" ]]; then
		git clone -b openwrt-21.02 --depth 1 https://github.com/openwrt/openwrt
		svn co https://github.com/garypang13/Actions-OpenWrt/trunk/devices openwrt/devices
		cd openwrt
		wget -cO sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/21.02-SNAPSHOT/targets/x86/64/openwrt-sdk-21.02-SNAPSHOT-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
fi


read -p "请输入后台地址 [回车默认192.168.1.1]: " ip
ip=${ip:-"192.168.1.1"}
echo "您的后台地址为: $ip"
cp -rf devices/common/* ./
cp -rf devices/$firmware/* ./
./scripts/feeds update -a
cp -Rf ./diy/* ./
if [ -f "devices/common/diy.sh" ]; then
		chmod +x devices/common/diy.sh
		/bin/bash "devices/common/diy.sh"
fi
if [ -f "devices/$firmware/diy.sh" ]; then
		chmod +x devices/$firmware/diy.sh
		/bin/bash "devices/$firmware/diy.sh"
fi
if [ -f "devices/common/default-settings" ]; then
	sed -i 's/10.0.0.1/$ip/' devices/common/default-settings
	cp -f devices/common/default-settings package/*/*/default-settings/files/uci.defaults
fi
if [ -f "devices/$firmware/default-settings" ]; then
	sed -i 's/10.0.0.1/$ip/' devices/$firmware/default-settings
	cat -f devices/$firmware/default-settings >> package/*/*/default-settings/files/uci.defaults
fi
if [ -n "$(ls -A "devices/common/patches" 2>/dev/null)" ]; then
          find "devices/common/patches" -type f -name '*.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -p1 --forward"
fi
if [ -n "$(ls -A "devices/$firmware/patches" 2>/dev/null)" ]; then
          find "devices/$firmware/patches" -type f -name '*.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -p1 --forward"
fi
cp devices/common/.config .config
echo >> .config
cat devices/$firmware/.config >> .config
make menuconfig
echo
echo
echo
echo "                      *****5秒后开始编译*****

1.你可以随时按Ctrl+C停止编译

3.大陆用户编译前请准备好梯子,使用大陆白名单或全局模式"
echo
echo
echo
sleep 3s

make -j$(($(nproc)+1)) download -j$(($(nproc)+1)) &
make -j$(($(nproc)+1)) || make -j1 V=s

if [ "$?" == "0" ]; then
echo "

编译完成~~~

初始后台地址: $ip
初始用户名密码: admin  password

"
fi
