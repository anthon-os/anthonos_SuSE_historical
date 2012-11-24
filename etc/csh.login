#
# System csh.login for tcsh,
# (c) Werner Fink '93
#
# PLEASE DO NOT CHANGE /etc/csh.login. There are chances that your changes
# will be lost during system upgrades. Instead use /etc/csh.login.local for
# your local environment settings.
#
onintr -
set noglob
#   
# Call common progams from /bin or /usr/bin only
#   
alias path 'if ( -x /bin/\!^ ) /bin/\!*; if ( -x /usr/bin/\!^ ) /usr/bin/\!*'
if ( -x /bin/id ) then
    set id=/bin/id
else if ( -x /usr/bin/id ) then
    set id=/usr/bin/id
endif

#
# Initialize terminal
#
if ( -o /dev/$tty && -c /dev/$tty && ${?prompt} ) then
    # Console
    if ( ! ${?TERM} )           setenv TERM linux
    if ( "$TERM" == "unknown" ) setenv TERM linux
    if ( ! ${?SSH_TTY} && "$TERM" != "dumb" ) then
	path stty sane cr0 pass8 dec
	path tset -I -Q
    endif
    # on iSeries virtual console, detect screen size and terminal
    if ( -d /proc/iSeries && ( $tty == "tty1" || "$tty" == "console")) then
	setenv LINES   24
	setenv COLUMNS 80
	eval `path initviocons -q -e -c`
    endif
    settc km yes
endif
unsetenv TERMCAP

#
# The user file-creation mask
#
umask 022

#
# Setup for gzip and (t)csh users
#
if (! ${?CSHRCREAD} ) then
    # setenv GZIP -9
    setenv CSHEDIT emacs
endif

#
# In case if not known
#
if (! ${?UID}  ) set -r  UID=${uid}
if (! ${?EUID} ) set -r EUID="`${id} -u`"
if (! ${?USER} ) set    USER="`${id} -un`"
if (! ${?HOME} ) set    HOME=""
if (! ${?MAIL} ) setenv MAIL /var/spool/mail/$USER
if ( -x /bin/uname ) then
    if (! ${?HOST} ) setenv HOST "`/bin/uname -n`"
    if ( ${HOST} == localhost ) setenv HOST "`/bin/uname -n`"
    if (! ${?CPU}  ) setenv CPU  "`/bin/uname -m`"
endif
# Remark: /proc/sys/kernel/domainname and the program domainname
# its self will provide the NIS/YP domainname, see domainname(8).
if ( -s /etc/HOSTNAME ) then
    if (! ${?HOSTNAME} ) setenv HOSTNAME `cat /etc/HOSTNAME`
else
    if (! ${?HOSTNAME} ) setenv HOSTNAME $HOST
endif
if (! ${?LOGNAME} )  set    LOGNAME=$USER
if ( ${CPU} =~ i?86 ) then
    setenv HOSTTYPE i386
else
    setenv HOSTTYPE "$CPU"
endif
setenv OSTYPE linux
setenv MACHTYPE "${CPU}-suse-${OSTYPE}"

#
# Get message if mail is reached
#
set mail=$MAIL

#
# You may use /etc/initscript, /etc/profile.local or the
# ulimit package instead to set up ulimits and your PATH.
#
# if (! -r /etc/initscript ) then
#     limit coredumpsize	0	# don't create core files
#     eval limit `limit -h datasize`
#     eval limit `limit -h stacksize`
#     eval limit `limit -h memoryuse`
# endif

#
# Make path more comfortable
#
unset noglob
set _hpath
set _spath
set _upath=( /usr/local/bin /usr/bin /bin )
if ( "$HOME" != "/" ) then
    foreach _d (${HOME}/bin/${CPU} ${HOME}/bin)
	if ( -d $_d ) set _hpath=( $_d $_hpath )
    end
endif
if ( "$uid" == "0" ) then
    if ( -d /opt/kde3/sbin ) set _spath=( /opt/kde3/sbin )
    set _spath=( /sbin /usr/sbin /usr/local/sbin $_spath )
endif
foreach _d (/usr/X11/bin \
	    /usr/bin/X11 \
	    /usr/X11R6/bin \
	    /var/lib/dosemu \
	    /usr/games \
	    /opt/bin \
	    /opt/kde3/bin \
	    /opt/kde2/bin \
	    /opt/kde/bin \
	    /usr/openwin/bin \
	    /opt/cross/bin )
    if ( -d $_d ) set _upath=( $_upath $_d )
end
unset _d

if ( ${?OPENWINHOME} ) then
    if ( -d $OPENWINHOME/bin ) then
	set _upath=( $_upath $OPENWINHOME/bin )
    endif
endif

#
# Doing only one rehash
#
set -f path=( $_hpath $_spath $path $_upath )
unset _upath
unset _spath
unset _hpath
set noglob

