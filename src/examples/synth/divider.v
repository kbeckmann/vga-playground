//-----------------------------------------------------------------------------
//-- Divisor de frecuencia generico
//-- (c) BQ. August 2015. written by Juan Gonzalez (obijuan)
//-----------------------------------------------------------------------------
//-- GPL license
//-----------------------------------------------------------------------------


//-- Megaherzios  MHz
`define F_4MHz 3
`define F_3MHz 4
`define F_2MHz 6
`define F_1MHz 12

//-- Kilohercios KHz
`define F_4KHz 3_000
`define F_3KHz 4_000
`define F_2KHz 6_000
`define F_1KHz 12_000

//-- Hertzios (Hz)
`define F_2Hz   6_000_000
`define F_1Hz   12_000_000


//-- Entrada: clk_in. Señal original
//-- Salida: clk_out. Señal de frecuencia 1/M de la original
module divider(input wire clk_in, output wire clk_out);

//-- Valor por defecto del divisor
//-- Lo ponemos a 1 Hz
parameter M = `F_1Hz;

//-- Numero de bits para almacenar el divisor
//-- Se calculan con la funcion de verilog $clog2, que nos devuelve el 
//-- numero de bits necesarios para representar el numero M
//-- Es un parametro local, que no se puede modificar al instanciar
localparam N = $clog2(M);

//-- Registro para implementar el contador modulo M
reg [N-1:0] divcounter = 0;

//-- Contador módulo M
always @(posedge clk_in)
  divcounter <= (divcounter == M - 1) ? 0 : divcounter + 1;

//-- Sacar el bit mas significativo por clk_out
assign clk_out = divcounter[N-1];

endmodule

//-- Contador módulo M: Otra manera de implementarlo
/*
always @(posedge clk_in)
  if (divcounter == M - 1) 
    divcounter <= 0;
  else 
    divcounter <= divcounter + 1;
*/

