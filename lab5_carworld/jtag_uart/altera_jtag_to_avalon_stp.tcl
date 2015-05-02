# -----------------------------------------------------------------
# altera_jtag_to_avalon_stp.tcl
#
# 9/16/2011 D. W. Hawkins (dwh@ovro.caltech.edu)
#
# Altera JTAG-to-Avalon bridge commands for use under quartus_stp.
#
# Altera provides SystemConsole Tcl procedures for accessing the
# following JTAG services;
#
#  * bytestream (JTAG-to-Avalon-ST data stream)
#  * jtag_debug (JTAG-to-Avalon-ST registers)
#  * master     (JTAG-to-Avalon-MM)
#
# However, no corresponding quartus_stp routines are provided.
#
# quartus_stp does have Tcl support for the sld_virtual_jtag node,
# and for JTAG IR and DR shifts. The JTAG routines are used here
# to provide access to the JTAG-to-Avalon-ST/MM bridges.
#
# -----------------------------------------------------------------
# Notes:
# ------
#
# 1. To make these procedures visible in other Tcl scripts, use
#
#     package require altera_jtag_to_avalon_stp
#     namespace import altera_jtag_to_avalon_stp::*
#
#    If the package cannot be found, make sure to have your
#    TCLLIBPATH enviroment variable set, and an appropriate
#    setting in the pkgIndex.tcl found at that location.
#
#    Note that under Windows, the TCLLIBPATH variable must use
#    use forward slashes in the path name, otherwise the package
#    require command fails.
#
# 2. The Tcl procedures in this package are implemented using
#    low-level procedures from the ::quartus::jtag 1.0 package.
#
#    The package is described in the Quartus Help under;
#
#    Devices and Adapters->API Functions For Tcl
#
#    The package is automatically included by quartus_stp.
#
#    The low-level JTAG package only supports a single device 
#    open per process. This is reflected in the API in that
#    open_device does not return a handle and close_device
#    does require an argument (i.e., the handle of the device to
#    close). The low-level open_device procedure will fail if
#    called again before close_device is called.
#
#    To control multiple FPGAs from within a single quartus_stp
#    session, you have to interact with the FPGAs via an
#    open->action->close sequence.
#
#    This Tcl package does not return a handle for the device
#    being controlled, since the underlying low-level JTAG routines
#    do not support it.
#
# -----------------------------------------------------------------
# References:
# -----------
#
# [1] Altera, "Virtual JTAG (sld_virtual_jtag) MegaFunction
#     User Guide", version 2.0, 2008.
#
# -----------------------------------------------------------------

package provide altera_jtag_to_avalon_stp 1.0

