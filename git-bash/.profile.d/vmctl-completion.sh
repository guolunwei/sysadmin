_vmctl_complete() {
    local cur prev words cword
    
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    words=("${COMP_WORDS[@]}")
    cword=$COMP_CWORD

    # get subcommands
    local subcommands=$(vmctl.sh 2>/dev/null | awk '/^Available commands:/{flag=1;next} /^For example:/{flag=0} flag {print $1}' | sort | uniq)

    case $cword in
        1)
            # complete subcommands
            COMPREPLY=( $(compgen -W "$subcommands" -- "$cur") )
            ;;
        *)
            case ${words[1]} in
                clone|remove|start|stop|restart|setip|ssh)
                    # get all vms
                    local vms=$(vmctl.sh list --all 2>/dev/null)
                    COMPREPLY=( $(compgen -W "$vms" -- "$cur") )
                    ;;
                setip)
                    if [ $cword -eq 2 ]; then
                        # complete vm name
                        local vms=$(vmctl.sh list --all 2>/dev/null)
                        COMPREPLY=( $(compgen -W "$vms" -- "$cur") )
                    else
                        # not complete ip*
                        COMPREPLY=()
                    fi
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
            ;;
    esac
}

complete -F _vmctl_complete vm
complete -F _vmctl_complete vmctl.sh
