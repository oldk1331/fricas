BEGIN {
    print ")set message autoload off"
    print "-- \\begin{inputonly}"
    print ")set break resume"
    print ")lisp (setf |$ioHook| \
(lambda (x &optional args) \
  (cond ((eq x '|startKeyedMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) \
        ((eq x '|endOfKeyedMsg|) (SAY \"-- \\\\end{MessageOutput}\")) \
        ((eq x '|startSysCmd|) (SAY \"-- \\\\begin{SysCmdOutput}\")) \
        ((eq x '|endSysCmd|) (SAY \"-- \\\\end{SysCmdOutput}\")) \
        ((eq x '|startPatternMsg|) (SAY \"-- \\\\begin{MessageOutput}\")) \
        ((eq x '|endPatternMsg|) (SAY \"-- \\\\end{MessageOutput}\")) \
        ((eq x '|startAlgebraOutput|) (SAY \"-- \\\\begin{AlgebraOutput}\")) \
        ((eq x '|endOfAlgebraOutput|) (SAY \"-- \\\\end{AlgebraOutput}\")))))"
    print "setDefault!((label: String): OutputBox +-> vconcat([box \"-- \\begin{TeXOutput}\",defaultPrologue(label)$FormatLaTeX],1,-1)$OutputBox, (label: String): OutputBox +-> vconcat([defaultEpilogue(label)$FormatLaTeX, box \"-- \\end{TeXOutput}\"],1,-1)$OutputBox)$Formatter(FormatLaTeX);"
    print "setFormats!([Formatter(FormatLaTeX)] pretend List(OutputFormatterCategory))$FormattedOutput;"
    print ")set output formatted on"
    print ")set output algebra off"
    print ")set output length 88"
    print ")set message time off"
    print ")set streams calculate 7"
    print "outputSpacing(0)"
    print "-- \\end{inputonly}"
    spadgraph=0
}

END {
    maybeCloseViewport()
    print ")set quit unprotected"
    print ")quit"
}

# discard lines between \begin{htonly} and \end{htonly}
/^\\begin{htonly}/,/^\\end{htonly}/ {next}

# delete \begin{texonly} and \end{texonly} lines (leaving what is in between)
/^\\begin{texonly}/ || /^\\end{texonly}/  {next}

# LaTeX should never see stuff that is not intended for it, i.e. we
# translate \texht{T}{H} into T. We assume that \texht with arguments
# appears on a single line.
/\\texht{/ {
        cmd = "\\texht{"
        line = $0
        p = index(line,cmd)
        while (p > 0) {
            pref = (p == 1) ? "" : substr(line,1,p-1)
            line = substr(line,p)
            n = endMacroIndex(line,2)
            if (n < 0) {
                print ARGV[1] ":" NR ": ERROR: texht not on ended on the same line"
                print $0
                next
            }
            line = extractArg(line,1) substr(line,n+1)
            if (p != 1) {line = pref line}
            p = index(line,cmd)
        }
        $0 = line
}

# print lines between \begin{inputonly} and \end{inputonly}
/^\\begin{inputonly}/ {
    print "-- " $0
    getline
    while (substr($1,1,15) != "\\end{inputonly}") {
        print $0
        getline
    }
    print "-- " $0
    next
}


/^} *$/ && xtc>1 {
    xtc=0
    print "-- \\end{" xtcname "}"
    next
}

