# Discard \begin{psXtcOutput} ... \end{psXtcOutput}.
/^-- \\begin{psXtcOutput}/,/^-- \\end{psXtcOutput}/ {next}

{
    print $0
}
