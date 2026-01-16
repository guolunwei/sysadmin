# User specific aliases and functions
if [ -d ~/.profile.d ]; then
        for rc in ~/.profile.d/*; do
                if [ -f "$rc" ]; then
                        . "$rc"
                fi
        done
fi
