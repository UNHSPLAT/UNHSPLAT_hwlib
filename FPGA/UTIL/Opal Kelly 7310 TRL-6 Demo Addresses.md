# Opal Kelly 7310 TRL-6 Demo Addresses
## WIREINS
Output from Laptop to FPGA

WireIn Address

| WireIn | Address |
|--------|----------|
| SPARE | x"00" |
| THRESH_UPPER | x"01" |
| THRESH_LOWER0 | x"02" |
| THRESH_LOWER4 | x"03" |
| THRESH_LOWER8 | x"04" |
| THRESH_LOWER12 | x"05" |
| PULSER_CONFIG | x"06" |
| PULSER RATE | x"07" |
| PPA_CNT_RATE | x"08" |
| THRESH_PULSE_HEIGHT | x"09" |

Upper Thresholds

| Threshold | Address | Bits | Bit Total |
|-----------|---------|------|----------|
| Thres_u0 | x"01" | 7 downto 0 | 8 |
| Thresh_u7 | x"01" | 15 downto 8 | 8 |
| Thresh_u8 | x"01" | 23 downto 16 | 8 |
| Thresh_u15 | x"01" | 31 donwto 24 | 8 |

Lower Thresholds

| Threshold | Address | Bits | Bit Total |
|-----------|---------|------|----------|
| Thresh_0 | x"02" | 7 downto 0 | 8 |
| Thresh_1 | x"02" | 15 downto 8 | 8 |
| Thresh_2 | x"02" | 23 downto 16 | 8 |
| Thresh_3 | x"02" | 31 downto 24 | 8 |
| Thresh_4 | x"03" | 7 downto 0 | 8 |
| Thresh_5 | x"03" | 15 downto 8 | 8 |
| Thresh_6 | x"03" | 23 downto 16 | 8 |
| Thresh_7 | x"03" | 31 downto 24 | 8 |
| Thresh_8 | x"04" | 7 downto 0 | 8 |
| Thresh_9 | x"04" | 15 downto 8 | 8 |
| Thresh_10 | x"04" | 23 downto 16 | 8 |
| Thresh_11 | x"04" | 31 downto 24 | 8 |
| Thresh_12 | x"05" | 7 downto 0 | 8 |
| Thresh_13 | x"05" | 15 downto 8 | 8 |
| Thresh_14 | x"05" | 23 downto 16 | 8 |
| Thresh_15 | x"05" | 31 downto 24 | 8 |

Pulser Config

| Setting | Address | Bit Range | Bit Total | Value |
|---------|---------|-----------|-----------|-------|
| Even Pulser Enable | x"06" | 0 | 1 | '0' = Disable<br>'1' = Enable |
| Odd Pulser Enable | x"06" | 1 | 1 | '0' = Disable<br>'1' = Enable |
| External Pulser Enable | x"06" | 2 | 1 | '0' = Disable<br>'1' = Enable (overrides rate selection) |
| Pulser Output Selection | x"06" | 6 downto 4 | 3 | 0 = SSD 0/1<br>1 = SSD 2/3<br>2 = SSD 4/5<br>3 = SSD 6/7<br>4 = SSD 8/9<br>5 = SSD 10/11<br>6 = SSD 12/13<br>7 = SSD 14/15 |

Pulser Frequency

| Setting | Address | Bit Range | Bit Total | Value |
|---------|---------|-----------|-----------|-------|
| Pulser Frequency Selection | x"07" | 2 downto 0 | 3 | 0 = 10 Hz<br>1 = 100 Hz<br>2 = 1 kHz<br>3 = 10 kHz<br>4 = 100 kHz |

Acquisition Rate

| Setting | Address | Bit Range | Bit Total | Value |
|---------|---------|-----------|-----------|-------|
| PPA_CNT_RATE | x"08" | 0 | 1 | '0' = 1 second<br>'1' = 10 seconds |

Pulse Height Threshold

| Setting | Address | Bit Range | Bit Total | Value |
|---------|---------|-----------|-----------|-------|
| Pulse Height Threshold | x"09" | 13 downto 0 | 14 | SIGNED 14 bits |

## WIREOUTS
--Output to Laptop from FPGA

