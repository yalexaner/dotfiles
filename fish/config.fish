# starship prompt
starship init fish | source

# zoxide (replaces cd)
zoxide init fish --cmd cd | source

# fzf keybindings (ctrl+r for fuzzy history, ctrl+t for fuzzy file finder)
# ubuntu/debian ships fzf < 0.48, use bundled keybindings file
if test -f /usr/share/doc/fzf/examples/key-bindings.fish
    source /usr/share/doc/fzf/examples/key-bindings.fish
else
    fzf --fish | source
end
