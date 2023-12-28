action="simulation"
sim_tool = "iverilog"
top_module = "spi_tb"

sim_post_cmd = "vvp spi_tb.vvp; gtkwave spi_tb.vcd"

files = [
        "spi_tb.v",
        "../../src/cod5/spi.v",
]

