#! /bin/sh

# original: https://stendhalgame.org/wiki/Two_way_git_mirror

cd -- "$(dirname "$0")" || exit 1
[ -d srv-gitsync ] || mkdir srv-gitsync
[ -d srv-gitsync ] || exit 1

sync_repo() {
	(
		cd srv-gitsync || return 1
		cd -- "$1" || return 1
		echo " $1"

		# fetch all known remotes
		git fetch --all -p

		# push branches from sourceforge to github and via versa.
		git push github 'refs/remotes/gitlab/*:refs/heads/*'
		git push gitlab 'refs/remotes/github/*:refs/heads/*'
	)
}

init_repo() {
	local account="$1" repository="$2"; shift 2
	(
		cd srv-gitsync || return 1
		git clone --bare "ssh://git@github.com/${account}/${repository}.git" "${repository}"
		cd -- "${repository}"
		git remote remove origin
		git remote add github "ssh://git@github.com/${account}/${repository}.git"
		git remote add gitlab "ssh://git@gitlab.com/${account}/${repository}.git"
		#git remote add sourceforge  ssh://${account}@git.code.sf.net/p/${repository}/code
	)
}

if [ $# -eq 0 ]; then
	set -- --help
fi

case "$1" in
	('--help'|'-h'|'')
		# no command line parameters, print help message
		echo >&2 "Usage: gitsync [report]|--all"
		return 1
	;;
	('--all')
		# "--all": for all known repositories
		for D in *; do
			if [ -d "${D}" ]; then
				sync_repo "$D"
			fi
		done
	;;
	(init) shift
		if [ $# -ne 2 ]; then
			echo >&2 'Usage: '"$0"' init <account> <reponame>'
			return 1
		fi
		init_repo "$1" "$2"
	;;
	(*)
		if [ ! -d "./srv-gitsync/$1" ]; then
			echo >&2 "ERROR: No such directory $1"
			return 1
		fi
		# sync only the specified repository
		sync_repo "$1"
	;;
esac
