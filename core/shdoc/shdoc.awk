#!/usr/bin/awk -f

# Source: https://github.com/reconquest/shdoc/blob/master/shdoc

BEGIN {
    if (! style) {
        style = "github"
    }

    styles["github", "h1", "from"] = ".*"
    styles["github", "h1", "to"] = "# &"

    styles["github", "h2", "from"] = ".*"
    styles["github", "h2", "to"] = "## &"

    styles["github", "h3", "from"] = ".*"
    styles["github", "h3", "to"] = "### &"

    styles["github", "h4", "from"] = ".*"
    styles["github", "h4", "to"] = "#### &"

    styles["github", "code", "from"] = ".*"
    styles["github", "code", "to"] = "```&"

    styles["github", "/code", "to"] = "```"

    styles["github", "argN", "from"] = "^([[:alnum:]]{1,}) (\\S+)"
    styles["github", "argN", "to"] = "**\\1** (\\2):"

    styles["github", "arg@", "from"] = "^\\$@ (\\S+)"
    styles["github", "arg@", "to"] = "**...** (\\1):"

    styles["github", "li", "from"] = ".*"
    styles["github", "li", "to"] = "* &"

    styles["github", "i", "from"] = ".*"
    styles["github", "i", "to"] = "_&_"

    styles["github", "anchor", "from"] = ".*"
    styles["github", "anchor", "to"] = "[&](#&)"

    styles["github", "return", "from"] = "(.*)"
    styles["github", "return", "to"] = "\\1"

    styles["github", "exitcode", "from"] = "([>!]?[0-9]{1,3}) (.*)"
    styles["github", "exitcode", "to"] = "**\\1**: \\2"
}

function render(type, text) {
    return gensub( \
        styles[style, type, "from"],
        styles[style, type, "to"],
        "g",
        text \
    )
}

function reset() {
    has_example = 0
    has_args = 0
    has_return = 0
    has_exitcode = 0
    has_stdout = 0
    has_stderr = 0
}

/^[[:space:]]*# @internal/ {
    is_internal = 1
}

/^[[:space:]]*# @file/ {
    sub(/^[[:space:]]*# @file /, "")
    filedoc = render("h1", $0) "\n"
}

/^[[:space:]]*# @brief/ {
    sub(/^[[:space:]]*# @brief /, "")
    filedoc = filedoc "\n" $0
}

/^[[:space:]]*# @description/ {
    in_description = 1
    in_example = 0

    reset()

    docblock = ""
}

in_description {
    if (/^[^[[:space:]]*#]|^[[:space:]]*# @[^d]|^[[:space:]]*[^#]/) {
        if (!match(docblock, /\n$/)) {
            docblock = docblock "\n"
        }
        in_description = 0
    } else {
        sub(/^[[:space:]]*# @description /, "")
        sub(/^[[:space:]]*# /, "")
        sub(/^[[:space:]]*#$/, "")

        docblock = docblock "\n" $0
    }
}

in_example {
    if (! /^[[:space:]]*#[ ]{3}/) {
        in_example = 0

        docblock = docblock "\n" render("/code") "\n"
    } else {
        sub(/^[[:space:]]*#[ ]{3}/, "")

        docblock = docblock "\n" $0
    }
}

/^[[:space:]]*# @example/ {
    in_example = 1

    docblock = docblock "\n" render("h3", "Example")
    docblock = docblock "\n\n" render("code", "bash")
}

/^[[:space:]]*# @arg/ {
    if (!has_args) {
        has_args = 1

        docblock = docblock "\n" render("h3", "Arguments") "\n\n"
    }

    sub(/^[[:space:]]*# @arg /, "")

    $0 = render("argN", $0)
    $0 = render("arg@", $0)

    docblock = docblock render("li", $0) "\n"
}

/^[[:space:]]*# @noargs/ {
    docblock = docblock "\n" render("i", "Function has no arguments.") "\n"
}

/^[[:space:]]*# @return/ {
    if (!has_return) {
        has_return = 1

        docblock = docblock "\n" render("h3", "Return value") "\n\n"
    }

    sub(/^[[:space:]]*# @return /, "")

    $0 = render("return", $0)

    docblock = docblock render("li", $0) "\n"
}

/^[[:space:]]*# @exitcode/ {
    if (!has_exitcode) {
        has_exitcode = 1

        docblock = docblock "\n" render("h3", "Exit codes") "\n\n"
    }

    sub(/^[[:space:]]*# @exitcode /, "")

    $0 = render("exitcode", $0)

    docblock = docblock render("li", $0) "\n"
}

/^[[:space:]]*# @see/ {
    sub(/[[:space:]]*# @see /, "")

    $0 = render("anchor", $0)
    $0 = render("li", $0)

    docblock = docblock "\n" render("h4", "See also") "\n\n" $0 "\n"
}

/^[[:space:]]*# @stdout/ {
    has_stdout = 1

    sub(/^[[:space:]]*# @stdout /, "")

    docblock = docblock "\n" render("h3", "Output on stdout")
    docblock = docblock "\n\n" render("li", $0) "\n"
}

/^[[:space:]]*# @stderr/ {
    has_stderr = 1

    sub(/^[[:space:]]*# @stderr /, "")

    docblock = docblock "\n" render("h3", "Output on stderr")
    docblock = docblock "\n\n" render("li", $0) "\n"
}

/^[ \t]*(function([ \t])+)?([a-zA-Z0-9_:-]+)([ \t]*)(\(([ \t]*)\))?[ \t]*\{/ && docblock != "" {
    if (is_internal) {
        is_internal = 0
    } else {
        func_name = ENVIRON["SHDOC_LIB"] gensub(\
            /^[ \t]*(function([ \t])+)?([a-zA-Z0-9_:-]+)[ \t]*\(.*/, \
            "\\3()", \
            "g" \
        )

        doc = doc "\n" render("h1", func_name) "\n" docblock

        url = func_name
        if (style == "github") {
          # https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/toc_filter.rb#L44-L45
          url = tolower(url)
          gsub(/[^[:alnum:] -]/, "", url)
          gsub(/ /, "-", url)
        }

        toc = toc "\n" "* [" func_name "](#" url ")"
    }

    docblock = ""
    reset()
}

END {
    if (filedoc != "") {
        print filedoc
    }
    print toc
    print ""
    print doc
}