| WireOut | Address |
|---------|----------|
| FPGA_Staus | x"20" |
| Aliveness Counter (Count) | x"21" |
| PPA_Count0 | x"22" |
| PPA_Count1 | x"23" |
| PPA_Count2 | x"24" |
| PPA_Count3 | x"25" |
| PPA_Count4 | x"26" |
| PPA_Count5 | x"27" |
| PPA_Count6 | x"28" |
| PPA_Count7 | x"29" |
| PPA_Count8 | x"2A" |
| PPA_Count9 | x"2B" |
| PPA_Count10 | x"2C" |
| PPA_Count11 | x"2D" |
| PPA_Count12 | x"2E" |
| PPA_Count13 | x"2F" |
| PPA_Count14 | x"30" |
| PPA_Count15 | x"31" |
| Raw_High_U15 | x"32" |
| Raw_High_U8 | x"33" |
| Raw_High_U7 | x"34" |
| Raw_High_U0 | x"35" |
| Raw_Low_U15 | x"36" |
| Raw_Low_U8 | x"37" |
| Raw_Low_U7 | x"38" |
| Raw_Low_U0 | x"39" |
| RAW_LOW_COUNT13 | x"3A" |
| RAW_LOW_COUNT11 | x"3B" |
| RAW_LOW_COUNT9 | x"3C" |
| RAW_LOW_COUNT5 | x"3D" |
| RAW_LOW_COUNT3 | x"3E" |
| RAW_LOW_COUNT1 | x"3F" |

--FPGA Status

| WireOut (FPGA_STATUS) | Address | Bits | Bit Total |
|----------------------|---------|------|----------|
| GIT_DIRTY | x"20" | 31 | 1 |
| GIT_HASH | x"20" | 27 downto 0 | 28 |

--Aliveness

| WireOut (Count) | Address | Bits | Bit Total |
|----------------|---------|------|----------|
| Aliveness Counter | x"21" | 31 downto 0 | 32 |

--PPA Counts

| WireOut (PPA_Counts) | Address | Bits | Bit Total |
|---------------------|---------|------|----------|
| PPA_Count0 | x"22" | 31 downto 0 | 32 |
| PPA_Count1 | x"23" | 31 downto 0 | 32 |
| PPA_Count2 | x"24" | 31 downto 0 | 32 |
| PPA_Count3 | x"25" | 31 downto 0 | 32 |
| PPA_Count4 | x"26" | 31 downto 0 | 32 |
| PPA_Count5 | x"27" | 31 downto 0 | 32 |
| PPA_Count6 | x"28" | 31 downto 0 | 32 |
| PPA_Count7 | x"29" | 31 downto 0 | 32 |
| PPA_Count8 | x"2A" | 31 downto 0 | 32 |
| PPA_Count9 | x"2B" | 31 downto 0 | 32 |
| PPA_Count10 | x"2C" | 31 downto 0 | 32 |
| PPA_Count11 | x"2D" | 31 downto 0 | 32 |
| PPA_Count12 | x"2E" | 31 downto 0 | 32 |
| PPA_Count13 | x"2F" | 31 downto 0 | 32 |
| PPA_Count14 | x"30" | 31 downto 0 | 32 |
| PPA_Count15 | x"31" | 31 downto 0 | 32 |

--Raw Upper Counts

| WireOut (Raw Upper Counts) | Address | Bits | Bit Total |
|---------------------------|---------|------|----------|
| Raw_High_U15 | x"32" | 31 downto 0 | 32 |
| Raw_High_U8 | x"33" | 31 downto 0 | 32 |
| Raw_High_U7 | x"34" | 31 downto 0 | 32 |
| Raw_High_U0 | x"35" | 31 downto 0 | 32 |
| Raw_Low_U15 | x"36" | 31 downto 0 | 32 |
| Raw_Low_U8 | x"37" | 31 downto 0 | 32 |
| Raw_Low_U7 | x"38" | 31 downto 0 | 32 |
| Raw_Low_U0 | x"39" | 31 downto 0 | 32 |

--Raw Lower Counts

