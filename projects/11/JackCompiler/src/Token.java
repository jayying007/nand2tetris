/**
 * @author Administrator
 * @since 2021/4/1
 */
class Token {
    TokenType tokenType;
    Keyword keyword;
    Object value;

    public Token(TokenType tokenType, Keyword keyword, Object value) {
        this.tokenType = tokenType;
        this.keyword = keyword;
        this.value = value;
    }

    public TokenType tokenType() {
        return tokenType;
    }
    public Keyword keyword() {
        return keyword;
    }
    public Character symbol() {
        return (Character)value;
    }
    public String identifier() {
        return (String)value;
    }
    public int intVal() {
        return (Integer)value;
    }
    public String stringVal() {
        return (String)value;
    }

    @Override
    public String toString() {
        return "Node" + '"' +
                "tokenType=" + tokenType +
                ", keyword=" + keyword +
                ", value=" + value +
                '"';
    }
}
