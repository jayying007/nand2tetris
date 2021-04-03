import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Queue;

/**
 * 本代码分析器默认编写的代码格式是正确的
 */
public class CompilationEngine {
    private Queue<Token> tokens;
    private File outFile;
    private BufferedWriter bw;
    public CompilationEngine(Queue<Token> tokens, File outFile) throws IOException {
        this.tokens = tokens;
        this.outFile = outFile;
        this.bw = new BufferedWriter(new FileWriter(outFile));
    }

    /**
     * 'class' className '{' classVarDec* subroutineDec* '}'
     * @throws Exception
     */
    public void compileClass() throws IOException {
        bw.write("<class>\n");
        //class关键字
        bw.write("<keyword> " + tokens.poll().keyword().getValue() + " </keyword>\n");
        //类名
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        //左大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //类变量*或类方法*
        while (true) {
            if(tokens.peek().keyword() == Keyword.STATIC || tokens.peek().keyword() == Keyword.FIELD) {
                compileClassVarDec();
            } else if(tokens.peek().keyword() == Keyword.CONSTRUCTOR || tokens.peek().keyword() == Keyword.FUNCTION
                    || tokens.peek().keyword() == Keyword.METHOD) {
                compileSubroutine();
            } else {
                //右大括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
                break;
            }
        }
        bw.write("</class>");
        bw.close();
    }
    public void compileClassVarDec() throws IOException {
        bw.write("<classVarDec>\n");
        //static或field关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //type
        if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        } else {
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //varName
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        while (tokens.peek().symbol() == ',') {
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //;结束符
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</classVarDec>\n");
    }
    public void compileSubroutine() throws IOException {
        bw.write("<subroutineDec>\n");
        //constructor,function,method关键字
        bw.write("<keyword>" + tokens.poll().keyword.getValue() + "</keyword>\n");
        //void 或者 type类型
        if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        } else {
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //subroutineName
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        //左小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //参数列表
        compileParameterList();
        //右小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //subroutineBody
        bw.write("<subroutineBody>\n");
        //左大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //局部变量varDec*
        while (tokens.peek().keyword() == Keyword.VAR) {
            compileVarDec();
        }
        //语句statements
        compileStatements();
        //右大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</subroutineBody>\n");
        bw.write("</subroutineDec>\n");
    }
    public void compileParameterList() throws IOException {
        bw.write("<parameterList>\n");
        if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ')') {
            bw.write("</parameterList>\n");
            return;
        }
        //type
        if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        } else {
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //varName
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        // (',' type varName)*
        while (tokens.peek().symbol() == ',') {
            //逗号,
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //type
            if(tokens.peek().tokenType() == TokenType.KEYWORD) {
                bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
            } else {
                bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
            }
            //varName
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        bw.write("</parameterList>\n");
    }
    public void compileVarDec() throws IOException {
        bw.write("<varDec>\n");
        //var关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //type
        if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        } else {
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //varName
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        //(',' varName)*
        while (tokens.peek().symbol() == ',') {
            //逗号,
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //varName
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        }
        //结束符;
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</varDec>\n");
    }
    public void compileStatements() throws IOException {
        bw.write("<statements>\n");
        while (tokens.peek().tokenType != TokenType.SYMBOL) {
            switch (tokens.peek().keyword()) {
                case LET: compileLet();break;
                case IF: compileIf();break;
                case WHILE: compileWhile();break;
                case DO: compileDo();break;
                case RETURN: compileReturn();break;
            }
        }
        bw.write("</statements>\n");
    }
    public void compileLet() throws IOException {
        bw.write("<letStatement>\n");
        //let关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //varName
        bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
        //('[' expression ']')?
        if(tokens.peek().symbol() == '[') {
            //左中括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //expression
            compileExpression();
            //右中括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        }
        //等号=
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        compileExpression();
        //分号;
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</letStatement>\n");
    }
    public void compileIf() throws IOException {
        bw.write("<ifStatement>\n");
        //if关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //左小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //expression
        compileExpression();
        //右小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //左大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //语句statements
        compileStatements();
        //右大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //('else' '{' statements '}')?
        if(tokens.peek().keyword() == Keyword.ELSE) {
            //else关键字
            bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
            //左大括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //语句statements
            compileStatements();
            //右大括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        }
        bw.write("</ifStatement>\n");
    }
    public void compileWhile() throws IOException {
        bw.write("<whileStatement>\n");
        //while关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //左小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //expression
        compileExpression();
        //右小括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //左大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        //语句statements
        compileStatements();
        //右大括号
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</whileStatement>\n");
    }
    public void compileDo() throws IOException {
        bw.write("<doStatement>\n");
        //do关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //subroutineCall
        Token pre = tokens.poll();
        //subroutineName '(' expressionList ')'
        if(tokens.peek().symbol() == '(') {
            //subroutineName
            bw.write("<identifier>" + pre.identifier() + "</identifier>\n");
            //左小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            compileExpressionList();
            //右小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        } else { //(className | varName) '.' subroutineName '(' expressionList ')'
            //className | varName
            bw.write("<identifier>" + pre.value + "</identifier>\n");
            //点号.
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //subroutineName
            bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
            //左小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            compileExpressionList();
            //右小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        }
        //分号;
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</doStatement>\n");
    }
    public void compileReturn() throws IOException {
        bw.write("<returnStatement>\n");
        //return关键字
        bw.write("<keyword>" + tokens.poll().keyword().getValue() + "</keyword>\n");
        //expression?
        if(!(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ';')) {
            compileExpression();
        }
        //分号;
        bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        bw.write("</returnStatement>\n");
    }
    public void compileExpression() throws IOException {
        bw.write("<expression>\n");
        //term
        compileTerm();
        //(op term)*
        while(tokens.peek().tokenType() == TokenType.SYMBOL && isOp(tokens.peek().symbol())) {
            //op
            if(tokens.peek().symbol() == '<') {
                bw.write("<symbol> &lt; </symbol>\n");
                tokens.poll();
            } else if(tokens.peek().symbol() == '>') {
                bw.write("<symbol> &gt; </symbol>\n");
                tokens.poll();
            } else if(tokens.peek().symbol() == '&') {
                bw.write("<symbol> &amp; </symbol>\n");
                tokens.poll();
            } else {
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            }
            //term
            compileTerm();
        }
        bw.write("</expression>\n");
    }
    /*
        integerConstant | stringConstant | keywordConstant |
        varName | varName'['expression']' | subroutineCall |
        '('expression')' | unaryOp term
     */
    public void compileTerm() throws IOException {
        bw.write("<term>\n");
        if(tokens.peek().tokenType() == TokenType.INT_CONST) {
            bw.write("<integerConstant> " + tokens.poll().intVal() + " </integerConstant>\n");
        } else if(tokens.peek().tokenType() == TokenType.STRING_CONST) {
            bw.write("<stringConstant> " + tokens.poll().stringVal() + " </stringConstant>\n");
        } else if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            bw.write("<keyword> " + tokens.poll().identifier() + " </keyword>\n");
        } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '(') {
            //左小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            //expression
            compileExpression();
            //右小括号
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
        } else if(tokens.peek().tokenType() == TokenType.SYMBOL && isUnaryOp(tokens.peek().symbol())) {
            //unaryOp
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            compileTerm();
        } else {
            Token pre = tokens.poll();
            if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '[') {
                //varName
                bw.write("<identifier>" + pre.identifier() + "</identifier>\n");
                //左中括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
                compileExpression();
                //右中括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '(') {
                //subroutineName
                bw.write("<identifier>" + pre.identifier() + "</identifier>\n");
                //左小括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
                compileExpressionList();
                //小括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '.') {
                //className | varName
                bw.write("<identifier>" + pre.identifier() + "</identifier>\n");
                //点号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
                //subroutineName
                bw.write("<identifier>" + tokens.poll().identifier() + "</identifier>\n");
                //左小括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
                compileExpressionList();
                //小括号
                bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            } else {
                //varName
                bw.write("<identifier> " + pre.identifier() + " </identifier>\n");
            }
        }
        bw.write("</term>\n");
    }
    public void compileExpressionList() throws IOException {
        bw.write("<expressionList>\n");
        if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ')') {
            bw.write("</expressionList>\n");
            return;
        }
        compileExpression();
        while (tokens.peek().symbol() == ',') {
            //逗号,
            bw.write("<symbol> " + tokens.poll().symbol() + " </symbol>\n");
            compileExpression();
        }
        bw.write("</expressionList>\n");
    }

    public boolean isOp(Character s) {
        String tar = "+-*/&|<>=";
        return tar.contains(s + "");
    }
    public boolean isUnaryOp(Character s) {
        String tar = "-~";
        return tar.contains(s + "");
    }
}