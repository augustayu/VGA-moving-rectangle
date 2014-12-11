`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:08:50 12/07/2014 
// Design Name: 
// Module Name:    VGA 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module VGA(
input clk, rst, 
input [7:0] rect_color,
output reg hsync,vsync,
output reg [7:0] color
    );

reg [9:0] hgrid = 0; // 800 TS , x 
reg [9:0] vgrid = 0; // 521 Ts , y
reg clk_4fp = 0;
reg [1:0] count = 0;
//分频 25M Hz
always @ (posedge clk or posedge rst) begin
  if(rst) 
      count <= 0; 
  else 
 count <= count + 1; 
end

always @ (posedge clk or posedge rst) begin
  if(rst)
  clk_4fp <= 0;  
  else begin 
  
    if (count[1] == 1)
	    clk_4fp <= 1;
	 else
	    clk_4fp <= 0;
end 
    
end

 // 扫描整个屏幕，包括非显示区,确定什么时候
always @ (posedge clk_4fp or posedge rst) begin
  if(rst) begin 
    hgrid <= 0;
	 vgrid <= 0;
 
  end
  else begin
  //根据basic VGA controller的电路图，在水平方向扫描一次后，使得垂直方向开始扫描
  // 因为水平方向是时钟计数的，垂直方向是根据水平方向的脉冲计数的
    if(hgrid >= 800) begin 
	    hgrid <= 0;
		 vgrid <= (vgrid >= 521? 0 : vgrid + 1'b1);
	 end 
    else
	    hgrid <= hgrid + 1'b1;
  end
end

//设置行选，列选信号有效。 由于有建立的Tpw时间，所以要把Tpw(脉冲宽度）时间段内的坐标视为无效
always @(posedge clk_4fp or posedge rst) begin
if(rst) begin 
  hsync <= 0;
  vsync <= 0;
end
else begin
  if(hgrid < 752 &&hgrid  >= 656) // Tpw 脉冲宽度
     hsync <= 0;
  else 
     hsync <= 1;
	  
  if(vgrid < 492 && vgrid >= 490 )
     vsync <= 0;
  else 
     vsync <= 1;
end

end


////////////////////////////////////////////
// 显示移动矩形

parameter  WIDTH = 32, //矩形长
           HEIGHT = 24,  //矩形宽
			  // 显示区域的边界
			  DISV_TOP = 10'd480,  // 520 - Tfp
			  DISV_DOWN =10'd0,  // Tbp + Tpw -1
			  DISH_LEFT = 10'd0, // Tbp + Tpw -1
			  DISH_RIGHT = 10'd640; // 799 -Tfp
			  
//初始矩形的位置，在显示区的左下角			   
reg [9:0] topbound = DISV_DOWN + HEIGHT;
reg [9:0] downbound = DISV_DOWN ;
reg [9:0] leftbound = DISH_LEFT ;
reg [9:0] rightbound = DISH_LEFT + WIDTH ;
//初始方向为东南方向
reg [1:0] movexy = 2'b11;
/*
根据时间选择不同范围坐标的像素显示颜色，使其成为一个移动的矩形。
由于是60/s, vsync的Ts恰好是移动1px所花的时间，所以用vsync信号的上升沿判断
*/

//确立每一个像素时钟里矩形的坐标范围

always @ (posedge vsync or posedge rst) begin
if(rst) begin 
   topbound = DISV_DOWN + HEIGHT ;
	downbound = DISV_DOWN;
	leftbound = DISH_LEFT;
	rightbound = DISH_LEFT + WIDTH ;
	movexy = 2'b11;
 
end

else begin
     //碰到边界，改变方向
	 case(movexy[1:0])
	 2'b11: begin // 东南
	         if (topbound == DISV_TOP && rightbound < DISH_RIGHT )
				    movexy = 2'b10;
				else if (topbound < DISV_TOP && rightbound == DISH_RIGHT )
				    movexy = 2'b01;
			   else if (topbound == DISV_TOP && rightbound == DISH_RIGHT )
				    movexy = 2'b00;
	        end
	 2'b10: begin // 东北
	         if (downbound  == DISV_DOWN&& rightbound < DISH_RIGHT )
				    movexy = 2'b11;
				else if (downbound > DISV_DOWN && rightbound == DISH_RIGHT )
				    movexy = 2'b00;
			   else if (downbound == DISV_DOWN && rightbound == DISH_RIGHT )
				    movexy = 2'b01;
	        end
	 2'b00: begin // 西北
	         if (downbound == DISV_DOWN && leftbound > DISH_LEFT )
				    movexy = 2'b01;
				else if (downbound > DISV_DOWN  && leftbound == DISH_LEFT )
				    movexy = 2'b10;
			   else if (downbound == DISV_DOWN && leftbound == DISH_LEFT )
				    movexy = 2'b11;
	        end
	 2'b01:  begin // 西南
	         if (topbound == DISV_TOP && leftbound > DISH_LEFT )
				    movexy = 2'b00;
				else if (topbound < DISV_TOP && leftbound == DISH_LEFT )
				    movexy = 2'b11;
			   else if (topbound == DISV_TOP && leftbound == DISH_LEFT )
				    movexy = 2'b10;
	        end
	 default: movexy = 2'b11;
	 endcase
	 
	  topbound <= topbound + ( movexy[0]? 1 : -1 );
	  downbound <= downbound + ( movexy[0]? 1 : -1 );
	  leftbound <= leftbound + ( movexy[1]? 1 : -1 );
     rightbound <= rightbound + ( movexy[1]? 1 : -1 );	

end

end

// 确定扫描到哪一个像素该显示什么颜色
always @(posedge clk_4fp or posedge rst) begin
if(rst)
     color <= 8'b0000_0000; 
	  
else begin
if (hgrid >= DISH_LEFT  && hgrid <= DISH_RIGHT  && vgrid >= DISV_DOWN && vgrid <= DISV_TOP) begin
    if(hgrid >= leftbound && hgrid <= rightbound && vgrid >= downbound && vgrid <= topbound)
	   color <= rect_color;  
	 else 		
	   color <= 8'b0000_0011; //blue
end
else begin
   color <= 8'b0000_0000;
end

end
 

end

endmodule




