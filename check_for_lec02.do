display "OS: " c(os)
display "PWD: " c(pwd)

macro list PROJ RAW CLEAN DO LOG OUT

display "$DO"
dir "$DO/"

confirm file "$DO/01_import.do"
confirm file "$DO\01_import.do"
