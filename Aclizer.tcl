############################
#
#
#Aclizer.tcl
#
#usage: copy to router
#edit interfaces/acl numbers to suit.  Be sure you have a fallback acl that works.
#Jason "jabreity" Breitwieser - ORI.NET
#
#To run every 5 minutes:
#
#kron occurrence tcl_occour in 5 recurring
#policy-list tclpol
#
#kron policy-list tclpol
#cli tclsh disk0:/Aclizer.tcl
#
proc updater {} {

set result ""
set url "GET /banlist.html HTTP/1.0\nHost: webserver.domain.tld\n\n"

# Open a socket to the server. This creates a TCP connection to the real server
set sock [socket webserver.domain.tld 80]
fconfigure $sock -buffering none -eofchar {}

# Send the get request as defined
puts -nonewline $sock $url;

# Wait for the response from the server and read that in variable line
set result [ read $sock ]
close $sock

set command ""

#Customize your interface and ACL number here.
#First, let's change to the "inactive acl"
ios_config "int F0/0" "ip access-group 125 in" "ip access-group 125 out"

#After changing ACL on interface, we are now safe to toss the old access-list
ios_config "no access-list 130"

#now, if the line is an IP address, ban it!
foreach x $result {if {[regexp {^([0-9]+\.){3}[0-9]+$} $x match]} {
	set command "access-list 130 deny ip $x 0.0.0.0 any"}
	ios_config $command}

#Now we also have a few permanant bans, and our permit any to add
ios_config "access-list 130 deny   ip badguyip 0.0.255.255 any"
ios_config "access-list 130 deny   udp any goodguyip 0.0.0.15 eq 80 log"
ios_config "access-list 130 deny   udp any goodguyip 0.0.0.15 eq 8080 log"
ios_config "access-list 130 deny icmp any goodguyip 0.0.0.0"
ios_config "access-list 130 permit ip any any"

#At this point, we've written out all our ACL's and are ready to apply to the appropriate interface
ios_config "int F0/0" "ip access-group 130 in" "ip access-group 130 out"
}

# - Fire the update command to initiate ACL swap/write/swap activities.
updater
################################
