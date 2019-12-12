OPTION _EXPLICIT
CONST true = -1, false = 0
CONST debugging = true

$CONSOLE

DIM l$
DO
    LINE INPUT l$
    _ECHO "--------- new call ---------"
    PRINT Parse(l$)
LOOP

'Adapted from https://www.codeproject.com/Articles/1205435/Parsing-Mathematical-Expressions-in-VB-NET-Missi
' Call this routine to perform the actual mathematic expression parsing
FUNCTION Parse$ (__inputExpr AS STRING)
    DIM t AS _UNSIGNED LONG, index AS _UNSIGNED LONG
    DIM totalStrings AS _UNSIGNED LONG
    DIM inputExpr AS STRING
    REDIM oe(0) AS _UNSIGNED LONG
    REDIM strings(0) AS STRING

    inputExpr = "(" + __inputExpr + ")"

    t = 1
    ' Iterate through the characters of input string starting at the position of final character
    FOR index = LEN(inputExpr) - 1 TO 0 STEP -1
        ' For each character perform a check if its value is '('
        IF ASC(inputExpr, index + 1) = 40 OR index = 0 THEN
            DIM sb AS STRING
            sb = ""
            DIM n AS _UNSIGNED LONG
            ' Perform a check if this is the first character in string
            IF index = 0 THEN
                ' If so assign n variable to the value of variable index
                n = 1
                IF debugging THEN _ECHO "Beginning of expression reached; n =" + STR$(n)
            ELSE
                ' Otherwise assign n variable to the value of variable index + 1
                n = index + 1
                IF debugging THEN _ECHO "'(' found at" + STR$(index) + "; n =" + STR$(n)
            END IF

            DIM exists AS _BYTE
            DO
                exists = false
                DIM bracket AS _BYTE
                bracket = false
                ' Perform the iterations stepping forward into each succeeding character
                ' starting at the position n = index + 1 until we've found a character equal to ')'
                WHILE n < LEN(inputExpr) AND bracket = false
                    ' Check if the current character is not ')'.
                    IF ASC(inputExpr, n + 1) <> 41 THEN
                        ' If so, append it to the temporary string buffer
                        sb = sb + MID$(inputExpr, n + 1, 1)
                        ' Otherwise break the loop execution
                    ELSE
                        bracket = true
                    END IF
                    ' Increment the n loop counter variable by 1
                    n = n + 1
                WEND
                DIM r AS _UNSIGNED LONG
                r = 0
                ' Iterate through the array of positions
                WHILE r <= UBOUND(oe) AND exists = false
                    ' For each element perform a check if its value
                    ' is equal to the position of the current ')' character
                    IF oe(r) = n THEN
                        ' If so, append the character ')' to the temporary string buffer and break
                        ' the loop execution assigning the variable exists to the value 'true'
                        exists = true
                        sb = sb + ") "
                        'n = n + 1
                    END IF
                    r = r + 1
                WEND

                ' Repeat the following loop execution until we've found the character ')' at
                ' the New position which is not in the array of positions
            LOOP WHILE exists = true

            ' If the current character's ')' position has not been previous found,
            ' add the value of position to the array
            IF exists = false THEN
                REDIM _PRESERVE oe(UBOUND(oe) + 1)
                oe(t) = n
                t = t + 1
            END IF

            ' Add the currently obtained string containing a specific part of the expression to the array
            totalStrings = totalStrings + 1
            REDIM _PRESERVE strings(totalStrings)
            strings(totalStrings) = sb
            IF debugging THEN _ECHO "Substring stored: " + sb
        END IF
    NEXT

    ' Iterate through the array of the expression parts
    FOR index = 1 TO totalStrings
        ' Compute the result for the current part of the expression
        DIM Result AS STRING
        Result = STR$(Compute(strings(index)))
        IF debugging THEN _ECHO "Computing: " + strings(index)

        ' Iterate through all succeeding parts of the expression
        FOR n = index TO totalStrings
            ' For each part substitute the substring containing the current part of the expression
            ' with its numerical value without parentheses.
            IF debugging THEN _ECHO "Passing substring to Replace(): " + strings(n)
            strings(n) = Replace(strings(n), "(" + strings(index) + ")", Result, 0, 0)
            IF debugging THEN _ECHO "           Result of Replace(): " + strings(n)
        NEXT
    NEXT
    ' Compute the numerical value of the last part (e.g. the numerical resulting value of the entire expression)
    ' and return this value at the end of the following routine execution.
    Parse$ = STR$(Compute(strings(totalStrings)))
