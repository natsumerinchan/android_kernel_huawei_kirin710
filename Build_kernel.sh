#!/bin/bash
#设置环境

# Special Clean For Huawei Kernel.
if [ -d include/config ];
then
    echo "Find config,will remove it"
	rm -rf include/config
else
	echo "No Config,good."
fi


echo " "
echo "***Setting environment...***"
# 交叉编译器路径
export PATH=$PATH:$(pwd)/aarch64-linux-android-4.9/bin
export CROSS_COMPILE=aarch64-linux-android-

export GCC_COLORS=auto
export ARCH=arm64
if [ ! -d "out" ];
then
	mkdir out
fi

start_time=$(date +%Y.%m.%d-%I_%M)

start_time_sum=$(date +%s)

#!/bin/bash

# 提示用户选择选项
echo "请选择一个选项："
echo "1. 设置defconfig参数为Nova4e"
echo "2. 设置defconfig参数为荣耀8X"
echo "3. 设置defconfig参数为默认710配置"
echo "请输入数字1到3"

# 读取用户输入的选项
read choice

# 根据用户选择设置defconfig参数
case $choice in
  1)
    defconfig="Nova4e_Kirin710_KSU_defconfig"
    ;;
  2)
    defconfig="JSN_kirin710_KSU_defconfig"
    ;;
  3)
    defconfig="kirin710_KSU_defconfig"
    ;;
  *)
    echo "无效的选项"
    exit 1
    ;;
esac

# 输出所选的defconfig参数
echo "已选择的defconfig参数为: $defconfig"


#构建内核部分
echo "***Building kernel...***"
make ARCH=arm64 O=out ${defconfig}
# 定义编译线程数
make ARCH=arm64 O=out -j64 2>&1 | tee kernel_log-${start_time}.txt

end_time_sum=$(date +%s)

end_time=$(date +%Y.%m.%d-%I_%M)

# 计算运行时间（秒）
duration=$((end_time_sum - start_time_sum))

# 将秒数转化为 "小时:分钟:秒" 形式输出
hours=$((duration / 3600))
minutes=$(( (duration % 3600) / 60 ))
seconds=$((duration % 60))

# 打印运行时间
echo "脚本运行时间为：${hours}小时 ${minutes}分钟 ${seconds}秒"

#打包内核

if [ -f out/arch/arm64/boot/Image.gz ];
then
	echo "***Packing kernel...***"

	cp out/arch/arm64/boot/Image.gz Image.gz 
	
	# Pack Enforcing Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x0 --cmdline "loglevel=4 initcall_debug=n page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=enforcing buildvariant=user" --tags_offset 0x07A00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000 --header_version 1 --os_version 9 --os_patch_level 2019-05-05 --output Kirin710_EMUI_9.1.0-${end_time}.img
	
	# Pack Permissive Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x0 --cmdline "loglevel=4 initcall_debug=n page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=permissive buildvariant=user" --tags_offset 0x07A00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000 --header_version 1 --os_version 9 --os_patch_level 2019-05-05 --output Kirin710_EMUI_9.1.0_PM-${end_time}.img

	echo "***Sucessfully built kernel...***"
	echo " "
	exit 0
else
	echo " "
	echo "***Failed!***"
	exit 0
fi