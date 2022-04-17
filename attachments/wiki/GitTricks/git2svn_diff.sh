if [ -z $1 ] ; then
	echo "Usage: $0 <patch file>"
	exit 1
fi

patch_file=$1

if $(head -n1 "${patch_file}" | grep '^commit' >& /dev/null) ; then
	git_rev=$(head -n1 "${patch_file}" | sed -r -e 's/^commit (.*)/\1/')
	svn_rev=$(git svn find-rev ${git_rev})

	while [ "x${svn_rev}" == "x" ] ; do
		git_rev=$(git rev-parse ${git_rev}^)
		svn_rev=$(git svn find-rev ${git_rev})
	done
else
	git_rev='unknown'
	svn_rev='unknown'
fi


cat ${patch_file} | sed -r -e "
/^diff --git a\/([^[:space:]]*).*/ {
	s/^diff --git a\/([^[:space:]]*).*/Index: \1/
	h
}
/^index.*/ {
	s/^index.*/===================================================================/
}
/^---.*/ {
	g
	s/Index: (.*)/--- \1\t(revision ${svn_rev})/
}
/^\+\+\+.*/ {
	g
	s/Index: (.*)/+++ \1\t(working copy)/
}
/^(new|deleted) file.*/ {
	N
	D
}
" > "${patch_file}".tmp