#
# For all readline library based applications
#
if (! ${?INPUTRC} ) then
    if ( -r /etc/inputrc ) setenv INPUTRC /etc/inputrc
    if ( "$HOME" != "/" ) then
	if ( -s ${HOME}/.inputrc ) setenv INPUTRC ${HOME}/.inputrc
    endif
endif

#
# Set some environment variables for TeX/LaTeX (Not used due luatex)
#
#if ( ${?TEXINPUTS} ) then
#    setenv TEXINPUTS ":${TEXINPUTS}:${HOME}/.TeX:/usr/share/doc/.TeX:/usr/doc/.TeX"
#else
#    setenv TEXINPUTS ":${HOME}/.TeX:/usr/share/doc/.TeX:/usr/doc/.TeX"
#endif

#
# Configure the default pager on SuSE Linux
#
if (! ${?LESS} ) then
    setenv LESS "-M -I -R"
    setenv LESSOPEN "lessopen.sh %s"
    setenv LESSCLOSE "lessclose.sh %s %s"
    setenv LESS_ADVANCED_PREPROCESSOR "no"
    if ( -s /etc/lesskey.bin ) then
        setenv LESSKEY /etc/lesskey.bin
    endif
    setenv PAGER less
    setenv MORE -sl
endif

#
# Minicom
#
if (! ${?CSHRCREAD} ) then
    setenv MINICOM  "-c on"
endif

#
# Current manpath
#
if (! ${?CSHRCREAD} && -x /usr/bin/manpath ) then
    if ( ${?MANPATH} ) then
	setenv MANPATH "${MANPATH}:`(unsetenv MANPATH; /usr/bin/manpath -q)`"
    else
	setenv MANPATH "`(unsetenv MANPATH; /usr/bin/manpath -q)`"
    endif
endif

#
# Some applications do not handle the XAPPLRESDIR environment properly,
# when it contains more than one directory. More than one directory only
# makes sense if you have a client with /usr mounted via nfs and you want
# to configure applications machine dependent. Uncomment the lines below
# if you want this.
#
#setenv XAPPLRESDIR "$XAPPLRESDIR:/var/X11R6/app-defaults:/usr/X11R6/lib/X11/app-defaults"

if (! ${?CSHRCREAD} ) then
    #
    # These settings are recommended for old motif applications
    #
    if ( -r /usr/share/X11/XKeysymDB ) then
	setenv XKEYSYMDB /usr/share/X11/XKeysymDB
    else
	setenv XKEYSYMDB /usr/X11R6/lib/X11/XKeysymDB
    endif
    if ( -d /usr/share/X11/nls ) then
	setenv XNLSPATH /usr/share/X11/nls
    else
	setenv XNLSPATH /usr/X11R6/lib/X11/nls
    endif

    #
    # Midnight Commander needs this to run in color mode
    #
    setenv COLORTERM 1
endif

#
# For RCS
#
#setenv VERSION_CONTROL numbered

#
# Source the files generated by SuSEconfig
#
# But do not source this if CSHRCREAD is already set to avoid
# overriding locale variables already present in the environment
#
if (! ${?CSHRCREAD} ) then
    if ( -r /etc/profile.d/csh.ssh )    source /etc/profile.d/csh.ssh
    if ( -r /etc/SuSEconfig/csh.login ) source /etc/SuSEconfig/csh.login
    if (! ${?SSH_SENDS_LOCALE} ) then
	if ( -r /etc/sysconfig/language && -r /etc/profile.d/csh.utf8 ) then
	    set _tmp=`/bin/sh -c '. /etc/sysconfig/language; echo $AUTO_DETECT_UTF8'`
	    if ( ${_tmp} == "yes" ) source /etc/profile.d/csh.utf8
	    unset _tmp
	endif
    endif
endif

#
# Source profile extensions for certain packages, the super
# may disable some of them by setting the sticky bit.
#
if ( -d /etc/profile.d && ! ${?CSHRCREAD} ) then
    set _tmp=${?nonomatch}
    set nonomatch
    unset noglob
    foreach _s ( /etc/profile.d/*.csh )
	if ( -r $_s && ! -k $_s ) then
	    source $_s
	endif
    end
    set noglob
    if ( ! ${_tmp} ) unset nonomatch
    unset _tmp _s
endif

#
# Avoid overwriting user settings if called twice
#
if (! ${?CSHRCREAD} ) then
    setenv CSHRCREAD true
    set -r CSHRCREAD=$CSHRCREAD
endif

#
# Restore globbing on Ctrl-C
#
onintr
unset noglob

#
# Local configuration
#
if ( -r /etc/csh.login.local ) source /etc/csh.login.local

#
# An X session
#
if (${?TERM} && -o /dev/$tty && -c /dev/$tty && ${?prompt} && ! ${?SSH_TTY}) then
    if (${TERM} == "xterm") then
	echo "Directory: $cwd"
	# Last but not least
	date
    endif
endif

#
# End of /etc/csh.login
#
