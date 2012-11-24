#
# (c) System csh.cshrc for tcsh, Werner Fink '93
#                         and  J"org Stadler '94
#
# This file sources /etc/profile.d/complete.tcsh and
# /etc/profile.d/bindkey.tcsh used especially by tcsh.
#
# PLEASE DO NOT CHANGE /etc/csh.cshrc. There are chances that your changes
# will be lost during system upgrades. Instead use /etc/csh.cshrc.local for
# your local settings, favourite global aliases, VISUAL and EDITOR
# variables, etc ...
# USERS may write their own $HOME/.csh.expert to skip sourcing of
# /etc/profile.d/complete.tcsh and most parts oft this file.
#

#
# Just in case the user excutes a command with ssh
#
if ((${?loginsh} || ${?SSH_CONNECTION}) && ! ${?CSHRCREAD}) then
    set _SOURCED_FOR_SSH=true
    source /etc/csh.login >& /dev/null
    unset _SOURCED_FOR_SSH
endif
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
# Default echo style
#
set echo_style=both

#
# In case if not known
#
if (! ${?UID}  ) set -r  UID=${uid}
if (! ${?EUID} ) set -r EUID="`${id} -u`"

#
# Avoid trouble with Emacs shell mode
#
if ($?EMACS) then
  setenv LS_OPTIONS '-N --color=none -T 0';
  path tset -I -Q
  path stty cooked pass8 dec nl -echo
# if ($?tcsh) unset edit
endif

#
# Only for interactive shells
#
if (! ${?prompt}) goto done

#
# Let root watch its system
#
if ( "$uid" == "0" ) then
    set who=( "%n has %a %l from %M." )
    set watch=( any any )
endif

#
# This is an interactive session
#
# Now read in the key bindings of the tcsh
#
if ($?tcsh && -r /etc/profile.d/bindkey.tcsh) source /etc/profile.d/bindkey.tcsh

#
# Some useful settings
#
set autocorrect=1
set listmaxrows=23
# set cdpath = ( /var/spool )
# set complete=enhance
# set correct=all
set correct=cmd
set fignore=(.o \~)
# set histdup=erase
set histdup=prev
set history=1000
set listjobs=long
set notify=1
set nostat=( /afs )
set rmstar=1
set savehist=( $history merge )
set showdots=1
set symlinks=ignore
#
unset autologout
unset ignoreeof

if (-r /etc/profile.d/ls.tcsh) source /etc/profile.d/ls.tcsh

if (-r /etc/profile.d/alias.tcsh) source /etc/profile.d/alias.tcsh
#
# Prompting and Xterm title
#
set prompt="%B%m%b %C2%# "
if ( -o /dev/$tty && -c /dev/$tty ) then
  alias cwdcmd '(echo "Directory: $cwd" > /dev/$tty)'
  if ( -x /usr/bin/biff ) /usr/bin/biff y
  # If we're running under X11
  if ( ${?DISPLAY} ) then
    if ( ${?TERM} && ${?EMACS} == 0 && ${?MC_SID} == 0 && ! -r $HOME/.csh.expert ) then
      if ( ${TERM} == "xterm" ) then
        alias cwdcmd '(echo -n "\033]2;$USER on ${HOST}: $cwd\007\033]1;$HOST\007" > /dev/$tty)'
        cd .
      endif
    endif
    if ( -x /usr/bin/biff ) /usr/bin/biff n
    set prompt="%C2%# "
  endif
endif
#
# tcsh help system does search for uncompressed helps file
# within the cat directory system of a old manual page system.
# Therefore we use whatis as alias for this helpcommand
#
alias helpcommand whatis

#
# Expert mode: if we find $HOME/.csh.expert we skip our settings
# used for interactive completion and read in the expert file.
#
if (-r $HOME/.csh.expert) then
    unset noglob
    source $HOME/.csh.expert
    goto done
endif

#
# Source the completion extension of the tcsh
#
if ($?tcsh) then
    set _rev=${tcsh:r}
    set _rel=${_rev:e}
    set _rev=${_rev:r}
    if (($_rev > 6 || ($_rev == 6 && $_rel > 1)) && -r /etc/profile.d/complete.tcsh) then
	source /etc/profile.d/complete.tcsh
    endif
    #
    # Enable editing in multibyte encodings for the locales
    # where this make sense, but not for the new tcsh 6.14.
    #
    if ($_rev < 6 || ($_rev == 6 && $_rel < 14)) then
	switch ( `/usr/bin/locale charmap` )
	case UTF-8:
	    set dspmbyte=utf8
            breaksw
	case BIG5:
	    set dspmbyte=big5
            breaksw
	case EUC-JP:
	    set dspmbyte=euc
            breaksw
	case EUC-KR:
	    set dspmbyte=euc
            breaksw
	case GB2312:
	    set dspmbyte=euc
	    breaksw
	case SHIFT_JIS:
	    set dspmbyte=sjis
            breaksw
	default:
            breaksw
	endsw
    endif
    #
    unset _rev _rel
endif

#
# Set GPG_TTY for curses pinentry
# (see man gpg-agent and bnc#619295)
#
if ( -o /dev/$tty && -c /dev/$tty ) setenv GPG_TTY /dev/$tty

done:
onintr
unset noglob

#
# Local configuration
#
if ( -r /etc/csh.cshrc.local ) source /etc/csh.cshrc.local

#
# End of /etc/csh.cshrc
#
