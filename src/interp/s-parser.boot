)package "BOOT"

DEFPARAMETER($ParseMode, NIL)
DEFPARAMETER($LABLASOC, NIL)


-- PURPOSE: This file sets up properties which are used by the Boot lexical
--          analyzer for bottom-up recognition of operators.  Also certain
--          other character-class definitions are included, as well as
--          table accessing functions.
--
-- 1. Led and Nud Tables
--
-- TABLE PURPOSE

-- Led and Nud have to do with operators. An operator with a Led property takes
-- an operand on its left (infix/suffix operator).

-- An operator with a Nud takes no operand on its left (prefix/nilfix).
-- Some have both (e.g. - ).  This terminology is from the Pratt parser.
-- The translator for Scratchpad II is a modification of the Pratt parser which
-- branches to special handlers when it is most convenient and practical to
-- do so (Pratt's scheme cannot handle local contexts very easily).

-- Both LEDs and NUDs have right and left binding powers.  This is meaningful
-- for prefix and infix operators.  These powers are stored as the values of
-- the LED and NUD properties of an atom, if the atom has such a property.
-- The format is:

--     <Operator Left-Binding-Power  Right-Binding-Power <Special-Handler>>

-- where the Special-Handler is the name of a function to be evaluated when
-- that keyword is encountered.

-- The default values of Left and Right Binding-Power are NIL.  NIL is a
-- legitimate value signifying no precedence.  If the Special-Handler is NIL,
-- this is just an ordinary operator (as opposed to a surfix operator like
-- if-then-else).

-- ** TABLE CREATION

MAKEOP(X, Y) ==
    if OR(NOT (CDR X), NUMBERP (SECOND X)) then
        X := CONS(FIRST X, X)
    MAKEPROP(FIRST X, Y, X)

init_parser_properties() ==
    for j in _
         [["*", 800, 801],   ["rem", 800, 801],   ["mod", 800, 801], _
          ["quo", 800, 801],   ["div", 800, 801], _
          ["/", 800, 801],    ["**", 901, 900],  ["^", 901, 900], _
          ["exquo", 800, 801], ["+", 700, 701], _
          ["-", 700, 701],    ["->", 1002, 1001],  ["<-", 1001, 1002], _
          [":", 996, 997],    ["::", 996, 997], _
          ["@", 996, 997],    ["pretend", 995, 996], _
          ["."],            ["!", 1002, 1001], _
          [",", 110, 111], _
          [";", 81, 82, ["parse_SemiColon"]], _
          ["<", 400, 400],    [">", 400, 400], _
          ["<<", 400, 400],  [">>", 400, 400], _
          ["<=", 400, 400],   [">=", 400, 400], _
          ["=", 400, 400],     ["^=", 400, 400], _
          ["~=", 400, 400], _
          ["in", 400, 400],    ["case", 400, 400], _
          ["add", 400, 120],   ["with", 2000, 400, ["parse_InfixWith"]], _
          ["has", 400, 400], _
          ["where", 121, 104], _
          ["when", 112, 190], _
          ["otherwise", 119, 190, ["parse_Suffix"]], _
          ["is", 400, 400],    ["isnt", 400, 400], _
          ["and", 250, 251],   ["or", 200, 201], _
          ["/\", 250, 251],   ["\/", 200, 201], _
          ["..", "SEGMENT", 401, 699, ["parse_Seg"]], _
          ["=>", 123, 103], _
          ["+->", 995, 112], _
          ["==", "DEF", 122, 121], _
          ["==>", "MDEF", 122, 121], _
          ["|", 108, 111], _
          [":=", "LET", 125, 124]] repeat
        MAKEOP(j, "Led")

    for j in _
         [["for", 130, 350, ["parse_Loop"]], _
          ["while", 130, 190, ["parse_Loop"]], _
          ["until", 130, 190, ["parse_Loop"]], _
          ["repeat", 130, 190, ["parse_Loop"]], _
          ["import", 120, 0, ["parse_Import"]], _
          ["unless"], _
          ["add", 900, 120], _
          ["with", 1000, 300, ["parse_With"]], _
          ["has", 400, 400], _
          ["-", 701, 700], _
          ["#", 999, 998], _
          ["!", 1002, 1001], _
          ["'", 999, 999, ["parse_Data"]], _
          ["<<", 122, 120, ["parse_LabelExpr"]], _
          [">>"], _
          ["->", 1001, 1002], _
          [":", 194, 195], _
          ["not", 260, 259, NIL], _
          ["~", 260, 259, nil], _
          ["=", 400, 700], _
          ["return", 202, 201, ["parse_Return"]], _
          ["leave", 202, 201, ["parse_Leave"]], _
          ["exit", 202, 201, ["parse_Exit"]], _
          ["from"], _
          ["iterate"], _
          ["yield"], _
          ["if", 130, 0, ["parse_Conditional"]], _
          ["|", 0, 190], _
          ["suchthat"], _
          ["then", 0, 114], _
          ["else", 0, 114]] repeat
        MAKEOP(j, "Nud")

init_parser_properties()

push_lform0(tag) ==
    push_reduction("dummy", tag)

push_form0(tag) ==
    push_reduction("dummy", [tag])

push_lform1(tag, arg1) ==
    push_reduction("dummy", [tag, :arg1])

push_form1(tag, arg1) ==
    push_reduction("dummy", [tag, arg1])

push_lform2(tag, arg1, arg2) ==
    push_reduction("dummy", [tag, arg1, :arg2])

push_form2(tag, arg1, arg2) ==
    push_reduction("dummy", [tag, arg1, arg2])

push_form3(tag, arg1, arg2, arg3) ==
    push_reduction("dummy", [tag, arg1, arg2, arg3])

parse_new_expr() == parse_Expr 0

parse_InfixWith() ==
    not(parse_With()) => nil
    push_form2("Join", pop_stack_2(), pop_stack_1())

parse_With() ==
    not(match_symbol "with") => nil
    MUST parse_Category()
    push_form1("with", pop_stack_1())

repetition(delimiter, fn) ==
    val := nil
    repeat
        if delimiter then
            if not(match_symbol(delimiter)) then return nil -- break loop
            MUST(FUNCALL fn)
        else
            if not(FUNCALL fn) then return nil -- break loop
        val := [pop_stack_1(), :val]
    val => push_lform0(nreverse(val))
    nil

-- category : if expression then category [else category]
--          | '(' category* ')'
--          | application [':' expression]
--          ;
parse_Category() ==
    match_symbol "if" =>
        MUST parse_Expression()
        cond := pop_stack_1()
        MUST match_symbol "then"
        MUST parse_Category()
        else_val :=
            match_symbol "else" =>
                MUST parse_Category()
                pop_stack_1()
            nil
        push_form3("if", cond, pop_stack_1(), else_val)
    match_symbol "(" =>
        MUST
            match_symbol ")" => push_form0("CATEGORY")
            MUST(parse_Category())
            tail_val :=
                repetition(";", FUNCTION parse_Category) => pop_stack_1()
                nil
            MUST match_symbol ")"
            push_lform2("CATEGORY", pop_stack_1(), tail_val)
    G1 := LINE_-NUMBER CURRENT_-LINE
    not(parse_Application()) => nil
    MUST
        OR(
              AND(match_symbol ":", MUST parse_Expression(),
                  push_form2("Signature", pop_stack_2(), pop_stack_1()),
                  ACTION recordSignatureDocumentation(NTH_-STACK 1, G1)),
              AND(push_form1("Attribute", pop_stack_1()),
                  ACTION recordAttributeDocumentation(NTH_-STACK 1, G1)))

parse_Expression() ==
    parse_Expr
     parse_rightBindingPowerOf(MAKE_-SYMBOL_-OF PRIOR_-TOKEN, $ParseMode)

parse_Expr1000() == parse_Expr 1000

-- import : 'import' expr_1000 [',' expr_1000]*
parse_Import() ==
    not(match_symbol "import") => nil
    MUST parse_Expr 1000
    tail_val :=
        repetition(",", FUNCTION parse_Expr1000) => pop_stack_1()
        nil
    push_lform2("import", pop_stack_1(), tail_val)

parse_Infix() ==
    push_reduction("parse_Infix", current_symbol())
    advance_token()
    parse_TokTail()
    MUST parse_Expression()
    push_reduction("parse_Infix",
                   [pop_stack_2(), pop_stack_2(), pop_stack_1()])

parse_Prefix() ==
    push_reduction("parse_Prefix", current_symbol())
    advance_token()
    parse_TokTail()
    MUST parse_Expression()
    push_reduction("parse_Prefix", [pop_stack_2(), pop_stack_1()])

parse_Suffix() ==
    push_reduction("parse_Suffix", current_symbol())
    advance_token()
    parse_TokTail()
    push_reduction("parse_Suffix", [pop_stack_1(), pop_stack_1()])

parse_TokTail() ==
    $BOOT or current_symbol() ~= "$" => nil
    not(OR(MATCH_-NEXT_-TOKEN("IDENTIFIER", NIL), next_symbol() = "%",
           next_symbol() = "(")) => nil                     -- )
    G1 := COPY_-TOKEN PRIOR_-TOKEN
    not(parse_Qualification()) => nil
    SETF(PRIOR_-TOKEN, G1)

parse_Qualification() ==
    not(match_symbol "$") => nil
    MUST parse_Primary1()
    push_reduction("parse_Qualification",
                   dollarTran(pop_stack_1(), pop_stack_1()))

parse_SemiColon() ==
    not(match_symbol ";") => nil
    OR(parse_Expr 82,
       push_reduction("parse_SemiColon", "/throwAway"))
    push_form2(";", pop_stack_2(), pop_stack_1())

parse_Return() ==
    not(match_symbol "return") => nil
    MUST parse_Expression()
    push_form1("return", pop_stack_1())

parse_Exit() ==
    not(match_symbol "exit") => nil
    OR(parse_Expression(), push_reduction("parse_Exit", "$NoValue"))
    push_form1("exit", pop_stack_1())

parse_Leave() ==
    not(match_symbol "leave") => nil
    OR(parse_Expression(), push_reduction("parse_Leave", "$NoValue"))
    match_symbol "from" =>
        MUST parse_Label()
        push_form2("leaveFrom", pop_stack_1(), pop_stack_1())
    push_form1("leave", pop_stack_1())

parse_Seg() ==
    not(parse_GliphTok "..") => nil
    right_val :=
        parse_Expression() => pop_stack_1()
        nil
    push_form2("SEGMENT", pop_stack_1(), right_val)

parse_Conditional() ==
    not(match_symbol "if") => nil
    MUST parse_Expression()
    MUST match_symbol "then"
    MUST parse_Expression()
    else_val :=
        match_symbol "else" =>
            MUST parse_ElseClause()
            pop_stack_1()
        nil
    push_form3("if", pop_stack_2(), pop_stack_1(), else_val)

parse_ElseClause() ==
    current_symbol() = "if" => parse_Conditional()
    parse_Expression()

parse_Loop() ==
    OR(AND(repetition(nil, FUNCTION parse_Iterator),
           MUST match_symbol "repeat", MUST parse_Expr 110,
           push_lform1("REPEAT", [:pop_stack_2(), pop_stack_1()])),
       AND(match_symbol "repeat", MUST parse_Expr 110,
           push_form1("REPEAT", pop_stack_1())))

parse_Iterator() ==
    match_symbol "for" =>
        MUST parse_Primary()
        MUST match_symbol "in"
        MUST parse_Expression()
        by_val :=
              AND(match_symbol "by", MUST parse_Expr 200) => pop_stack_1()
              nil
        bar_val :=
            AND(match_symbol "|", MUST parse_Expr 111) => pop_stack_1()
            nil
        in_val := pop_stack_1()
        if bar_val then
            in_val := ["|", in_val, bar_val]
        if by_val then
            push_form3("INBY", pop_stack_1(), in_val, by_val)
        else
            push_form2("IN", pop_stack_1(), in_val)
    match_symbol "while" =>
        MUST parse_Expr 190
        push_form1("WHILE", pop_stack_1())
    match_symbol "until" =>
        MUST parse_Expr 190
        push_form1("UNTIL", pop_stack_1())
    nil

parse_Expr($RBP) ==
    not(parse_NudPart($RBP)) => nil
    while parse_LedPart($RBP) repeat nil
    push_reduction("parse_Expr", pop_stack_1())

parse_LabelExpr() ==
    not(parse_Label()) => nil
    MUST parse_Expr(120)
    push_form2("LABEL", pop_stack_2(), pop_stack_1())

parse_Label() ==
    not(match_symbol "<<") => nil
    MUST parse_Name()
    MUST match_symbol ">>"

parse_LedPart($RBP) ==
    not(parse_Operation("Led", $RBP)) => nil
    push_reduction("parse_LedPart", pop_stack_1())

parse_NudPart($RBP) ==
    AND(OR(parse_Operation("Nud", $RBP), parse_Reduction(), parse_Form()),
        push_reduction("parse_NudPart", pop_stack_1()))

parse_Operation($ParseMode, $RBP) ==
    match_current_token("IDENTIFIER", NIL) => nil
    GETL(tmptok := current_symbol(), $ParseMode) and
      $RBP < parse_leftBindingPowerOf(tmptok, $ParseMode) =>
        $RBP := parse_rightBindingPowerOf(tmptok, $ParseMode)
        parse_getSemanticForm($ParseMode,
                               ELEMN(GETL(tmptok, $ParseMode), 5, NIL))

parse_leftBindingPowerOf(x, ind) ==
    (y := GETL(x, ind)) => ELEMN(y, 3, 0)
    0

parse_rightBindingPowerOf(x, ind) ==
    (y := GETL(x, ind)) => ELEMN(y, 4, 105)
    105

parse_getSemanticForm(ind, y) ==
    AND(y, FUNCALL(CAR y)) => true
    ind = "Nud" => parse_Prefix()
    ind = "Led" => parse_Infix()
    nil

parse_Reduction() ==
    parse_ReductionOp() =>
        MUST parse_Expr 1000
        push_form2("Reduce", pop_stack_2(), pop_stack_1())
    nil

parse_ReductionOp() ==
    AND(GETL(current_symbol(), "Led"), MATCH_-NEXT_-TOKEN("KEYWORD", "/"),
        push_reduction("parse_ReductionOp", current_symbol()),
        ACTION advance_token(), ACTION advance_token())

parse_Form() ==
    match_symbol "iterate" =>
        from_val :=
            match_symbol "from" =>
                MUST parse_Label()
                [pop_stack_1()]
            nil
        push_lform1("iterate", from_val)
    match_symbol "yield" =>
        MUST parse_Application()
        push_form1("yield", pop_stack_1())
    parse_Application()

parse_Application() ==
    not(parse_Primary()) => nil
    while parse_Selector() repeat nil
    parse_Application() =>
        push_reduction("parse_Application", [pop_stack_2(), pop_stack_1()])
    true

parse_Selector() ==
    not(match_symbol ".") => nil
    MUST parse_Primary()
    $BOOT => push_form2("ELT", pop_stack_2(), pop_stack_1())
    push_reduction("parse_Selector",
                         [pop_stack_2(), pop_stack_1()])

parse_PrimaryNoFloat() ==
    AND(parse_Primary1(), OPTIONAL(parse_TokTail()))

parse_Primary() == OR(parse_Float(), parse_PrimaryNoFloat())

parse_Primary1() ==
    OR(
       AND(parse_VarForm(),
           OPTIONAL AND(
              NONBLANK, current_symbol() = "(", MUST parse_Enclosure(),
              push_reduction("parse_Primary1",
                             [pop_stack_2(), pop_stack_1()]))),
       parse_Quad(), parse_String(), parse_IntegerTok(),
       parse_FormalParameter(),
       AND(symbol_is? "'",
          MUST OR(
             AND($BOOT, parse_Data()),
             AND(match_symbol "'", MUST parse_Expr 999,
                 push_form1("QUOTE", pop_stack_1())))),
       parse_Sequence(), parse_Enclosure())

parse_Float() == parse_SPADFLOAT()

parse_Enclosure() ==
    match_symbol "(" =>
        MUST OR(  -- (
               AND(parse_Expr 6, MUST match_symbol ")"), -- (
               AND(match_symbol ")",
                   push_form0("@Tuple")))
    nil

parse_IntegerTok() == parse_NUMBER()

parse_FormalParameter() == parse_ARGUMENT_-DESIGNATOR()

parse_Quad() ==
    OR(AND($BOOT, match_symbol "$", push_lform0("$")),
       AND($BOOT, parse_GliphTok("."), push_lform0(".")))

parse_String() == parse_SPADSTRING()

parse_VarForm() == parse_IDENTIFIER()

parse_Name() == parse_IDENTIFIER()

parse_Data() ==
    AND(ACTION ($LABLASOC := NIL), parse_Sexpr(),
        push_form1("QUOTE", TRANSLABEL(pop_stack_1(), $LABLASOC)))

parse_Sexpr() == AND(ACTION(advance_token()), parse_Sexpr1())

parse_Sexpr1() ==
    parse_AnyId() =>
        if parse_NBGliphTok "=" then
            MUST parse_Sexpr1()
            $LABLASOC := [[pop_stack_2(), :NTH_-STACK 1], :$LABLASOC]
        true
    match_symbol "'" =>
        MUST parse_Sexpr1()
        push_form1("QUOTE", pop_stack_1())
    parse_IntegerTok() => true
    match_symbol "-" =>
        MUST parse_IntegerTok()
        push_reduction("parse_Sexpr1", MINUS pop_stack_1())
    parse_String() => true
    match_symbol "<" =>
        seq_val :=
            repetition(nil, FUNCTION parse_Sexpr1) => pop_stack_1()
            nil
        MUST match_symbol ">"
        push_reduction("parse_Sexpr1", LIST2VEC(seq_val))
    match_symbol "(" =>
        if repetition(nil, FUNCTION parse_Sexpr1) then
            OPTIONAL AND(
                        parse_GliphTok ".", MUST parse_Sexpr1(),
                        push_reduction("parse_Sexpr1",
                                       NCONC(pop_stack_2(),
                                             pop_stack_1())))
        else
            push_reduction("parse_Sexpr1", nil)
        MUST match_symbol ")"
    nil

parse_NBGliphTok(tok) ==
   AND(match_current_token("KEYWORD", tok),
       NONBLANK,
       ACTION(advance_token()))

parse_AnyId() ==
    OR(parse_IDENTIFIER(),
       OR(AND(symbol_is? "$",
              push_reduction("parse_AnyId", current_symbol()),
              ACTION advance_token()),
        parse_AKEYWORD()))

parse_GliphTok(tok) ==
  AND(match_current_token('KEYWORD, tok), ACTION(advance_token()))

parse_Sequence() ==
    match_symbol "[" =>
        MUST(parse_Sequence1())
        MUST(match_symbol "]")
)if false
    match_symbol "{" =>
        MUST(parse_Sequence1())
        MUST(match_symbol "}")
        push_form1("brace", pop_stack_1())
)endif
    nil

parse_Sequence1() ==
    val :=
        parse_Expression() => [pop_stack_1()]
        nil
    push_reduction("parse_Sequence1", ["construct", :val])
    OPTIONAL
      AND(parse_IteratorTail(),
          push_lform1("COLLECT", [:pop_stack_1(),
                                       pop_stack_1()]))

-- IteratorTail : "repeat" [Iterator*] | [Iterator*]
parse_IteratorTail() ==
    match_symbol("repeat") =>
        repetition(nil, FUNCTION parse_Iterator) => true
        push_reduction("null_Tail", nil)
    repetition(nil, FUNCTION parse_Iterator)