xtc==2 && (/^\\spadcommand{/ || /^\\spadgraph{/) {
    posspadgraph=match($0, /^\\spadgraph{/)
    gsub(/^\\spadcommand{/, "")
    gsub(/^\\spadgraph{/, "")
    gsub(/}$/, "")
    gsub(/\\\$/, "$")
    gsub(/\\%/, "%")
    gsub(/\\#/, "#")
    gsub(/\\_/, "_")
    gsub(/\\free{.*/, "")
    gsub(/\\bound{.*/, "")
    gsub(/  *$/, "")

    # ")clear all" commands need special treatment
    if ($0 == ")clear all") {maybeCloseViewport()}
    print "-- \\begin{spadsrc}"
    print "-- " $0
    print "-- \\end{spadsrc}"

    if (xtcname=="psXtc") {
        if (posspadgraph>0) {maybeCloseViewport()}
        print "-- \\begin{inputonly}"
        if (posspadgraph>0) {
            spadgraph=1
            print ")if CreateGraphics"
            print "spadgraphViewport:=" $0
            print ")endif"
        } else {
            print $0
        }
        print "-- \\end{inputonly}"
    }
    if (xtcname=="noOutputXtc") {
        print "-- \\begin{inputonly}"
        print $0
        print "-- \\end{inputonly}"
    }
    if (xtcname=="xtc") {
        print $0
    }
    next
}

xtc==2 && /^\\begin{spadsrc}/ {
    print "-- \\begin{spadsrc}" # This removes optional arguments.
    n=1
    getline
    while (substr($1,1,13) != "\\end{spadsrc}") {
        print "-- " $0
        arr[n]=$0
        n++
        getline
    }
    print "-- " $0
    if (xtcname=="psXtc" || xtcname=="noOutputXtc") {
        print "-- \\begin{inputonly}"
    }
    if (xtcname=="xtc" || xtcname=="noOutputXtc") {
        if (xtcname!="nullXtc") {
            for (i = 1; i < n; i++) {print arr[i]}
        }
    }
    if (xtcname=="psXtc" || xtcname=="noOutputXtc") {
        print "-- \\end{inputonly}"
    }
    next
}

/^\\xtc{/ || /^\\noOutputXtc{/ || /^\\nullXtc{/ || /^\\psXtc{/ {
    xtc=1
    sub(/\\/,"")
    sub(/{.*/,"")
    xtcname=$0
    print "-- \\begin{" xtcname "}"
    print "-- \\begin{xtccomment}"
    next
}

/^}{/ && xtc==1 {
    print "-- \\end{xtccomment}"
    xtc=2
    next
}

/^}{/ && xtc==2 {
    xtc=3
    next
}

xtc==3 && xtcname == "psXtc" {
    print "-- \\begin{center}"
    print "-- \\includegraphics[height=.25\\textheight]{" $0 "}"
    print "-- \\end{center}"
    print "-- \\begin{inputonly}"
    print ")if CreateGraphics"
    print "write(spadgraphViewport, \"tmp/" $0 "\", \"postscript\");"
    print ")endif"
    print "-- \\end{inputonly}"
    next
}

{
    print "-- " $0
    if (match($0,/^\\head/)) {
        maybeCloseViewport()
        print "-- \\begin{inputonly}"
        print ")clear all"
        print "-- \\end{inputonly}"
    }
}

function maybeCloseViewport() {
    if (spadgraph>0) {
        print "-- \\begin{inputonly}"
        print ")if CreateGraphics"
        print "close(spadgraphViewport);"
        print ")endif"
        print "-- \\end{inputonly}"
    }
    spadgraph=0
}

function endMacroIndex(line,parms,    pp,x,bc,cc,len,found) {
# assumes start of line is a macro call and returns position of final "}"
        x = 0
        found = -1
        pp = index(line,"{")
        len = length(line)
        if (pp != 0) {
          bc = 1
          for (x = pp+1; x<=len; x++) {
            cc = substr(line,x,1)
            if (cc == "{")
              bc++
            else if (cc == "}") {
              bc--
              if (bc == 0) {
                parms--
                if (parms == 0) {
                    found = 1
                    break
                }
              }
            }
          }
          x = x * found # negative if not found
        }
        return x
}

function extractArg(line,num,   p,arg) {
# assumes line is a macro call and extracts the num-th arg
        arg = ""
        p = index(line,"{")
        if (p != 0) {
          line = substr(line,p)

          if (num > 1) {
            p = endMacroIndex(line,num-1)
            line = substr(line,p+1)
          }
          p = endMacroIndex(line,1)
          arg = substr(line,2,p-2)
        }
        return arg
}
