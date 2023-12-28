create_clock -name CLK_48MHZ -period 20.833ns [get_ports {CLK_48MHZ}]

derive_pll_clocks

derive_clock_uncertainty

# set_clock_groups -asynchronous -group {clockone} -group { mem_pll|altpll_component|auto_generated|pll1|clk[0]} 

