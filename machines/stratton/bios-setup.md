# BIOS settings for Stratton
> **NOTE:** These settings are for motherboard: [ROG STRIX B450-F GAMING](https://rog.asus.com/se/motherboards/rog-strix/rog-strix-b450-f-gaming-model/) with 128 GB [VENGEANCE® LPX DDR4 DRAM 3200MHz C16 Memory Kit](https://www.corsair.com/uk/en/p/memory/cmk64gx4m2e3200c16/vengeancea-lpx-64gb-2-x-32gb-ddr4-dram-3200mhz-c16-memory-kit-black-cmk64gx4m2e3200c16) and a [AMD Ryzen™ 9 5950X Desktop Processor](https://www.amd.com/en/products/processors/desktops/ryzen/5000-series/amd-ryzen-9-5950x.html)

1. Reset BIOS to factory settings (as a baseline)
   1. Go to **Exit**
   2. Click "Load Optimizzed Defaults"
   3. Click "Save Changes & Exit"

2. Fans
   1. In the top bar click "Qfan Control"
   2. In the left top corner click on "Optimize All"
   3. When calibration is done change all fan curvs (CPU FAN, CHA1 FAN, CHA2 FAN, CHA3 FAN) to:
      - The first point: 35% fan at 45 C
      - The second point: 60% fan at 70 C
      - The third point: 100% fan at 85 C
      - Click "Apply" when you have set curve for one fan

3. Overclocking RAM
   1. Click on the "Ai Tweaker" in the bar
   2. In the first item "Ai Overclock Tuner" select "D.O.C.P. Standard"
   3. In the "D.O.C.P." field select "D.O.C.P DDR4-3200 16-20-20-38...."

4. Under volting CPU
   1. Go to Advanced -> AMD Overclocking -> Precision Boost Overdirve, set "Precision Boost Overdirve" to ``Advanced``
      1. Set PBO Limits to ``Manual``
      2. Set "PPT Limit [W]" to ``100``
      3. Set "TDC Limit [A]" to ``70``
      4. Set "EDC Limit [A]" to ``100``
      5. Set "Platform Thermal Throttle Limit" to ``Manual`` and set it to ``85``
      6. Go to Curve Optimizer, set Curve Optimizer to ``All Cores``
         1. Set "All Core Curve Optimizer Sign" to ``Negative``
         2.  Set "ALL Core Curve Optimizer Magnitude" to ``10``

5. Efficency and stability settings 
   1. Go to Advanced -> AMD CBS -> CPU Common Options
      1. Set "Global C-State Control" to ``Enabled``
      2. Set "Power Supply Idle Control" to ``Typical Current Idle``
   2. Go to Boot and set "Fast Boot" to ``Disabled``
   3. Go to Advanced -> ROG Effects and set "Onboard LED" to ``Disabled``
   4. Go to Advanced -> Onboard Devices Configuration and set "HD Audio Controller" to ``Disabled``
      1. Under RGB LED lighting, set "When system is in working state" to ``Off`` and "When system is in sleep, hibernate or osft off states" to ``Off``

6. Virtualization
   1. Go to "Advanced" in the bar
   2. Scroll down and ggo to "AMD CBS" -> "NBIO Common Options"
   3. On the item "IOMMU" select "Enabled"
   4. Go back to "Advanced" section and navigate to "CPU Configuration"
   5. Set "SVM Mode" to "Enabled"

7. HDD drives
   1. Go to "Advanced" -> "SATA Configuration"
   2. On every SATA port connected to HDD hotswap bay (2,3,4,5,6) set "Hot Plug" to enable

8. Click on "Exit" in the bar and click on "Save Changes & Reset" and hit "OK"