namespace eval altera_jtag_to_avalon_stp {

# -----------------------------------------------------------------
# Exported procedures
# -----------------------------------------------------------------
#
# The following procedures can be used without the namespace
# prefix by importing them using
#
# namespace import altera_jtag_to_avalon_stp::*
#
namespace export \
	version \
	jtag_open \
	jtag_close \
	jtag_idcode \
	jtag_usercode \
	jtag_pulse_nconfig \
	jtag_print_hub_info \
	jtag_print_node_info \
	jtag_number_of_nodes \
	jtag_node_id \
	jtag_node_is_bytestream \
	jtag_node_is_master \
	jtag_resetrequest \
	jtag_send \
	jtag_write \
	jtag_read

# -----------------------------------------------------------------
# Package state
# -----------------------------------------------------------------
#
# The 'jtag' variable is an array used to store various parameters.
#
variable jtag
set jtag(version) 1.0

# -----------------------------------------------------------------
# Get the package version
# -----------------------------------------------------------------
#
proc version {} {
	variable jtag
	return $jtag(version)
}

# -----------------------------------------------------------------
# JTAG open/close
# -----------------------------------------------------------------
#
proc jtag_open {{controller_index 0} {device_index 0}} {
	variable jtag

	# Close any open device
	if {[info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_close
	}

	# Get the list of JTAG controllers
	set hardware_names [get_hardware_names]
	
	# Select the JTAG controller
	set hardware_name [lindex $hardware_names $controller_index]
	
	# Get the list of FPGAs in the JTAG chain
	set device_names [get_device_names\
		-hardware_name $hardware_name]
	
	# Select the FPGA
	set device_name [lindex $device_names $device_index]

	puts "\nJTAG: $hardware_name, FPGA: $device_name"
	open_device -hardware_name $hardware_name\
		-device_name $device_name
	set jtag(open) 1
	return
}

# -----------------------------------------------------------------
# JTAG close
# -----------------------------------------------------------------
#
proc jtag_close {} {
	variable jtag
	if {[info exists jtag(open)]} {
		close_device
		unset jtag(open)
	}
	return
}

# -----------------------------------------------------------------
# Device IDCODE instruction
# -----------------------------------------------------------------
#
proc jtag_idcode {} {
	variable jtag
	if {![info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_open
	}
	device_lock -timeout 10000

	# Shift-IR: = IDCODE = 6
	device_ir_shift -ir_value 6 -no_captured_ir_value
	
	# Shift-DR: read 32-bits
	set val 0x[device_dr_shift -length 32 -value_in_hex]

	device_unlock
	return $val
}

# -----------------------------------------------------------------
# Device USERCODE instruction
# -----------------------------------------------------------------
#
#  * If its not set, then the expected value is 0xFFFFFFFF
#
#  * The USERCODE can be set using, eg.
# 	set_global_assignment -name STRATIX_JTAG_USER_CODE 12345678
#
proc jtag_usercode {} {
	variable jtag
	if {![info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_open
	}
	device_lock -timeout 10000

	# Shift-IR: = USERCODE = 7
	device_ir_shift -ir_value 7 -no_captured_ir_value
	
	# Shift-DR: read 32-bits
	set val 0x[device_dr_shift -length 32 -value_in_hex]

	device_unlock
	return $val
}

# -----------------------------------------------------------------
# Pulse CONFIG#
# -----------------------------------------------------------------
#
# There is no documentation on what to do with this command.
# The Shift-IR command alone does not do anything (until
# a subsequent command is issued). Issuing a shift on DR causes
# the configuration to be cleared.
#
proc jtag_pulse_nconfig {} {
	variable jtag
	if {![info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_open
	}
	device_lock -timeout 10000

	# Shift-IR: = PULSE_NCONFIG = 1
	device_ir_shift -ir_value 1 -no_captured_ir_value

	# Shift-DR: read 1-bitt
	device_dr_shift -length 1 -dr_value 0

	device_unlock
	return
}

# -----------------------------------------------------------------
# JTAG hub interrogation
# -----------------------------------------------------------------
#
# Read the HUB_INFO and SLD_NODE_INFO fields as discussed in
# Appendix A in the Virtual JTAG users guide. With the slight
# modification in the interpretation of the HUB_INFO sum(m, n)
# field, which is documented incorrectly. its just width-m.
#
proc jtag_hub_info {} {
	variable jtag
	if {![info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_open
	}

	# ----------------------
	# HUB_INFO
	# ----------------------
	
	device_lock -timeout 10000

	# Shift-IR: = USER1 = 0xE
	device_ir_shift -ir_value 14 -no_captured_ir_value

	# Shift-DR: write 64-bits
	device_dr_shift -length 64 -value_in_hex -dr_value 0000000000000000
	
	# Shift-IR: = USER0 = 0xC
	device_ir_shift -ir_value 12 -no_captured_ir_value

	# Shift-DR: read 4-bits, 8 times
	set data {}
	for {set i 0} {$i < 8} {incr i} {
		set byte [device_dr_shift -length 4 -value_in_hex]

		# Build up a hex string
		set data $byte$data
	}
	
	# String to 32-bit integer
	set data 0x$data
	
	# Decode the HUB_INFO fields
	set jtag(hub_info)        $data
	set jtag(hub_vir_width_m) [expr { $data        & 0xFF}]
	set jtag(hub_mfg_id)      [expr {($data >> 8)  & 0x7FF}]
	set jtag(hub_n_nodes)     [expr {($data >> 19) & 0xFF}]
	set jtag(hub_version)     [expr {($data >> 27) & 0x1F}]
	
	# Calculate the n-bit node address width
	set jtag(hub_vir_width_n) [expr {int(ceil(log10($jtag(hub_n_nodes)+1)/log10(2)))}]

	# ----------------------
	# SLD_NODE_INFO
	# ----------------------
	#
	# Using the number of nodes from HUB_INFO
	set node_info {}
	for {set i 0} {$i < $jtag(hub_n_nodes)} {incr i} {
	
		# Read out the SLD_NODE_INFO registers (4-bit nibble at a time)
		set data {}
		for {set j 0} {$j < 8} {incr j} {
			set byte [device_dr_shift -length 4 -value_in_hex]

			# Build up a hex string
			set data $byte$data
		}

		# String to 32-bit integer
		lappend node_info 0x$data
	}
	device_unlock

	# Put the 32-bit hex values into the global
	set jtag(node_info) $node_info

	# Decode the node info into fields
	for {set i 0} {$i < $jtag(hub_n_nodes)} {incr i} {
		set node [lindex $node_info $i]
		set jtag(node_${i}_inst)     [expr { $node      & 0xFF}]
		set jtag(node_${i}_mfg_id)   [expr {($node>>8)  & 0x7FF}]
		set jtag(node_${i}_id)       [expr {($node>>19) & 0xFF}]
		set jtag(node_${i}_version)  [expr {($node>>27) & 0x1F}]
		
	}

	# Read the purpose field of the JTAG-to-Avalon bridges
	for {set i 0} {$i < $jtag(hub_n_nodes)} {incr i} {
		# Search for node ID of 0x84
		if {$jtag(node_${i}_id) != 0x84} {
			continue
		}

		# Read the INFO register
		altera_jtag_to_avalon_stp::jtag_vir $i 3
		set info [altera_jtag_to_avalon_stp::jtag_vdr 0 11]

		# Extract the 3-bit PURPOSE field
		# * 0 = Avalon-ST
		# * 1 = Avalon-MM
		set jtag(node_${i}_purpose) [expr {($info >> 8) & 0x7}]
	}

	# IP names
	for {set i 0} {$i < $jtag(hub_n_nodes)} {incr i} {

		if {$jtag(node_${i}_id) == 0} {
		
			set jtag(node_${i}_name) "SignalTap II"
			
		} elseif {$jtag(node_${i}_id) == 0x08} {
		
			set jtag(node_${i}_name) "Virtual JTAG"
			
		} elseif {$jtag(node_${i}_id) == 0x84} {
		
			if {$jtag(node_${i}_purpose) == 0} {
				set jtag(node_${i}_name) "JTAG-to-Avalon-ST bridge"
			} elseif  {$jtag(node_${i}_purpose) == 1} {	
				set jtag(node_${i}_name) "JTAG-to-Avalon-MM bridge"
			}
		}
	}
	return
}

# -----------------------------------------------------------------
# Device interrogation
# -----------------------------------------------------------------
#
proc jtag_number_of_nodes {} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	return $jtag(hub_n_nodes)
}

proc jtag_node_id {index} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		return -1;
	}	
	return $jtag(node_${index}_id)
}

proc jtag_node_is_bytestream {index} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		return -1;
	}	

	# Check the node is ID 132 (0x84)
	if {$jtag(node_${index}_id) != 0x84} {
		return 0
	}
	
	# Check its an Avalon-ST bytestream device
	if {$jtag(node_${index}_purpose) != 0} {
		return 0
	}
	return 1
}

proc jtag_node_is_master {index} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		return -1;
	}	

	# Check the node is ID 132 (0x84)
	if {$jtag(node_${index}_id) != 0x84} {
		return 0
	}
	
	# Check its an Avalon-ST bytestream device
	if {$jtag(node_${index}_purpose) != 1} {
		return 0
	}
	return 1
}

