`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author        : EmbedFire
//Create Date    : 2019/09/03
// Module Name   : uart_sd
// Project Name  : uart_sd
// Target Devices: Xilinx XC6SLX16
// Tool Versions : ISE 14.7
// Description   : 串口读写SD卡顶层模块
//
// Revision      : V1.0
// Additional Comments:
// 
// 实验平台: 野火_踏浪Pro_FPGA开发板
// 公司    : http://www.embedfire.com
// 论坛    : http://www.firebbs.cn
// 淘宝    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module  uart_sd
(
    input   wire            sys_clk     ,   //输入工作时钟,频率50MHz
    // input   wire            sys_rst_n   ,   //输入复位信号,低电平有效
    input                   reset       ,

    input   wire            uart_rx          ,   //串口发送数据
    output  wire            uart_tx          ,   //串口接收数据


    // MicroSD
    output sd_clk,
    output sd_cmd,      // MOSI
    input  sd_dat0,     // MISO
    output sd_dat1,     // 1
    output sd_dat2,     // 1
    output sd_dat3,     // 1
    // input   wire            sd_miso     ,   //主输入从输出信号
    // output  wire            sd_clk      ,   //SD卡时钟信号
    // output  wire            sd_cs_n     ,   //片选信号
    // output  wire            sd_mosi     ,   //主输出从输入信号
    output  wire [7:0]  led

);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter                        CLK_FRE  = 50;//Mhz
parameter                        UART_FRE = 115200;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       WAIT =  2;   //wait 1 second and send uart received data

wire             sd_miso    ; //主输入从输出信号
//  wire            sd_clk     ; //SD卡时钟信号
wire             sd_cs_n    ; //片选信号
wire             sd_mosi    ; //主输出从输入信号

//wire  define
wire            rx_flag         ;   //写fifo写入数据标志信号
wire    [7:0]   rx_data         ;   //写fifo写入数据
wire            wr_req          ;   //sd卡数据写请求
wire            wr_busy         ;   //sd卡写数据忙信号
wire            wr_en           ;   //sd卡数据写使能信号
wire    [31:0]  wr_addr         ;   //sd卡写数据扇区地址
wire    [15:0]  wr_data         ;   //sd卡写数据
wire            rd_data_en      ;   //sd卡读出数据标志信号
wire    [15:0]  rd_data         ;   //sd卡读出数据
wire            rd_busy         ;   //sd卡读数据忙信号
wire            rd_en           ;   //sd卡数据读使能信号
wire    [31:0]  rd_addr         ;   //sd卡读数据扇区地址
wire            tx_flag         ;   //读fifo读出数据标志信号
// wire    [7:0]   tx_data         ;   //读fifo读出数据
reg[7:0]    tx_data;
wire            clk_50m         ;   //生成50MHz时钟
wire            clk_50m_shift   ;   //生成50MHz时钟,相位偏移180度
wire            locked          ;   //时钟锁定信号
wire            rst_n           ;   //复位信号
wire            init_end        ;   //SD卡初始化完成信号
wire            CLK_OUT2;
wire                             rx_data_ready;
//rst_n:复位信号,低有效
assign  rst_n = ~reset && locked;
assign  sd_miso=sd_dat0;
assign  sd_cmd =sd_mosi;
assign  sd_dat3=sd_cs_n;
assign  sd_dat1=1'bz;
assign  sd_dat2=1'bz;
assign rx_data_ready = 1'b1;//always can receive data,
//********************************************************************//
//************************** Instantiation ***************************//
//********************************************************************//
//------------- clk_gen_inst -------------
// clk_gen clk_gen_inst
// (
//     .RESET     (~sys_rst_n     ),  //复位信号,高有效
//     .CLK_IN1   (sys_clk        ),  //输入系统时钟,50MHz

//     .CLK_OUT1  (clk_50m        ),  //生成50MHz时钟
//     .CLK_OUT2  (clk_50m_shift       ),  //生成50MHz时钟,相位偏移180度
//     .LOCKED    (locked         )   //时钟锁定信号
//     );
    Gowin_PLL your_instance_name(
        .lock(locked), //output lock
        .clkout0(clk_50m), //output clkout0
        .clkout1(clk_50m_shift ), //output clkout1
        .clkin(sys_clk), //input clkin
        .reset(reset) //input reset //高电平有效，reset一开始就是低电平
    );


//------------- data_rw_ctrl_inst -------------
data_rw_ctrl    data_rw_ctrl_inst
(
    .sys_clk     (clk_50m   ),  //输入工作时钟,频率50MHz
    .sys_rst_n   (rst_n     ),  //输入复位信号,低电平有效
    .init_end    (init_end  ),  //SD卡初始化完成信号

    .rx_flag     (rx_flag   ),  //写fifo写入数据标志信号
    .rx_data     (rx_data   ),  //写fifo写入数据
    .wr_req      (wr_req    ),  //sd卡数据写请求
    .wr_busy     (wr_busy   ),  //sd卡写数据忙信号

    .wr_en       (wr_en     ),  //sd卡数据写使能信号
    .wr_addr     (wr_addr   ),  //sd卡写数据扇区地址
    .wr_data     (wr_data   ),  //sd卡写数据

    .rd_data_en  (rd_data_en),  //sd卡读出数据标志信号
    .rd_data     (rd_data   ),  //sd卡读出数据
    .rd_busy     (rd_busy   ),  //sd卡读数据忙信号
    .rd_en       (rd_en     ),  //sd卡数据读使能信号
    .rd_addr     (rd_addr   ),  //sd卡读数据扇区地址
    .tx_flag     (tx_flag   ),  //读fifo读出数据标志信号
    .tx_data     (  )   //读fifo读出数据
);

//------------- sd_ctrl_inst -------------

//SD卡顶层控制模块
    sd_ctrl_top u_sd_ctrl_top(
        .clk_ref           (clk_50m),
        .clk_ref_180deg    (clk_50m_shift),
        .rst_n             (rst_n),
        //SD卡接口
        .sd_miso           (sd_miso),
        .sd_clk            (sd_clk),
        .sd_cs             (sd_cs_n),
        .sd_mosi           (sd_mosi),
        //用户写SD卡接口
        .wr_start_en       (wr_en),        //不需要写入数据,写入接口赋值为0
        .wr_sec_addr       (wr_addr),
        .wr_data           (wr_data),
        .wr_busy           (wr_busy),
        .wr_req            (wr_req),
        //用户读SD卡接口
        .rd_start_en       (rd_en),
        .rd_sec_addr       (rd_addr),
        .rd_busy           (rd_busy),
        .rd_val_en         (rd_data_en),
        .rd_val_data       (rd_data),    

        .sd_init_done      (init_end)
        );     

assign  led[0] =~init_end;
assign  led[1] =~rx_flag;
assign  led[2] =~tx_flag;
assign  led[3] =~ wr_busy;
assign  led[4] = ~rd_data_en;
assign  led[6]  = ~wr_en;
assign  led[7]  = ~wr_req;

//------------- uart_rx_inst -------------

wire    rx_data_valid;
uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (clk_50m                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid           ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (uart_rx                  )
);

//------------- uart_tx_inst -------------

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (clk_50m                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);

reg[31:0]                        wait_cnt;
reg[3:0]                         state;
reg[7:0]                         tx_cnt;
reg    tx_data_valid;

always@(posedge clk_50m or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			
			tx_data <= 16'hff;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < 16)//Send 12 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)//last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;

			if(rx_data_valid == 1'b1)
			begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;   // send uart received data
			end
			else if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if(wait_cnt >= CLK_FRE * 1000_000) // wait for 1 second
				state <= SEND;
		end
		default:
			state <= IDLE;
	endcase
end


endmodule