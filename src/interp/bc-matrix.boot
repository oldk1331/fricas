-- Copyright (c) 1991-2002, The Numerical ALgorithms Group Ltd.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are
-- met:
--
--     - Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--
--     - Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in
--       the documentation and/or other materials provided with the
--       distribution.
--
--     - Neither the name of The Numerical ALgorithms Group Ltd. nor the
--       names of its contributors may be used to endorse or promote products
--       derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
-- IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
-- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
-- PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
-- LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

)package "BOOT"

-- Basic Command matrix entry

bcMatrix() ==  bcReadMatrix nil

bcReadMatrix(exitFunctionOrNil) ==
  page := htInitPage('"Matrix Basic Command", nil)
  htpSetProperty(page,'exitFunction,exitFunctionOrNil)
  htMakePage
   '((domainConditions
     (isDomain PI (PositiveInteger)))
    (text . "Enter the size of the matrix:")
    (inputStrings
     ("Number of {\em rows}:\space{3}" "" 5 2 rows PI)
     ("Number of {\em columns}: " "" 5 2 cols PI))
    (text . "\blankline ")
    (text . "How would you like to enter the matrix?")
    (text . "\beginmenu")
    (text . "\item ")
    (bcLinks ("\menuitemstyle{By entering individual entries}" "" bcInputExplicitMatrix  explicit))
    (text . "\item ")
    (bcLinks ("\menuitemstyle{By formula}" "" bcInputMatrixByFormula formula))
    (text . "\endmenu"))
  htShowPage()

bcInputMatrixByFormula(htPage, junk) ==
  page := htInitPage('"Basic Matrix Command", htpPropertyList htPage)
  htMakePage '(
    (domainConditions
      (isDomain S (Symbol))
      (isDomain FE (Expression (Integer))))
    (text . "\menuitemstyle{}\tab{2}")
    (text . "Enter the {\em row variable}: ")
    (text . "\tab{36}")
    (bcStrings (6 i rowVar S))
    (text . "\blankline ")
    (text . "\newline ")
    (text . "\menuitemstyle{}\tab{2}")
    (text . "Enter the {\em column variable}: ")
    (text . "\tab{36}")
    (bcStrings (6 j colVar S))
    (text . "\blankline ")
    (text . "\newline ")
    (text . "\menuitemstyle{}\tab{2}")
    (text .  "Enter the general {\em formula} for the entries:")
    (text . "\newline\tab{2} ")
    (bcStrings (40 "1/(x - i - j - 1)" formula FE)))
  htMakeDoneButton('"Continue", 'bcInputMatrixByFormulaGen)
  nrows :=
    null $bcParseOnly => objValUnwrap htpLabelSpadValue(htPage,'rows)
    PARSE_-INTEGER htpLabelInputString(htPage,'rows)
  ncols :=
    null $bcParseOnly => objValUnwrap htpLabelSpadValue(htPage,'cols)
    PARSE_-INTEGER htpLabelInputString(htPage,'cols)
  htpSetProperty(page, 'nrows, nrows)
  htpSetProperty(page, 'ncols, ncols)
  htShowPage()

bcInputMatrixByFormulaGen htPage ==
  fun :=  htpProperty(htPage,'exitFunction) => FUNCALL(fun, htPage)
  formula := htpLabelInputString(htPage,'formula)
  rowVar := htpLabelInputString(htPage,'rowVar)
  colVar := htpLabelInputString(htPage,'colVar)
  nrows := htpProperty(htPage,'nrows)
  ncols := htpProperty(htPage,'ncols)
  bcGen STRCONC('"matrix([[",formula,'" for ",colVar,'" in 1..",
    STRINGIMAGE ncols,'"] for ",rowVar,'" in 1..",STRINGIMAGE nrows,'"])")

bcInputExplicitMatrix(htPage,junk) ==
  nrows :=
    null $bcParseOnly => objValUnwrap htpLabelSpadValue(htPage,'rows)
    PARSE_-INTEGER htpLabelInputString(htPage,'rows)
  ncols :=
    null $bcParseOnly => objValUnwrap htpLabelSpadValue(htPage,'cols)
    PARSE_-INTEGER htpLabelInputString(htPage,'cols)
  cond := nil
  k := 0
  wrows := # STRINGIMAGE nrows
  wcols := # STRINGIMAGE ncols
  labelList :=
    "append"/[[f for j in 1..ncols] for i in 1..nrows] where f ==
      rowpart := STRCONC('"{\em Row",htStringPad(i,wrows))
      colpart := STRCONC('", Column",htStringPad(j,wcols),'":}\space{2}")
      prefix := STRCONC(rowpart,colpart)
 --     name := INTERN STRCONC(htMkName('"row",i),htMkName('"col",j))
      name := INTERN STRINGIMAGE (k := k + 1)
      [prefix,'"",30, 0,name,'P]
  labelList :=
    [['domainConditions, '(isDomain P (Polynomial $EmptyMode)), cond],
     ['inputStrings, :labelList] ]
  page := htInitPage('"Solve Basic Command", htpPropertyList htPage)
  bcHt '"Enter the entries of the matrix:"
  htMakePage labelList
  htMakeDoneButton('"Continue", 'bcGenExplicitMatrix)
  htpSetProperty(page,'nrows,nrows)
  htpSetProperty(page,'ncols,ncols)
  htShowPage()

bcGenExplicitMatrix htPage ==
  htpSetProperty(htPage,'matrix,htpInputAreaAlist htPage)
  fun :=  htpProperty(htPage,'exitFunction) => FUNCALL(fun, htPage)
  bcGen bcMatrixGen htPage

bcMatrixGen htPage ==
  nrows := htpProperty(htPage,'nrows)
  ncols := htpProperty(htPage,'ncols)
  mat := htpProperty(htPage,'matrix)
  formula := LASSOC('formula,mat) =>
    formula := formula.0
    rowVar := (LASSOC('rowVar, mat)).0
    colVar := (LASSOC('colVar, mat)).0
    STRCONC('"matrix([[",formula,'" for ",colVar,'" in 1..",
      STRINGIMAGE ncols,'"] for ",rowVar,'" in 1..",STRINGIMAGE nrows,'"])")
  mat := htpProperty(htPage,'matrix) =>
    mat := REVERSE mat
    k := -1
    matform := [[mat.(k := k + 1).1
      for j in 0..(ncols-1)] for i in 0..(nrows-1)]
    matstring := bcwords2liststring [bcwords2liststring x for x in matform]
    STRCONC('"matrix(",matstring,'")")
  systemError nil
