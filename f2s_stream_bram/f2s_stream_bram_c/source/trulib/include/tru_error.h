/*
	MIT License

	Copyright (c) 2023 Truong Hy

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	Version: 20230319

	Tru library error codes.
*/

#ifndef TRU_ERROR_H
#define TRU_ERROR_H

// My error codes
typedef enum tru_error_code_e{
	TRU_ERROR_NONE,
	TRU_MSGQ_ALLOC_FAILURE,
	TRU_UART_ERROR_RX_BUF_ALLOC_FAILURE,
	TRU_UART_ERROR_TX_BUF_ALLOC_FAILURE,
	TRU_UART_ERROR_LINE_STATUS_OE,  // Overrun Error
	TRU_UART_ERROR_LINE_STATUS_PE,  // Parity Error
	TRU_UART_ERROR_LINE_STATUS_FE,  // Framing Error
	TRU_UART_ERROR_LINE_STATUS_RFE,  // Receiver FIFO Error
	TRU_UART_ERROR_TX_FIFO_ERROR,
	TRU_UART_ERROR_TX_BUF_FULL,
	TRU_USB_PCD_ERROR_INVALID_USB_NUM
}tru_error_code_t;

#endif