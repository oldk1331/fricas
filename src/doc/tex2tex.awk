# This file does some post prcoessings for the tex file.

#
/^\\end{AlgebraOutput}$/ {
    getline
    if (/^\\begin{AlgebraOutput}$/) {next}
    print "\\end{AlgebraOutput}"
    print $0
    next
}

/^\\end{MessageOutput}$/ {
    getline
    if (/^\\begin{MessageOutput}$/) {next}
    print "\\end{MessageOutput}"
    print $0
    next
}

## default cases
        {
    print $0
}
