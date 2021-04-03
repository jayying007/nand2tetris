/**
 * @author Administrator
 * @since 2021/3/31
 */
public enum Keyword {
    CLASS("class"),
    METHOD("method"),
    INT("int"),
    FUNCTION("function"),
    BOOLEAN("boolean"),
    CONSTRUCTOR("constructor"),
    CHAR("char"),
    VOID("void"),
    VAR("var"),
    STATIC("static"),
    FIELD("field"),
    LET("let"),
    DO("do"),
    IF("if"),
    ELSE("else"),
    WHILE("while"),
    RETURN("return"),
    TRUE("true"),
    FALSE("false"),
    NULL("null"),
    THIS("this");

    private String value;
    Keyword(String value) {
        this.value = value;
    }
    public String getValue() {
        return this.value;
    }
}
