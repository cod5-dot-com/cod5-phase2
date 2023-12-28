module spi_tb();
// Declare inputs as regs and outputs as wires
reg clock,  dummy, busy;
reg RESETn;
wire [7:0] bus1;
wire busy1;
wire echo;
wire FLASH_MOSI;
reg FLASH_MISO;
wire FLASH_SCK;
wire FLASH_CS;
wire FLASH_HOLD;
wire FLASH_WP;

// Initialize all variables
initial begin   
  $dumpfile("spi_tb.vcd");
  $dumpvars(0,spi_tb);     
  $display ("time\t clock clear count Q");
  $monitor ("%g\t %b   %b     %b      %b",
	  $time, clock, RESETn, FLASH_MISO, FLASH_MOSI);

  clock = 1; 
  RESETn = 0;
  dummy = 0;
  busy = 1;
  FLASH_MISO = 1;

  #15 RESETn = 1;
  #5 dummy = 1;
  busy=0;
  #400 RESETn = 0;
  #5 $finish;      // Terminate simulation
end

// Clock generator
always begin
  #5 clock = ~clock; // Toggle clock every 5 ticks
end

// Connect DUT to test bench
spi U_spi (
	.clk(clock),
	.reset(~RESETn),
	.cmd_read(1'b1),
	.cmd_write(dummy && ~busy),
	.mosi(FLASH_MOSI),
	.miso(FLASH_MISO),
	.sclk(FLASH_SCK),
	.cs_n(FLASH_CS),
	.hold_n(FLASH_HOLD),
	.wp_n(FLASH_WP),
	.bus_in(8'h90),
	.bus_out(bus1),
	.busy_write(busy1),
	.data_avail(echo)
);

endmodule

