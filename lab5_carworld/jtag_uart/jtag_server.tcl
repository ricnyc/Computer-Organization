# -----------------------------------------------------------------
# jtag_server.tcl
#
# 9/14/2011 D. W. Hawkins (dwh@ovro.caltech.edu)
#
# Altera JTAG socket server.
#
# This script sets up the server environment, accesses the JTAG
# device (if not in debug mode), and then starts the server.
#
# -----------------------------------------------------------------
# Notes:
# ------
#
# 1. Command line operation
#
#    quartus_stp -t jtag_server.tcl <port> <debug>
#
#    where 
#
#    <port>   Server port number (defaults to 2540)
#
#    <debug>  Debug flag (defaults to 0)
#
#             If <debug> = 1, the server runs in debug mode, where
#             reads and writes are performed on a Tcl variable,
#             rather than to the JTAG interface.
#
#  2. Console operation
#
#     The port number and debug flag can be set prior to sourcing
#     the script from a Tcl console.
#
# -----------------------------------------------------------------
# References
# ----------
#
# 1. Brent Welch, "Practical Programming in Tcl and Tk",
#    3rd Ed, 2000.
#
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Load the server commands
# -----------------------------------------------------------------
#
source ./jtag_server_cmds.tcl
source ./altera_jtag_to_avalon_stp.tcl

# -----------------------------------------------------------------
# Check the Tcl console supports JTAG
# -----------------------------------------------------------------
#
if {![is_tool_ok]} {
	puts "Sorry, this script can only run using quartus_stp or SystemConsole"
	return
}

# Load the JTAG-to-Avalon bridge commands for quartus_stp
#if {![is_system_console]} {
#	if {[catch {package require altera_jtag_to_avalon_stp}]} {
#		error [concat \
#			"Error: the package 'altera_jtag_to_avalon_stp' "\
#			"was not found. Please ensure the environment "\
#			"variable TCLLIBPATH includes the path to the " \
#			"library location." ]
#
#	}
#}

# -----------------------------------------------------------------
# Command line arguments?
# -----------------------------------------------------------------
#
# SystemConsole has an argc of 1 when you start it via the
# Transceiver Toolkit GUI, and an argc of 0 when you start
# it from SOPC Builder. Ignore command-line arguments from
# SystemConsole.
#
if {![is_system_console]} {
#	puts "Command-line argument count: $argc"
	if {$argc > 0} {
		set port [lindex $argv 0]
#		puts "Command-line port number: $port"
	}
	if {$argc > 1} {
		set debug [lindex $argv 1]
#		puts "Command-line debug flag: $debug"
	}
	
}
if {![info exists port]} {
	set port 2540
}
if {![info exists debug]} {
	jtag_debug_mode 0
} else {
	jtag_debug_mode $debug
	unset debug
}

# -----------------------------------------------------------------
# Start-up message
# -----------------------------------------------------------------
#
if {[is_system_console]} {
	set tool "system console"
} else {
	set tool "quartus_stp"
}
if {![is_debug_mode]} {
	puts [format "\nJTAG server running under %s\n" $tool]
} else {
	puts [format "\nJTAG server running in debug mode under %s\n" $tool]
}

if {[is_system_console]} {
	if {[has_fileevent]} {
		puts "This version of SystemConsole ([get_version]) supports fileevent."
		puts "The server can support multiple clients.\n"
	} else {
		puts "This version of SystemConsole ([get_version]) does not support fileevent."
		puts "The server can only support a single client.\n"
	}
}

# Check that the JTAG device exists
# * The Quartus tools are pretty bad about multiple accesses
#   to the JTAG hardware, so this command may hang if the
#   server is started while another is already running.
if {![is_debug_mode]} {
	puts "Open JTAG to access the JTAG-to-Avalon-MM master\n"
	jtag_open
}

# -----------------------------------------------------------------
# Start the server and wait for clients
# -----------------------------------------------------------------
#
puts "Start the server on port $port\n"
server_listen $port

puts "Wait for clients\n"
vwait forever
