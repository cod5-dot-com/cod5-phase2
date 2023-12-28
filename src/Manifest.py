target = "altera"
action = "synthesis"

syn_family = "CYCLONE 10 LP"
syn_device = "10CL016Y"
syn_grade = "C8G"
syn_package = "U256"
syn_top = "mkrvidor4000_top"
syn_project = "cod5"
syn_tool = "quartus"

quartus_preflow = "./cod5/pinout.tcl"
quartus_postmodule = "./cod5/module.tcl"

modules = {
  "local" : [
    "./cod5",
  ],
}