# -----------------------------------------------------------------
# Display the JTAG hub and node information
# -----------------------------------------------------------------
#
proc jtag_print_hub_info {} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	puts ""
	puts "         Hub info: [format 0x%X $jtag(hub_info)]"
	puts "      VIR m-width: $jtag(hub_vir_width_m)"
	puts "      VIR n-width: $jtag(hub_vir_width_n)"
	puts "  Manufacturer ID: [format 0x%X $jtag(hub_mfg_id)]"
	puts "  Number of nodes: $jtag(hub_n_nodes)"
	puts "       IP Version: $jtag(hub_version)"
	puts ""
}


proc jtag_print_node_info {} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	
	# Loop over the list and print the fields
	puts ""
	for {set i 0} {$i < $jtag(hub_n_nodes)} {incr i} {
		set inst $jtag(node_${i}_inst)
		set mfg  $jtag(node_${i}_mfg_id)
		set id   $jtag(node_${i}_id)
		set ver  $jtag(node_${i}_version)
	
		puts "       Node index: [format "%4d" $i]"
		puts "    Node instance: [format "%4d (0x%X)" $inst $inst]"
		puts "Node manufacturer: [format "%4d (0x%X)" $mfg  $mfg]"
		puts "          Node ID: [format "%4d (0x%X)" $id   $id]"
		if {$id == 0x84} {
			set pur  $jtag(node_${i}_purpose)
			puts "     Node purpose: [format "%4d (0x%X)" $pur  $pur]"
		}
		puts "     Node version: [format "%4d (0x%X)" $ver  $ver]"
		puts ""
	}
}

