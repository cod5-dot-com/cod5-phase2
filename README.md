# COD5 phase 2

The public domain computer

#### common 


```

sudo apt install build-essential git curl libtinfo5 iverilog gtkwave

firefox https://github.com/trabucayre/openFPGALoader/releases/download/v0.11.0/ubtuntu22.04-openFPGALoader.tgz

(cd /; sudo tar -xvzf ~/Downloads/ubtuntu22.04-openFPGALoader.tgz)

sudo apt install gcc-mipsel-linux-gnu


mkdir -p ~/Documents/src
cd ~/Documents/src
git clone https://github.com/cod5-dot-com/cod5-phase2.git
cd cod5-phase2
cd common
make
cd ..



```

#### Arty S7-50

```

firefox https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2023-2.html

sudo mkdir /tools
sudo chmod a+w /tools

bash FPGAs_AdaptiveSoCs_Unified_2023.2_1013_2256_Lin64.bin

sudo /tools/Xilinx/Vivado/2023.2/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers

```

### Tang Nano 20k

```
cd ~/Downloads/
firefox https://www.gowinsemi.com/en/support/download_eda/
tar -xvf Gowin_V1.9.9Beta-4_Education.tar.gz 
mv IDE ~/Documents/src/

```

### ULX3S

```

firefox https://www.latticesemi.com/en/Products/DesignSoftwareAndIP/FPGAandLDS/LatticeDiamond#linux

firefox https://www.latticesemi.com/Support/Licensing#requestDiamond

sudo apt install libftdi-dev alien

sudo alien --scripts diamond_3_13-base-56-2-x86_64-linux.rpm

sudo dpkg -i diamond-3-13-base_3.13-57_amd64.deb

sudo cp license.dat /usr/local/diamond/3.13/license/

/bin/bash /usr/local/diamond/3.13/bin/lin64/diamond

 
```

### GateMate

```
firefox https://colognechip.com/mygatemate/ 
 
cd ~/Documents/src

tar -xvzf ~/Downloads/cc-toolchain-linux.tar.gz

```

### MKR Vidor 4000

```
firefox https://www.intel.com/content/www/us/en/software-kit/785085/intel-quartus-prime-lite-edition-design-software-version-22-1-2-for-linux.html

cd ~/Downloads/

tar -xvf Quartus-lite-22.1std.2.922-linux.tar
./setup.sh

mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=~/.local/bin sh

echo install Arduino IDE and configure for MKR Vidor 4000
firefox https://www.arduino.cc/en/software


```

--

https://www.colognechip.com/gatemate-start/
https://github.com/ak-fau/gmm7550

https://docs.arduino.cc/hardware/mkr-vidor-4000
https://www.intel.com/content/www/us/en/products/details/fpga/development-tools/quartus-prime/resource.html

https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html
https://www.reddit.com/r/GowinFPGA/
https://www.gowinsemi.com/en/support/home/

https://digilent.com/reference/programmable-logic/arty-s7/start
https://www.xilinx.com/products/design-tools/vivado.html

https://radiona.org/ulx3s/
https://www.latticesemi.com/en/Products/DesignSoftwareAndIP/FPGAandLDS/LatticeDiamond


https://www.transcend-info.com/support/faq-296
https://blogs.synopsys.com/vip-central/2019/02/27/ddr5-4-3-2-how-memory-density-and-speed-increased-with-each-generation-of-ddr/
