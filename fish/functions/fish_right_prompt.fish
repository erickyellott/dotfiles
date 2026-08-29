function fish_right_prompt
	set -l cmd_status $status
	if test $cmd_status -ne 0
		echo -n (set_color red)"✘ $cmd_status"
	end

	if not command -sq git
		set_color --reset
		return
	end

	# Return if not inside a Git repository work tree.
	if not set -l git_dir (command git rev-parse --git-dir 2>/dev/null)
		set_color --reset
		return
	end

	# Branch name, or a descriptor when detached.
	set -l branch_detached 0
	if not set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
		set branch_detached 1
		set branch (command git describe --contains --all HEAD 2>/dev/null)
	end

	# In-progress operation: rebase, merge, cherry-pick, bisect, etc.
	set -l action (fish_print_git_action "$git_dir")

	# Any change at all — staged, unstaged, or untracked.
	set -l dirty 0
	set -l changes (command git status --porcelain 2>/dev/null | head -n1)
	if test -n "$changes"
		set dirty 1
	end

	set_color -o

	if test -n "$branch"
		if test $branch_detached -ne 0
			set_color brmagenta
		else
			set_color green
		end
		echo -n " $branch"
	end
	if test -n "$action"
		echo -n (set_color white)':'(set_color -o brred)"$action"
	end
	if test $dirty -ne 0
		echo -n ' '(set_color yellow)'●'
	end

	set_color --reset
end