# -----------------------------------------------------------------
# Virtual IR/DR control
# -----------------------------------------------------------------
#

# Virtual shift-IR
#
#  * load the JTAG IR with USER1 to select the Virtual IR
#  * load the VIR_CAPTURE instruction
#  * load the VIR_USER instruction
#
# 'index' is the node index as listed by jtag_print_node_info
#
proc jtag_vir {index val} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		puts "Error; invalid index $index!"
		return	
	}
	
	# Calculate the VIR instructions
	#
	#  [m+n+1:m]: node address (index + 1)
	#    [m-1:0]: user VIR value
	#
	# Field widths
	set m     $jtag(hub_vir_width_m)
	set n     $jtag(hub_vir_width_n)
	#
	# Mask out invalid bits
	set val   [expr {$val       & ((1 << $m) - 1)}]
	set index [expr {($index+1) & ((1 << $n) - 1)}]
	#
	# Construct the VIR_CAPTURE instruction
	set vir_capture [expr {($index << 3) | 3}]
	
	# Construct the VIR_USER instruction
	set vir_user [expr {($index << $m) | $val}]
	
	# Reformat the instructions to hex format with the
	# appropriate number of character nibbles
	set len         [expr {$m + $n}]
	set width       [expr {int(ceil(double($len)/4.0))}]
	set vir_capture [format "%.${width}X" $vir_capture]
	set vir_user    [format "%.${width}X" $vir_user]

	device_lock -timeout 1000
	
	# Shift-IR: = USER1 = 0xE (select VIR register)
	device_ir_shift -ir_value 14 -no_captured_ir_value

	# Shift-DR: write the VIR_CAPTURE value
	device_dr_shift -length $len -value_in_hex -dr_value $vir_capture -no_captured_dr_value
	
	# Shift-DR: write the VIR_USER value
	set ret [device_dr_shift -length $len -value_in_hex -dr_value $vir_user]
	
	device_unlock
	return 0x$ret
}

