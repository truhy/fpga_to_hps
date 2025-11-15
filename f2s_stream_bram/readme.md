# F2S stream BRAM

## Overview

A project for the DE10-Nano development board (Intel Cyclone V SoC FPGA) to test data transfers from FPGA to HPS using the FPGA-to-SDRAM interface.

The project is of two parts:

HPS software (standalone C):<br />
A program with master role to manage the transfer and process the data.

FPGA hardware logic design (Verilog and Intel IP):<br />
A design with slave role to transfer data from FPGA to HPS over the FPGA-to-SDRAM interface (F2S interface).  Data is transferred from FPGA embedded RAM (as block RAM) to HPS SDRAM.

## Results

The highest throughput rate I achieved:
- F2S interface, 256-bit, 200MHz, 256MB: **1782.62 MB/s**

For more results see the Excel file in the results folder.

## Guide

You can find the guide on my website:
[https://truhy.co.uk](https://truhy.co.uk)
