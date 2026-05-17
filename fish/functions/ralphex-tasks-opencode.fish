function ralphex-tasks-opencode
    set -x OPENCODE_MODEL "opencode-go/kimi-k2.6"
    ralphex \
        --claude-command=$HOME/Projects/ralphex/scripts/opencode/opencode-as-claude.sh \
        --claude-args= \
        --tasks-only \
        $argv
end
