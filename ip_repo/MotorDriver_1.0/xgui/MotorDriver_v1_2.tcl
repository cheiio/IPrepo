
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/MotorDriver_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI-related Variables}]
  set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S00_AXI_DATA_WIDTH}
  set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Width of S_AXI address bus} ${C_S00_AXI_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}

  #Adding Page
  set Driver-related_Variables [ipgui::add_page $IPINST -name "Driver-related Variables"]
  ipgui::add_param $IPINST -name "nMOTORS" -parent ${Driver-related_Variables}
  ipgui::add_param $IPINST -name "sys_clk" -parent ${Driver-related_Variables}
  ipgui::add_param $IPINST -name "pwm_freq" -parent ${Driver-related_Variables}
  ipgui::add_param $IPINST -name "enable_axi" -parent ${Driver-related_Variables}


}

proc update_PARAM_VALUE.pwm_freq { PARAM_VALUE.pwm_freq PARAM_VALUE.pwm_freq PARAM_VALUE.sys_clk } {
	# Procedure called to update pwm_freq when any of the dependent parameters in the arguments change
	
	set pwm_freq ${PARAM_VALUE.pwm_freq}
	set sys_clk ${PARAM_VALUE.sys_clk}
	set values(pwm_freq) [get_property value $pwm_freq]
	set values(sys_clk) [get_property value $sys_clk]
	if { [gen_USERPARAMETER_pwm_freq_ENABLEMENT $values(pwm_freq) $values(sys_clk)] } {
		set_property enabled true $pwm_freq
	} else {
		set_property enabled false $pwm_freq
	}
}

proc validate_PARAM_VALUE.pwm_freq { PARAM_VALUE.pwm_freq } {
	# Procedure called to validate pwm_freq
	return true
}

proc update_PARAM_VALUE.bits_resolution { PARAM_VALUE.bits_resolution } {
	# Procedure called to update bits_resolution when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.bits_resolution { PARAM_VALUE.bits_resolution } {
	# Procedure called to validate bits_resolution
	return true
}

proc update_PARAM_VALUE.enable_axi { PARAM_VALUE.enable_axi } {
	# Procedure called to update enable_axi when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.enable_axi { PARAM_VALUE.enable_axi } {
	# Procedure called to validate enable_axi
	return true
}

proc update_PARAM_VALUE.motor_addr_with { PARAM_VALUE.motor_addr_with } {
	# Procedure called to update motor_addr_with when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.motor_addr_with { PARAM_VALUE.motor_addr_with } {
	# Procedure called to validate motor_addr_with
	return true
}

proc update_PARAM_VALUE.nMOTORS { PARAM_VALUE.nMOTORS } {
	# Procedure called to update nMOTORS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.nMOTORS { PARAM_VALUE.nMOTORS } {
	# Procedure called to validate nMOTORS
	return true
}

proc update_PARAM_VALUE.sys_clk { PARAM_VALUE.sys_clk } {
	# Procedure called to update sys_clk when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.sys_clk { PARAM_VALUE.sys_clk } {
	# Procedure called to validate sys_clk
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.sys_clk { MODELPARAM_VALUE.sys_clk PARAM_VALUE.sys_clk } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.sys_clk}] ${MODELPARAM_VALUE.sys_clk}
}

proc update_MODELPARAM_VALUE.pwm_freq { MODELPARAM_VALUE.pwm_freq PARAM_VALUE.pwm_freq } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.pwm_freq}] ${MODELPARAM_VALUE.pwm_freq}
}

proc update_MODELPARAM_VALUE.nMOTORS { MODELPARAM_VALUE.nMOTORS PARAM_VALUE.nMOTORS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.nMOTORS}] ${MODELPARAM_VALUE.nMOTORS}
}

proc update_MODELPARAM_VALUE.bits_resolution { MODELPARAM_VALUE.bits_resolution PARAM_VALUE.bits_resolution } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.bits_resolution}] ${MODELPARAM_VALUE.bits_resolution}
}

proc update_MODELPARAM_VALUE.motor_addr_with { MODELPARAM_VALUE.motor_addr_with PARAM_VALUE.motor_addr_with } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.motor_addr_with}] ${MODELPARAM_VALUE.motor_addr_with}
}

proc update_MODELPARAM_VALUE.enable_axi { MODELPARAM_VALUE.enable_axi PARAM_VALUE.enable_axi } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.enable_axi}] ${MODELPARAM_VALUE.enable_axi}
}