# Virtual shift-DR
#
#  * Note that you first need to select the VDR by
#    issuing a VIR command.
#
#  * JTAG-to-Avalon-ST bridge notes:
#
#    VIR value  Mode      Notes
#    ---------  --------  --------
#        1      LOOPBACK   writing 0x55555555 reads back as 0xAAAAAAAA,
#                          i.e., a right-shift of 1-bit due to the
#                          loopback register.
#
#        2      DEBUG      (3-bit register) read back 111b = 7 or 101b = 5.
#
#        3      INFO       (11-bit register).containing the 3-bit PURPOSE
#
#        4      CONTROL    (9-bit register)
#                           * write 0x100 to set resetrequest
#                           * write 0 to clear resetrequest
#
proc jtag_vdr {val {len 8}} {
	variable jtag
	if {![info exists jtag(open)]} {
		altera_jtag_to_avalon_stp::jtag_open
	}
	
	# Virtual shift-DR can be of arbitrary length, however, this
	# procedure assumes 'val' is a 32-bit integer value, hence
	# limit 'len' to 32-bits.
	#
	if {$len > 32} {
		error "Length must be less than or equal to 32"
	}
	
	# Mask invalid bits
	set val   [expr {$val & ((1 << $len) - 1)}]

	# Reformat the data to hex format with the
	# appropriate number of character nibbles
	set width [expr {int(ceil(double($len)/4.0))}]
	set val   [format "%.${width}X" $val]

	device_lock -timeout 1000

	# Shift-IR: = USER0 = 0xC (select VDR register)
	device_ir_shift -ir_value 12 -no_captured_ir_value

	# Shift-DR: write the VDR value
	set ret [device_dr_shift -length $len -value_in_hex -dr_value $val]

	device_unlock
	return 0x$ret
}

# -----------------------------------------------------------------
# JTAG-to-Avalon-ST interface commands
# -----------------------------------------------------------------
#
# Control the resetrequest output
#
#  * resetrequest is essentially a general purpose output
#    pin controlled by a bit in a register clocked by TCK
#  * the register is loaded by the JTAG state UDR, which
#    is a problem, as jtag_vdr leaves the JTAG TAP in the
#    UDR state, with no extra clocks. The jtag_vir command
#    is needed to produce a TCK edge to load the change in
#    resetrequest value.
#
proc jtag_resetrequest {index val} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		puts "Error; invalid index $index!"
		return	
	}

	# Check the node is ID 132 (0x84) (either ST or MM is ok)
	if {$jtag(node_${index}_id) != 0x84} {
		puts "Error; index $index is not a JTAG-to-Avalon-ST/MM bridge!"
		return
	}

	if {$val == 0} {
		# Select control mode
		altera_jtag_to_avalon_stp::jtag_vir $index 4	
		
		# Clear the control register
		altera_jtag_to_avalon_stp::jtag_vdr $index 9
		
		# Back to data mode (also causes transition though UDR)
		altera_jtag_to_avalon_stp::jtag_vir $index 0
	} else {
		# Select control mode
		altera_jtag_to_avalon_stp::jtag_vir $index 4	
		
		# Set the resetrequest bit
		altera_jtag_to_avalon_stp::jtag_vdr 0x100 9
		
		# Back to data mode (also causes transition though UDR)
		altera_jtag_to_avalon_stp::jtag_vir $index 0	
	}
	return
}

# JTAG-to-Avalon-ST bytestream send and receive
#
#  * The 'bytes' input is a list of bytes to transmit through
#    the JTAG interface to have appear on the Avalon-ST source
#    interface of the bridge
#
#  * The bridge uses the following special bytes
#
#      0x4A  IDLE code
#      0x4D  ESCAPE code
#
#    If either of these bytes exist in the bytes list, then
#    they need to be escaped by inserting the ESCAPE character
#    followed by the data XOR'ed with 0x20.
#
#  * The bridge expects bytestream data to start with a 16-bit
#    header indicating the write-length, read-length, and
#    scan-length. The scan-length is limited to lengths that
#    are multiples of 256-bytes.
#
# Example:
#   jtag_send 0 [list 0x11 0x22 0x33 0x44]
#
proc jtag_send {index bytes} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		puts "Error; invalid index $index!"
		return	
	}
	
	# Check the node is ID 132 (0x84)
	if {$jtag(node_${index}_id) != 0x84} {
		puts "Error; index $index is not a JTAG-to-Avalon-ST/MM bridge!"
		return
	}
	
	# Check its an Avalon-ST bytestream device
