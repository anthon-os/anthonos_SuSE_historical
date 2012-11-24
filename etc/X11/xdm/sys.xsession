#!/bin/bash
#
# sys.xsession: Login for an X session, will be executed
#		by the Xsession script of the xdm with
#		the help of the login shell of the user.
#

#
# If ssh is configured and ssh-agent is wanted set "yes"
#
usessh=yes

#
# If gpg is configured and gpg-agent is wanted set "yes"
#
usegpg=yes

#
# What we do if we fail at least ... emergency fall back.
#
failsafe="xterm -ls -T Failsafe -geometry 80x24+0+0"
trap "exec $failsafe" EXIT SIGHUP SIGINT SIGPIPE SIGTERM SIGIO

#
# Some bash (1 and 2) settings to avoid trouble on a
# failed program call.
#
set +e > /dev/null 2>&1
set +u > /dev/null 2>&1
set +o posix  > /dev/null 2>&1
if type shopt > /dev/null 2>&1 ; then
    shopt -s execfail
else
    no_exit_on_failed_exec=1
fi

#
# Simple helpers
#
checkproc ()
{
    /sbin/checkproc -k ${1+"$@"}
}

#
# Remember and reset the command line, used for execution at the end.
#
argv=("$@")
set --

#
# No ssh-agent if a ssh session is already provided by an other agent.
#
if test "$usessh" = yes -a -n "$GNOME_KEYRING_PID" ; then
    if test -S "$GNOME_KEYRING_SOCKET" -o -d "$GNOME_KEYRING_CONTROL"; then
	usessh=no
    fi
fi

#
# No gpg-agent if a gpg session is already provided by an other agent.
#
if test "$usegpg" = yes -a -n "$GNOME_KEYRING_PID" ; then
    case "${WINDOWMANAGER##*/}" in
    gnome*)
        # gnome-keyring provides a gpg agent starting with GNOME 3 (the
        # gnome-version.xml file only exists in GNOME 3)
        if test -d "$GNOME_KEYRING_CONTROL" -a -f "/usr/share/gnome/gnome-version.xml"; then
            usegpg=no
        fi
    esac
fi

#
# No gpg-agent if a gpg session is already provided by an other agent.
#
if test "$usegpg" = yes -a -n "$GNOME_KEYRING_PID" ; then
    # gnome-keyring provides a gpg agent starting with GNOME 3
    if test -d "$GNOME_KEYRING_CONTROL"; then
        usegpg=no
    fi
fi

#
# Run ssh-agent only if ssh service is configured and avaliable.
# Check if there is already a running ssh-agent and if use this.
#
if test "$usessh" = yes -a -d "$HOME/.ssh" && sshagent=$(type -p ssh-agent) ; then
    if test -S "$SSH_AUTH_SOCK" ; then
	if test -n "$SSH_AGENT_PID" && checkproc -p $SSH_AGENT_PID $sshagent ; then
	    export SSH_AGENT_PID SSH_AUTH_SOCK
	else
	    rm -f "$SSH_AUTH_SOCK"
	    case "${SSH_AUTH_SOCK%/*}" in
	    /tmp/*) rm -rf "${SSH_AUTH_SOCK%/*}"
	    esac
	    unset SSH_AUTH_SOCK
	fi
    else
	unset SSH_AUTH_SOCK
    fi

    if test -z "$SSH_AUTH_SOCK" ; then
	set -- $sshagent ${1+"$@"}
    fi

    if test -x /usr/lib/ssh/ssh-askpass ; then
	SSH_ASKPASS=/usr/lib/ssh/ssh-askpass
	export SSH_ASKPASS
    elif test -x /usr/lib64/ssh/ssh-askpass ; then
	SSH_ASKPASS=/usr/lib64/ssh/ssh-askpass
	export SSH_ASKPASS
    fi
fi

#
# Run gpg-agent only if gpg service is configured and avaliable.
# Check if there is already a running gpg-agent and if use this.
#
if test "$usegpg" = yes -a -d "$HOME/.gnupg" && gpgagent=$(type -p gpg-agent) ; then
    GPG_AGENT_FILE="$HOME/.gnupg/agent.info"
    test -s "$GPG_AGENT_FILE" && . "$GPG_AGENT_FILE"

    if test -n "$GPG_AGENT_INFO" ; then
	GPG_AGENT_PID=${GPG_AGENT_INFO#*:}
	GPG_AGENT_PID=${GPG_AGENT_PID%%:*}
	if test -n "$GPG_AGENT_PID" && checkproc -p $GPG_AGENT_PID $gpgagent ; then
	    export GPG_AGENT_INFO
	else
	    unset GPG_AGENT_INFO
	fi
    fi

    if test -z "$GPG_AGENT_INFO" ; then
	set -- $gpgagent --sh --daemon --write-env-file "$GPG_AGENT_FILE" ${1+"$@"}
    fi
fi

#
# Use system default xinitrc if the users does not have one.
#
XINITRCFILE=/etc/X11/xinit/xinitrc
test -r "$HOME/.xinitrc" && XINITRCFILE="$HOME/.xinitrc"

if test -f "$XINITRCFILE" ; then
    if test -x "$XINITRCFILE" ; then
	exec ${1+"$@"} "$XINITRCFILE" "${argv[@]}"
    else
	exec ${1+"$@"} /bin/bash "$XINITRCFILE" "${argv[@]}"
    fi
else
    #
    # Source common code shared between the
    # X session and X init scripts
    #
    . /etc/X11/xinit/xinitrc.common
    unset STARTUP WINDOW_MANAGER

    exec ${1+"$@"} $WINDOWMANAGER "${argv[@]}"
fi

# call failsafe
exit 0