| WireOut (Raw Lower Counts) | Address | Bits | Bit Total |
|---------------------------|---------|------|----------|
| RAW_LOW_COUNT14 | x"3A" | 31 downto 16 | 16 |
| RAW_LOW_COUNT13 | x"3A" | 15 downto 0 | 16 |
| RAW_LOW_COUNT12 | x"3B" | 31 downto 16 | 16 |
| RAW_LOW_COUNT11 | x"3B" | 15 downto 0 | 16 |
| RAW_LOW_COUNT10 | x"3C" | 31 downto 16 | 16 |
| RAW_LOW_COUNT9 | x"3C" | 15 downto 0 | 16 |
| RAW_LOW_COUNT6 | x"3D" | 31 downto 16 | 16 |
| RAW_LOW_COUNT5 | x"3D" | 15 downto 0 | 16 |
| RAW_LOW_COUNT4 | x"3E" | 31 downto 16 | 16 |
| RAW_LOW_COUNT3 | x"3E" | 15 downto 0 | 16 |
| RAW_LOW_COUNT2 | x"3F" | 31 downto 16 | 16 |
| RAW_LOW_COUNT1 | x"3F" | 15 downto 0 | 16 |

## TRIGGERINS

--10MHz TriggerIn (Laptop to FPGA); 1 Clock Pulse

| TriggerIn | Address | Bits | Bit Total |
|-----------|---------|------|----------|
| HSK_TRIGIN | x"40" | 0 | 1 |
| PPA_TRIGIN | x"40" | 1 | 1 |
| PH_TRIGIN | x"40" | 2 | 1 |

--40MHz TriggerIn (Laptop to FPGA); 1 Clock Pulse

| TriggerIn | Address | Bits | Bit Total |
|-----------|---------|------|----------|
| Start Counting | x"41" | 0 | 1 |
| Manual Stop Counting | x"41" | 1 | 1 |
| Clear PPA Counters | x"41" | 2 | 1 |
| Clear Upper Counters (RawCnt0) | x"41" | 3 | 1 |
| Clear Lower Counters (RawCnt1) | x"41" | 4 | 1 |

## TRIGGEROUTS
--TriggerOut (FPGA to Laptop); 1 Clock Pulse

| TriggerOut | Address | Bit | Bit Total |
|------------|---------|-----|----------|
| PPA DACs Updated | x"60" | 0 | 1 |
| PH Updated | x"60" | 1 | 1 |

## PIPEOUT

https://docs.opalkelly.com/fpsdk/frontpanel-api/

From OpalKelly:

"3.3.1 Length Restrictions

When using the Pipes API, the length is specified in bytes. Firmware restrictions put a limitation on the maximum length per transfer. However, this API will
automatically perform multiple transfers, if required, to complete the full length. Length must be an integer multiple of a minimal transfer size according to
the list below:

| DEVICE | LENGTH RESTRICTIONS (IN BYTES) |
|--------|-------------------------------|
| USB 2.0 | Multiple of 2 |
| USB 3.0 | Multiple of 16 |
| PCIe | Multiple of 8 |
3.3.2 Byte Order (USB 2.0)

Pipe data is transferred over the USB in 8-bit words but transferred to the FPGA in 16-bit words. Therefore, on the FPGA side (HDL), the Pipe interface
has a 16-bit word width but on the PC side (API), the Pipe interface has an 8-bit word width.

When writing to Pipe Ins, the first byte written is transferred over the lower order bits of the data bus (7:0). The second byte written is transferred over the
higher order bits of the data bus (15:8). Similarly, when reading from Pipe Outs, the lower order bits are the first byte read and the higher order bits are the
second byte read.

3.3.3 Byte Order (USB 3.0)

Pipe data is transferred over the USB in 8-bit words but transferred to the FPGA in 32-bit words. Therefore, on the FPGA side (HDL), the Pipe interface
has a 32-bit word width but on the PC side (API), the Pipe interface has an 8-bit word width.

When writing to Pipe Ins, the first byte written is transferred over the lower order bits of the data bus (7:0). The second byte written is transferred over next
higher order bits of the data bus (15:8) and so on. Similarly, when reading from Pipe Outs, the lower order bits are the first byte read and the next higher
order bits are the second byte read."


--PipeOut (FPGA to Laptop); Buffer size 32x1024. Each time you trigger (PH_TRIGIN), FPGA will write detected pulse height packet to buffer.

Outputs the following packet after read:

| PipeOut | Address | Bit | Bit Total |
|---------|---------|-----|----------|
| Zeroes | x"A0" | 31 downto 25 | 7 |
| Anode Active | x"A0" | 24 | 1 |
| Zeroes | x"A0" | 23 downto 20 | 4 |
| Anode Number | x"A0" | 19 downto 16 | 4 |
| Zeroes | x"A0" | 15 downto 14 | 2 |
| Pulse Dataout | x"A0" | 13 downto 0 | 14 | 