END FUNCTION

FUNCTION Compute## (expr AS STRING)
    DIM i AS _UNSIGNED LONG, j AS _UNSIGNED LONG
    DIM validOP$
    DIM a AS _UNSIGNED _BYTE, ch AS STRING
    DIM tempValue AS STRING
    REDIM op(0) AS STRING, elements(0) AS STRING

    validOP$ = "^*/+-"
    REDIM op(1 TO LEN(validOP$)) AS STRING
    FOR i = 1 TO LEN(validOP$)
        op(i) = MID$(validOP$, i, 1)
    NEXT

    'break down expr into elements()
    FOR i = 1 TO LEN(expr)
        a = ASC(expr, i)
        ch = CHR$(a)
        IF INSTR(validOP$, ch) THEN
            'this is an operator
        ELSE
            tempValue = tempValue + ch
        END IF
    NEXT

END FUNCTION

FUNCTION arrayContains%% (array() AS STRING, text$)
    DIM i AS _UNSIGNED LONG
    FOR i = LBOUND(array) TO UBOUND(array)
        IF array(i) = text$ THEN arrayContains%% = true: EXIT FUNCTION
    NEXT
END FUNCTION

FUNCTION Replace$ (TempText$, SubString$, NewString$, CaseSensitive AS _BYTE, TotalReplacements AS LONG)
    DIM FindSubString AS LONG, Text$

    IF LEN(TempText$) = 0 THEN EXIT SUB

    Text$ = TempText$
    TotalReplacements = 0
    DO
        IF CaseSensitive THEN
            FindSubString = INSTR(FindSubString + 1, Text$, SubString$)
        ELSE
            FindSubString = INSTR(FindSubString + 1, UCASE$(Text$), UCASE$(SubString$))
        END IF
        IF FindSubString = 0 THEN EXIT DO
        IF LEFT$(SubString$, 1) = "\" THEN 'Escape sequence
            'Replace the Substring if it's not preceeded by another backslash
            IF MID$(Text$, FindSubString - 1, 1) <> "\" THEN
                Text$ = LEFT$(Text$, FindSubString - 1) + NewString$ + MID$(Text$, FindSubString + LEN(SubString$))
                TotalReplacements = TotalReplacements + 1
            END IF
        ELSE
            Text$ = LEFT$(Text$, FindSubString - 1) + NewString$ + MID$(Text$, FindSubString + LEN(SubString$))
            TotalReplacements = TotalReplacements + 1
        END IF
    LOOP

    Replace$ = Text$
END FUNCTION

FUNCTION isNumber%% (a$)
    DIM i AS _UNSIGNED LONG
    DIM d AS _UNSIGNED LONG, e AS _UNSIGNED LONG
    DIM dp AS _BYTE
    DIM a AS _UNSIGNED _BYTE

    IF LEN(a$) = 0 THEN EXIT FUNCTION
    FOR i = 1 TO LEN(a$)
        a = ASC(MID$(a$, i, 1))
        IF a = 45 THEN
            IF (i = 1 AND LEN(a$) > 1) OR (i > 1 AND ((d > 0 AND d = i - 1) OR (e > 0 AND e = i - 1))) THEN _CONTINUE
            EXIT FUNCTION
        END IF
        IF a = 46 THEN
            IF dp = 1 THEN EXIT FUNCTION
            dp = 1
            _CONTINUE
        END IF
        IF a = 100 OR a = 68 THEN 'D
            IF d > 0 OR e > 0 THEN EXIT FUNCTION
            IF i = 1 THEN EXIT FUNCTION
            d = i
            _CONTINUE
        END IF
        IF a = 101 OR a = 69 THEN 'E
            IF d > 0 OR e > 0 THEN EXIT FUNCTION
            IF i = 1 THEN EXIT FUNCTION
            e = i
            _CONTINUE
        END IF
        IF a = 43 THEN '+
            IF (d > 0 AND d = i - 1) OR (e > 0 AND e = i - 1) THEN _CONTINUE
            EXIT FUNCTION
        END IF

        IF a >= 48 AND a <= 57 THEN _CONTINUE
        EXIT FUNCTION
    NEXT
    isNumber%% = true
END FUNCTION

