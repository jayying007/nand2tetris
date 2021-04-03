import java.io.*;
import java.util.LinkedList;
import java.util.Queue;

/**
 *
 */
public class JackTokenizer {
    private Queue<Token> tokens = new LinkedList<>();
    private Queue<String> lines = new LinkedList<>(); //去除注释后的代码
    private boolean isComment = false;

    public JackTokenizer(File file) throws IOException {
        getNonCommentCode(file);
        getNode();

        //generateXml(file.getPath().substring(0, file.getPath().length() - 5) + "T2.xml");
    }

    /**
     * 读取文件，去除其中的注释和空行
     * @param file 文件
     * @throws IOException
     */
    public void getNonCommentCode(File file) throws IOException {
        BufferedReader bf = new BufferedReader(new FileReader(file));
        String line;
        while ((line = bf.readLine()) != null) {
            //若先前已有/*， 则判断是否有*/
            if(isComment) {
                // 此处不考虑 “*/ .... //” 这种情况
                if(line.contains("*/")) {
                    isComment = false;
                    line = line.substring(line.indexOf("*/") + 2).trim();
                    if(line.length() > 0) lines.add(line);
                }
            } else {
                /*
                   这里为了代码简单，就没有考虑那么极端的情况。
                   比如存在 /** //   这种注释,
                 */
                // 还有 “// /*  */” 这种
                if(line.contains("/*")) {
                    if(line.contains("*/")) {
                        line = line.substring(0, line.indexOf("/*")).trim();
                        if(line.length() > 0) lines.add(line);
                    } else {
                        isComment = true;
                        line = line.substring(0, line.indexOf("/*")).trim();
                        if(line.length() > 0) lines.add(line);
                    }
                } else if(line.contains("//")) {
                    line = line.substring(0, line.indexOf("//")).trim();
                    if(line.length() > 0) lines.add(line);
                } else {
                    line = line.trim();
                    if(line.length() > 0) lines.add(line);
                }
            }
        }
    }

    /**
     * 将lines的内容转化为token
     */
    public void getNode() {
        while (!lines.isEmpty()) {
            String line = lines.poll();
            int pos = 0;
            while (pos < line.length()) {
                if(isSymbol(line.charAt(pos))) {
                    tokens.add(new Token(TokenType.SYMBOL, null, line.charAt(pos)));
                    pos++;
                } else if(line.charAt(pos) == ' ') {
                    pos++;
                } else if(line.charAt(pos) == '"') {
                    pos++;
                    StringBuilder sb = new StringBuilder();
                    while (line.charAt(pos) != '"') {
                        sb.append(line.charAt(pos));
                        pos++;
                    }
                    tokens.add(new Token(TokenType.STRING_CONST, null, sb.toString()));
                    pos++;
                } else if(line.charAt(pos) >= '0' && line.charAt(pos) <= '9') {
                    int sum = 0;
                    while (line.charAt(pos) >= '0' && line.charAt(pos) <= '9') {
                        sum = sum * 10 + line.charAt(pos) - '0';
                        pos++;
                    }
                    tokens.add(new Token(TokenType.INT_CONST, null, sum));
                } else {
                    StringBuilder sb = new StringBuilder();
                    while (line.charAt(pos) != ' ' && !isSymbol(line.charAt(pos))) {
                        sb.append(line.charAt(pos));
                        pos++;
                    }
                    String s = sb.toString();
                    if(isKeyword(s) != null) {
                        tokens.add(new Token(TokenType.KEYWORD, isKeyword(s), s));
                    } else {
                        tokens.add(new Token(TokenType.IDENTIFIER, null, s));
                    }
                }
            }
        }
    }
    public boolean isSymbol(char c) {
        String s = "{}()[].,;+-*/&|<>=~";
        return s.contains(c + "");
    }
    public Keyword isKeyword(String s) {
        switch (s) {
            case "class": return Keyword.CLASS;
            case "method": return Keyword.METHOD;
            case "int": return Keyword.INT;
            case "function": return Keyword.FUNCTION;
            case "boolean": return Keyword.BOOLEAN;
            case "constructor": return Keyword.CONSTRUCTOR;
            case "char": return Keyword.CHAR;
            case "void": return Keyword.VOID;
            case "var": return Keyword.VAR;
            case "static": return Keyword.STATIC;
            case "field": return Keyword.FIELD;
            case "let": return Keyword.LET;
            case "do": return Keyword.DO;
            case "if": return Keyword.IF;
            case "else": return Keyword.ELSE;
            case "while": return Keyword.WHILE;
            case "return": return Keyword.RETURN;
            case "true": return Keyword.TRUE;
            case "false": return Keyword.FALSE;
            case "null": return Keyword.NULL;
            case "this": return Keyword.THIS;
            default: return null;
        }
    }

    public void generateXml(String outPath) throws IOException {
        File file = new File(outPath);
        BufferedWriter bw = new BufferedWriter(new FileWriter(file));
        bw.write("<tokens>\n");
        while (!tokens.isEmpty()) {
            Token node = tokens.poll();
            switch (node.tokenType) {
                case SYMBOL:
                    if((char)node.value == '<') {
                        bw.write("<symbol> &lt; </symbol>\n");
                    } else if((char)node.value == '>') {
                        bw.write("<symbol> &gt; </symbol>\n");
                    } else if((char)node.value == '&') {
                        bw.write("<symbol> &amp; </symbol>\n");
                    } else {
                        bw.write("<symbol> " + node.value + " </symbol>\n");
                    }
                    break;
                case IDENTIFIER: bw.write("<identifier> " + node.value + " </identifier>\n");break;
                case KEYWORD: bw.write("<keyword> " + node.value + " </keyword>\n");break;
                case INT_CONST: bw.write("<integerConstant> " + node.value + " </integerConstant>\n");break;
                case STRING_CONST: bw.write("<stringConstant> " + node.value + " </stringConstant>\n");
            }
        }
        bw.write("</tokens>");
        bw.close();
    }

    public Queue<Token> getTokens() {
        return this.tokens;
    }
}