#	if {$jtag(node_${index}_purpose) != 0} {
#		puts "Error; index $index is not a JTAG-to-Avalon-ST bridge!"
#		return
#	}

	# ------------------------------------
	# Encode the bytestream
	# ------------------------------------
	#
	# First escape the data
	set len [llength $bytes]
	set bytes_jtag ""
	for {set i 0} {$i < $len} {incr i} {

		# Next transaction byte
		set byte [lindex $bytes $i]

		# Escape required?
		if {($byte == 0x4A) | ($byte == 0x4D)} {
			# Add an escape code
			lappend bytes_jtag 0x4D
			
			# Modify the byte
			set byte [expr {$byte ^ 0x20}]
		}

		# Add the byte in hex format
		lappend bytes_jtag [format "0x%.2X" $byte]
	}
	unset bytes
	
	# How much data is there now?
	set len [llength $bytes_jtag]
	#
	# For now, support JTAG packets of only 256-bytes
	if {$len > 256} {
		error "Length = $len is not supported yet!"
	}
	#	
	# Pad the remainder of the packet with IDLE codes
	for {set i $len} {$i < 256} {incr i} {
		lappend bytes_jtag 0x4A
	}
	#
	# Add the 16-bit JTAG header (for a 256-byte packet)
	set bytes_jtag [concat {0x00 0xFC} $bytes_jtag]

	# Convert the bytes into a string
	set len [llength $bytes_jtag]
	set bytes_str ""	
	foreach byte $bytes_jtag {
		set byte [format "%.2X" $byte]
		set bytes_str "${byte}${bytes_str}"
	}
	unset bytes_jtag

	# ------------------------------------
	# JTAG bytestream send/receive
	# ------------------------------------

	# Total Shift-DR data length in bits
	set len [expr {(256+2)*8}]

	# DATA mode	
	altera_jtag_to_avalon_stp::jtag_vir $index 0
	
	# Send the data
	device_lock -timeout 1000

	# Shift-IR: = USER0 = 0xC (select VDR register)
	device_ir_shift -ir_value 12 -no_captured_ir_value

	# Shift-DR: write the VDR value
	set rsp [device_dr_shift -length $len -value_in_hex -dr_value $bytes_str]

	device_unlock
	unset bytes_str

	# ------------------------------------
	# Receive data formatting
	# ------------------------------------
	
	# Convert the response string into return data bytes
	#
	# * delete the two header bytes (start at index 2)
	# * delete IDLE characters
	# * interpret ESCAPE characters and modify the following byte
	#
	set bytes_rsp ""
	set escape 0
	set i 2
	while {$i < 258} {
	
		# Read a byte from the response
		set first [expr {2*(256+2-$i)-2}]
		set last  [expr {2*(256+2-$i)-1}]
		incr i
		set byte 0x[string range $rsp $first $last]
		
		# Skip idle codes
		if {$byte == 0x4A} {
			continue;
		}
		
		# Is this an escape char?
		if {$escape == 0} {
			if {$byte == 0x4D} {
				set escape 1
				continue;
			}
		} else {
			# Character was escaped, so modify the byte
			set byte [expr {$byte ^ 0x20}]
			set escape 0
		}
		
		# Add the byte to the response data
		lappend bytes_rsp [format 0x%.2X $byte]
	}

	# Return the decoded bytes
	return $bytes_rsp
}

