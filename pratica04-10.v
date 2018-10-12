module reg6 ( input [5:0] data, input clk, input rst, input en, output [5:0] q);
reg [5:0] q; 
always @(posedge clk or negedge rst) 
begin
 if(rst==1'b0)
  q <= 6'b0; 
 else if ( en  == 1'b1 ) // enable
  q <= data; 
end 
endmodule

module reg5 ( input [4:0] data, input clk, input rst, input en, output [4:0] q);
reg [4:0] q; 
always @(posedge clk or negedge rst) 
begin
 if(rst==1'b0)
  q <= 5'b0; 
 else if ( en  == 1'b1 ) //enable
  q <= data; 
end 
endmodule 

module MaquinaDeVendas(input clk, reset, input [4:0] moeda, output VendeuSucesso, next);
reg next;
reg [2:0] state;
wire cmp, en1;
wire [5:0] sin, sout;
reg6 saldo(sin, clk, reset, en1,sout);
parameter init=3'd0, pedido=3'd1, soma=3'd2, verificasaldo=3'd3, vendeu=3'd4;
assign sin = moeda + sout;
assign cmp = (sout >= 6'd40);
assign VendeuSucesso = (state == vendeu)?1:0;
assign en1 = (state === soma);

always @(posedge clk or negedge reset)
     begin
          if (reset==0)
               state = init;
          else
               case (state)
                    init: begin
			    next = 0; if(moeda==5'd0) state = pedido;
                    end
                    pedido: begin
                      next = 1; 
		      if(moeda>5'd0) state = soma;
                    end
                    soma: 
                       state = verificasaldo;
                    verificasaldo: begin
			if(cmp==1) state = vendeu;
                        else state = init;
                    vendeu:
                         state = init;
               endcase
     end
endmodule

module Memoria( line,  dout , reset);
input [4:0] line; // 32 linhas
output [4:0] dout;
input reset;
reg [4:0] memory[0:31]; // 32 linhas com 5 bits 
reg [4:0] dout;

always @ (*)
  begin 
  dout <= memory[line];
  end

always @( posedge reset) 
			if(reset) // inicia  para testes
				begin
				  memory[0] <= 5'd5;
				  memory[1] <= 5'd20;
				  memory[2] <= 5'd5;
				  memory[3] <= 5'd10;
				  memory[4] <= 5'd20;
				  memory[5] <= 5'd20;
				  memory[6] <= 5'd10;
				  memory[7] <= 5'd5;
				end
endmodule

module MaquinaDeCompra(input clk, rst, next, vendeu, output [4:0] moeda);
reg [2:0] state;
wire enM,inc;
wire [4:0] mint, ptrIN, ptrOUT;
parameter init=3'd0, readmem=3'd1, incrPtr=3'd2, aguardando=3'd3;
reg5 m(mint, clk, rstM, enM, moedas); // moedas
Memoria mem(ptrOUT, mint, rst);
reg5 PTR(ptrIN, clk, rst, inc, ptrOUT); // moedas
assign ptrIN = ptrOUT + 1;
assign rstM = (state == init )?0:1;
assign enM = (state == readmem )?1:0;
assign inc = (state == incrPtr )?1:0;

// maquina
always @(posedge clk or negedge rst)
     begin
          if (rst==0)
               state = init;
          else
               case (state)
                    init:
                         if ( next ) state = readmem;
                    readmem:
                         state = incrPtr;
                    incrPtr:
                         state = aguardando;
		    aguardando:
			    if(next == 0) state = init;
	       endcase
     end
endmodule



module Vendas(input clk, reset, output t);
wire n;
wire [4:0] valormoeda;
MaquinaDeVendas m1(clk, reset, valormoeda, t, n);
MaquinaDeCompra m2(clk, reset, n, t, valormoeda);

endmodule

module main;
reg c,res;
wire v;

Vendas FSM(c,res,v);


initial
    c = 1'b0;
  always
    c= #(1) ~c;


  initial
    begin
     $monitor($time," c %b res %b v %b",c,res,v);
      #1 res=0;
      #1 res=1;
      #40;
      $finish ;
    end
endmodule
