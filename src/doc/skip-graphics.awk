# Discard \begin{psxtcnooutput} ... \end{psxtcnooutput}.
/^-- \\begin{psxtcnooutput}/,/^-- \\end{psxtcnooutput}/ {next}

{
    print $0
}