# JTAG-to-Avalon-MM 32-bit write
proc jtag_write {index addr data} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		puts "Error; invalid index $index!"
		return	
	}
	
	# Check the node is ID 132 (0x84)
	if {$jtag(node_${index}_id) != 0x84} {
		puts "Error; index $index is not a JTAG-to-Avalon-ST/MM bridge!"
		return
	}
	
	# Check its an Avalon-MM master device
	if {$jtag(node_${index}_purpose) != 1} {
		puts "Error; index $index is not a JTAG-to-Avalon-MM bridge!"
		return
	}

	# ------------------------------------
	# Send data formatting
	# ------------------------------------

	# Transaction bytes
	#
	#  Byte   Value  Description
	# ------  -----  -----------
	#    [0]  0x00   Transaction code = write, no increment
	#    [1]  0x00   Reserved
	#  [3:2]  0x0004 16-bit size (big-endian byte order)
	#  [7:4]  32-bit address (big-endian byte order)
	# [11:8]  32-bit data (little-endian byte order)
	#
	set bytes {0 0 0 4}
	for {set i 0} {$i < 4} {incr i} {
		lappend bytes [expr {($addr >> 8*(3-$i)) & 0xFF}]
	}
	for {set i 0} {$i < 4} {incr i} {
		lappend bytes [expr {($data >> 8*$i) & 0xFF}]
	}

	# Convert to Packet bytes
	#
	# Byte   Value  Description
	# -----  -----  ----------
	#  [0]   0x7C   Channel
	#  [1]   0x00   Channel number
	#  [2]   0x7A   Start-of-packet
	#  [X:3]        Transaction bytes with escape codes
	#        0x7B   End-of-packet
	#  [Y]          Last transaction byte (and escape code)
	#
	set len [llength $bytes]
	set bytes_pkt {0x7C 0x00 0x7A}
	for {set i 0} {$i < $len} {incr i} {

		# Next transaction byte
		set byte [lindex $bytes $i]
		
		# Add the end-of-packet code before the last item
		# of data (and its escape code)
		if {$i == $len-1} {
			lappend bytes_pkt 0x7B
		}

		# Escape required?
		if {($byte >= 0x7A) && ($byte <= 0x7D)} {
			# Add an escape code
			lappend bytes_pkt 0x7D
			
			# Modify the byte
			set byte [expr {$byte ^ 0x20}]
		}

		# Add the byte in hex format
		lappend bytes_pkt [format "0x%.2X" $byte]
	}
	unset bytes
	
	# ------------------------------------
	# JTAG bytestream send/receive
	# ------------------------------------
	#
	set bytes_rsp [altera_jtag_to_avalon_stp::jtag_send $index $bytes_pkt]
	unset bytes_pkt
		
	# ------------------------------------
	# Decode the bytes-to-packet response
	# ------------------------------------
	#
	# Bytes  Value  Description
	# -----  -----  -----------
	#  [0]    0x7C  Channel
	#  [1]    0x00  Channel number
	#  [2]    0x7A  Start-of-packet
	#  [3]    0x80  Transaction code with MSB set
	#  [4]    0x00  Reserved
	#  [5]    0x00  Size[15:8]
	#  [6]    0x7B  End-of-packet
	#  [7]    0x04  Size[7:0]
	#
	set bytes_exp {0x7C 0x00 0x7A 0x80 0x00 0x00 0x7B 0x04}
	set len_exp [llength $bytes_exp]
	set len_rsp [llength $bytes_rsp]
	if {$len_rsp != $len_exp} {
		error "Error: incorrect number of response bytes!"
	}
	for {set i 0} {$i < $len_exp} {incr i} {
		set byte_exp [lindex $bytes_exp $i]
		set byte_rsp [lindex $bytes_rsp $i]
		if {$byte_rsp != $byte_exp} {
			error "Error: incorrect response byte!"
		}
	}	
	return
}

