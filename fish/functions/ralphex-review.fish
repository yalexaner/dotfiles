function ralphex-review
    if test (count $argv) -lt 2
        echo "Usage: ralphex-review <base-branch> <plan-path>"
        echo "Example: ralphex-review develop docs/plans/2026-05-17-feature.md"
        return 1
    end

    set base_branch $argv[1]
    set plan_path $argv[2]

    ralphex --review --base-ref $base_branch $plan_path
end
