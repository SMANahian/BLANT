#!/bin/bash
################## SKELETON: DO NOT TOUCH THESE 2 LINES
EXEDIR=`dirname "$0"`; BASENAME=`basename "$0" .sh`; TAB='	'; NL='
'
#################### ADD YOUR USAGE MESSAGE HERE, and the rest of your code after END OF SKELETON ##################
USAGE="USAGE: $BASENAME [-r] k
PURPOSE: nicely print the ordinal value, orbits, and canon_list files for a particular k
OPTIONS:
    -r means to print the orbits relative to the lowest one for that canonical."

################## SKELETON: DO NOT TOUCH CODE HERE
# check that you really did add a usage message above
USAGE=${USAGE:?"$0 should have a USAGE message before sourcing skel.sh"}
die(){ echo "$USAGE${NL}FATAL ERROR in $BASENAME:" "$@" >&2; exit 1; }
[ "$BASENAME" == skel ] && die "$0 is a skeleton Bourne Shell script; your scripts should source it, not run it"
echo "$BASENAME" | grep "[ $TAB]" && die "Shell script names really REALLY shouldn't contain spaces or tabs"
[ $BASENAME == "$BASENAME" ] || die "something weird with filename in '$BASENAME'"
warn(){ (echo "WARNING: $@")>&2; }
not(){ if eval "$@"; then return 1; else return 0; fi; }
newlines(){ awk '{for(i=1; i<=NF;i++)print $i}' "$@"; }
parse(){ awk "BEGIN{print $*}" </dev/null; }
which(){ echo "$PATH" | tr : "$NL" | awk '!seen[$0]{print}{++seen[$0]}' | while read d; do eval /bin/ls $d/$N; done 2>/dev/null | newlines; }

# Temporary Filename + Directory (both, you can use either, note they'll have different random stuff in the XXXXXX part)
BIGTMP=`for i in /scratch/preserve/RaidZ3/tmp /var/tmp /scratch/preserve /var/tmp /tmp; do mkdir -p "$i/wayne" && (df $i | awk 'NR==1{for(av=1;av<=NF;av++)if(match($av,"[Aa]vail"))break;}NR>1{print $av,"'"$i"'"}'); done 2>/dev/null | sort -nr | awk 'NR==1{print $2}'`
[ "$MYTMP" ] || MYTMP="$BIGTMP/wayne"
TMPDIR=`mktemp -d $MYTMP/$BASENAME.XXXXXX`
 trap "/bin/rm -rf $TMPDIR; exit" 0 1 2 3 15 # call trap "" N to remove the trap for signal N

#################### END OF SKELETON, ADD YOUR CODE BELOW THIS LINE

REL=0
case "$1" in
-r) REL=1; shift;;
-*) die "unknown option '$1'";;
esac

[ $# -eq 1 ] || die "expecting exactly 1 argument"
k=$1;
[ 3 -le $k -a $k -le 10 ] || die "k must be between 3 and 10"

if [ $k -le 8 ]; then
    cd "$EXEDIR/../canon_maps" 2>/dev/null || cd "$EXEDIR/../src/bionets/BLANT/canon_maps" || die "couldn't cd to $EXEDIR/../canon_maps directory"
else
    cd "$EXEDIR/../src/EdgePredict/small_maps" 2>/dev/null || cd "$EXEDIR/../src/bionets/BLANT/src/EdgePredict/small_maps" || die "couldn't cd to $EXEDIR/../small_maps directory"
fi

[ '(' -f orbit_map$k.txt -o -f orbit_map$k.txt.xz ')' -a -f canon_list$k.txt ] || die "can't find orbit maps and/or canon_list for k=$k"

#k=3 looks like this:
#6       4
#0 0 0   0       0 0
#1 2 2   1       0 1     1,2
#3 3 4   3       1 2     0,2 1,2
#5 5 5   7       1 3     0,1 0,2 1,2
CS=canon-ordinal-to-signature$k.txt
paste <(tail -1 $CS|awk '{print $2}'; cat $CS) <((cat orbit_map$k.txt || unxz < orbit_map$k.txt.xz)2>/dev/null) canon_list$k.txt | #tee /dev/tty |
    hawk 'BEGIN{k='$k';REL='$REL'}
	NR==1{ lastSig=$1; numOrbits=$2; numCanon=$3;
	    Ds=ceil(log10(lastSig));   Fs="%"Ds"d"; # format string for signatures
	    Do=ceil(log10(numOrbits)); Fo="%"Do"d"; # format string for canonical+orbit IDs
	    printf("ordinal\t%"Ds"s\t", "sig");
	    printf("%-"(k+1)*(Do)"s\tC\tm\tedgeList\n", "orbits");
	}
	NR>1{
	    printf(Fo"\t"Fs, $1,$2);
	    for(i=1;i<=k;i++) printf((i==1?"\t":" ")Fo, $(i+2)-REL*$3);  # orbit IDs preceded by tab or space as appropriate
	    # we will skip printing the integer value of the canonical, which is column k+1
	    printf("\t%d\t%d\t", $(k+4), $(k+5)); # connected numEdges
	    for(i=k+4;i<=NF;i++) printf((i==k+4?"":" ")"%s", $(i+2));  # edge list
	    print ""
	}'
