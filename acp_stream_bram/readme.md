# ACP stream BRAM

## Overview

A project for the DE10-Nano development board (Intel Cyclone V SoC FPGA) to test data transfers from FPGA to HPS using the FPGA-to-HPS bridge and ACP.

The project is of two parts:

HPS software (standalone C):<br />
A program with master role to manage the transfer and process the data.

FPGA hardware logic design (Verilog and Intel IP):<br />
A design with slave role to transfer data from FPGA to HPS over the FPGA-to-HPS bridge (F2H bridge) and Accelerator Coherency Port (ACP).  Data is transferred from FPGA embedded RAM (as block RAM) to HPS SDRAM.

## Results

The highest that I managed to get are these transfer throughput results:
- F2H bridge + ACP, 128-bit, 200MHz, 128MB: **775.01 MB/s**

For more results see the Excel file in the results folder.

## Guide

You can find the guide on my website:
[https://truhy.co.uk](https://truhy.co.uk)