# JTAG-to-Avalon-MM 32-bit read
proc jtag_read {index addr} {
	variable jtag
	if {![info exists jtag(hub_info)]} {
		altera_jtag_to_avalon_stp::jtag_hub_info
	}
	if {$index >= $jtag(hub_n_nodes)} {
		puts "Error; invalid index $index!"
		return	
	}
	
	# Check the node is ID 132 (0x84)
	if {$jtag(node_${index}_id) != 0x84} {
		puts "Error; index $index is not a JTAG-to-Avalon-ST/MM bridge!"
		return
	}
	
	# Check its an Avalon-MM master device
	if {$jtag(node_${index}_purpose) != 1} {
		puts "Error; index $index is not a JTAG-to-Avalon-MM bridge!"
		return
	}

	# ------------------------------------
	# Send data formatting
	# ------------------------------------

	# Transaction bytes
	#
	#  Byte   Value  Description
	# ------  -----  -----------
	#    [0]  0x10   Transaction code = read, no increment
	#    [1]  0x00   Reserved
	#  [3:2]  0x0004 16-bit size (big-endian byte order)
	#  [7:4]  32-bit address (big-endian byte order)
	#
	set bytes {0x10 0 0 4}
	for {set i 0} {$i < 4} {incr i} {
		lappend bytes [expr {($addr >> 8*(3-$i)) & 0xFF}]
	}

	# Convert to Packet bytes
	#
	# Byte   Value  Description
	# -----  -----  ----------
	#  [0]   0x7C   Channel
	#  [1]   0x00   Channel number
	#  [2]   0x7A   Start-of-packet
	#  [X:3]        Transaction bytes with escape codes
	#        0x7B   End-of-packet
	#  [Y]          Last transaction byte (and escape code)
	#
	set len [llength $bytes]
	set bytes_pkt {0x7C 0x00 0x7A}
	for {set i 0} {$i < $len} {incr i} {

		# Next transaction byte
		set byte [lindex $bytes $i]
		
		# Add the end-of-packet code before the last item
		# of data (and its escape code)
		if {$i == $len-1} {
			lappend bytes_pkt 0x7B
		}

		# Escape required?
		if {($byte >= 0x7A) && ($byte <= 0x7D)} {
			# Add an escape code
			lappend bytes_pkt 0x7D
			
			# Modify the byte
			set byte [expr {$byte ^ 0x20}]
		}

		# Add the byte in hex format
		lappend bytes_pkt [format "0x%.2X" $byte]
	}
	unset bytes
	
	# ------------------------------------
	# JTAG bytestream send/receive
	# ------------------------------------
	#
	set bytes_rsp [altera_jtag_to_avalon_stp::jtag_send $index $bytes_pkt]
	unset bytes_pkt
		
	# ------------------------------------
	# Decode the bytes-to-packet response
	# ------------------------------------
	#
	# Bytes  Value  Description
	# -----  -----  -----------
	#  [0]    0x7C  Channel
	#  [1]    0x00  Channel number
	#  [2]    0x7A  Start-of-packet
	#  [3]          Read-data[7:0]
	#  [4]          Read-data[15:8]
	#  [5]          Read-data[23:16]
	#  [6]    0x7B  End-of-packet
	#  [7]          Read-data[31:24]
	#
	set bytes_exp {0x7C 0x00 0x7A 0x00 0x00 0x00 0x7B 0x00}
	set len_exp [llength $bytes_exp]
	set len_rsp [llength $bytes_rsp]
	if {$len_rsp != $len_exp} {
		error "Error: incorrect number of response bytes!"
	}
	set data 0
	for {set i 0} {$i < $len_exp} {incr i} {
		set byte_exp [lindex $bytes_exp $i]
		set byte_rsp [lindex $bytes_rsp $i]
		if {$i == 3} {
			set data $byte_rsp
		} elseif {$i == 4} {
			set data [expr {($byte_rsp << 8) | $data}]
		} elseif {$i == 5} {
			set data [expr {($byte_rsp << 16) | $data}]
		} elseif {$i == 7} {
			set data [expr {($byte_rsp << 24) | $data}]
		} else {
			if {$byte_rsp != $byte_exp} {
				error "Error: incorrect response byte!"
			}
		}
	}
	set data [format "0x%.8X" $data]
	return $data
}

} ;# end namespace altera_jtag_to_avalon_stp
