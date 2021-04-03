import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Queue;

/**
 * @author zhuangjy
 * @since 2021/4/2
 */
public class CompilationEngine {
    private Queue<Token> tokens;
    private VMWriter writer;
    private SymbolTable symbolTable;
    public CompilationEngine(Queue<Token> tokens, VMWriter writer) throws IOException {
        this.tokens = tokens;
        this.writer = writer;
        this.symbolTable = new SymbolTable();
    }

    private String className;
    private int ifIndex = 0;
    private int whileIndex = 0;
    private boolean isMethod = false;
    private Map<String, Integer> expressionListMap = new HashMap<>();

    /**
     * 'class' className '{' classVarDec* subroutineDec* '}'
     * @throws Exception
     */
    public void compileClass() throws IOException {
        //class关键字
        tokens.poll();
        //类名
        className = tokens.poll().identifier();
        //左大括号
        tokens.poll();
        //类变量*或类方法*
        while (true) {
            if(tokens.peek().keyword() == Keyword.STATIC || tokens.peek().keyword() == Keyword.FIELD) {
                compileClassVarDec();
            } else if(tokens.peek().keyword() == Keyword.CONSTRUCTOR || tokens.peek().keyword() == Keyword.FUNCTION
                    || tokens.peek().keyword() == Keyword.METHOD) {
                symbolTable.startSubroutine();
                //新的函数，label可以重置
                ifIndex = 0;
                whileIndex = 0;
                compileSubroutine();
            } else {
                //右大括号
                tokens.poll();
                break;
            }
        }
        writer.close();
    }
    public void compileClassVarDec() {
        //static或field关键字
        Token token1 = tokens.poll();
        //type
        Token token2 = tokens.poll();
        //varName
        Token token3 = tokens.poll();

        if(token1.keyword == Keyword.STATIC) {
            if(token2.tokenType() == TokenType.KEYWORD) {
                symbolTable.define(token3.identifier(), token2.keyword().getValue(), SymbolTable.Identifier.STATIC);
                while (tokens.peek().symbol() == ',') {
                    tokens.poll().symbol();
                    symbolTable.define(tokens.poll().identifier(), token2.keyword().getValue(), SymbolTable.Identifier.STATIC);
                }
            } else {
                symbolTable.define(token3.identifier(), token2.identifier(), SymbolTable.Identifier.STATIC);
                while (tokens.peek().symbol() == ',') {
                    tokens.poll().symbol();
                    symbolTable.define(tokens.poll().identifier(), token2.identifier(), SymbolTable.Identifier.STATIC);
                }
            }
        } else {
            if(token2.tokenType() == TokenType.KEYWORD) {
                symbolTable.define(token3.identifier(), token2.keyword().getValue(), SymbolTable.Identifier.FIELD);
                while (tokens.peek().symbol() == ',') {
                    tokens.poll().symbol();
                    symbolTable.define(tokens.poll().identifier(), token2.keyword().getValue(), SymbolTable.Identifier.FIELD);
                }
            } else {
                symbolTable.define(token3.identifier(), token2.identifier(), SymbolTable.Identifier.FIELD);
                while (tokens.peek().symbol() == ',') {
                    tokens.poll().symbol();
                    symbolTable.define(tokens.poll().identifier(), token2.identifier(), SymbolTable.Identifier.FIELD);
                }
            }
        }
        //;结束符
        tokens.poll();
    }
    public void compileSubroutine() throws IOException {
        //constructor,function,method关键字
        String key = tokens.poll().keyword().getValue();
        //void 或者 type类型
        tokens.poll();
        //subroutineName
        String subroutineName = tokens.poll().identifier();
        //左小括号
        tokens.poll();
        //参数列表
        compileParameterList();
        //右小括号
        tokens.poll();
        //subroutineBody
        //左大括号
        tokens.poll();
        //局部变量varDec*
        while (tokens.peek().keyword() == Keyword.VAR) {
            compileVarDec();
        }
        writer.writeFunction(className + "." + subroutineName, symbolTable.varCount(SymbolTable.Identifier.VAR));
        if(key.equals("constructor")) {
            writer.writePush(VMWriter.Segment.CONST, symbolTable.varCount(SymbolTable.Identifier.FIELD));
            writer.writeCall("Memory.alloc", 1);
            writer.writePop(VMWriter.Segment.POINTER, 0);
        } else if(key.equals("method")) {
            writer.writePush(VMWriter.Segment.ARG, 0);
            writer.writePop(VMWriter.Segment.POINTER, 0);
            isMethod = true;
        }
        //语句statements
        compileStatements();
        //右大括号
        tokens.poll();
        isMethod = false;
    }
    public void compileParameterList() {
        if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ')') {
            return;
        }
        //type
        Token token1 = tokens.poll();
        //varName
        Token token2 = tokens.poll();
        if(token1.tokenType() == TokenType.KEYWORD) {
            symbolTable.define(token2.identifier(), token1.keyword.getValue(), SymbolTable.Identifier.ARG);
        } else {
            symbolTable.define(token2.identifier(), token1.identifier(), SymbolTable.Identifier.ARG);
        }
        // (',' type varName)*
        while (tokens.peek().symbol() == ',') {
            //逗号,
            tokens.poll();
            //type
            Token token3 = tokens.poll();
            //varName
            Token token4 = tokens.poll();
            if(token3.tokenType() == TokenType.KEYWORD) {
                symbolTable.define(token4.identifier(), token3.keyword.getValue(), SymbolTable.Identifier.ARG);
            } else {
                symbolTable.define(token4.identifier(), token3.identifier(), SymbolTable.Identifier.ARG);
            }
        }
    }
    public void compileVarDec() {
        //var关键字
        tokens.poll();
        //type
        Token token1 = tokens.poll();
        //varName
        Token token2 = tokens.poll();
        if(token1.tokenType() == TokenType.KEYWORD) {
            symbolTable.define(token2.identifier(), token1.keyword.getValue(), SymbolTable.Identifier.VAR);
        } else {
            symbolTable.define(token2.identifier(), token1.identifier(), SymbolTable.Identifier.VAR);
        }
        //(',' varName)*
        while (tokens.peek().symbol() == ',') {
            //逗号,
            tokens.poll();
            //varName
            if(token1.tokenType() == TokenType.KEYWORD) {
                symbolTable.define(tokens.poll().identifier(), token1.keyword.getValue(), SymbolTable.Identifier.VAR);
            } else {
                symbolTable.define(tokens.poll().identifier(), token1.identifier(), SymbolTable.Identifier.VAR);
            }
        }
        //结束符;
        tokens.poll();
    }
    public void compileStatements() throws IOException {
        while (tokens.peek().tokenType != TokenType.SYMBOL) {
            switch (tokens.peek().keyword()) {
                case LET: compileLet();break;
                case IF: compileIf();break;
                case WHILE: compileWhile();break;
                case DO: compileDo();break;
                case RETURN: compileReturn();break;
            }
        }
    }
    public void compileLet() throws IOException {
        //let关键字
        tokens.poll();
        //varName
        String varName = tokens.poll().identifier();
        //('[' expression ']')?
        if(tokens.peek().symbol() == '[') {
            //左中括号
            tokens.poll();
            //expression
            compileExpression();
            /*
                将varName[index]的地址存到that
             */
            switch (symbolTable.kindOf(varName)) {
                case FIELD:
                    writer.writePush(VMWriter.Segment.THIS, symbolTable.indexOf(varName));
                    writer.writeArithmetic(VMWriter.Command.ADD);
                    break;
                case STATIC:
                    writer.writePush(VMWriter.Segment.STATIC, symbolTable.indexOf(varName));
                    writer.writeArithmetic(VMWriter.Command.ADD);
                    break;
                case VAR:
                    writer.writePush(VMWriter.Segment.LOCAL, symbolTable.indexOf(varName));
                    writer.writeArithmetic(VMWriter.Command.ADD);
                    break;
                case ARG:
                    writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(varName));
                    writer.writeArithmetic(VMWriter.Command.ADD);
                    break;
            }
            //右中括号
            tokens.poll();
            //等号=
            tokens.poll();
            compileExpression();
            writer.writePop(VMWriter.Segment.TEMP, 0);
            writer.writePop(VMWriter.Segment.POINTER, 1);
            writer.writePush(VMWriter.Segment.TEMP, 0);
            writer.writePop(VMWriter.Segment.THAT, 0);
        } else {
            //等号=
            tokens.poll();
            compileExpression();
            switch (symbolTable.kindOf(varName)) {
                case FIELD:
                    writer.writePop(VMWriter.Segment.THIS, symbolTable.indexOf(varName));
                    break;
                case STATIC:
                    writer.writePop(VMWriter.Segment.STATIC, symbolTable.indexOf(varName));
                    break;
                case VAR:
                    writer.writePop(VMWriter.Segment.LOCAL, symbolTable.indexOf(varName));
                    break;
                case ARG:
                    writer.writePop(VMWriter.Segment.ARG, symbolTable.indexOf(varName));
                    break;
            }
        }
        //分号;
        tokens.poll();
    }
    public void compileIf() throws IOException {
        int index = ifIndex;
        ifIndex++;
        //if关键字
        tokens.poll();
        //左小括号
        tokens.poll();
        //expression
        compileExpression();
        writer.writeIf("IF_TRUE" + index);  //如果栈顶非0，跳转到Label
        writer.writeGoto("IF_FALSE" + index);
        //右小括号
        tokens.poll();
        //左大括号
        tokens.poll();
        //语句statements
        writer.writeLabel("IF_TRUE" + index);
        compileStatements();
        //右大括号
        tokens.poll();
        //('else' '{' statements '}')?
        if(tokens.peek().keyword() == Keyword.ELSE) {
            writer.writeGoto("IF_END" + index);
            writer.writeLabel("IF_FALSE" + index);
            //else关键字
            tokens.poll();
            //左大括号
            tokens.poll();
            //语句statements
            compileStatements();
            //右大括号
            tokens.poll();
            writer.writeLabel("IF_END" + index);
        } else {
            writer.writeLabel("IF_FALSE" + index);
        }

    }
    public void compileWhile() throws IOException {
        int index = whileIndex;
        whileIndex++;
        //while关键字
        tokens.poll();
        //左小括号
        tokens.poll();
        writer.writeLabel("WHILE_EXP" + index);
        //expression
        compileExpression();
        writer.writeArithmetic(VMWriter.Command.NOT);
        writer.writeIf("WHILE_END" + index);
        //右小括号
        tokens.poll();
        //左大括号
        tokens.poll();
        //语句statements
        compileStatements();
        //右大括号
        tokens.poll();
        writer.writeGoto("WHILE_EXP" + index);
        writer.writeLabel("WHILE_END" + index);
    }
    public void compileDo() throws IOException {
        //do关键字
        tokens.poll();
        //subroutineCall
        Token pre = tokens.poll();
        //subroutineName '(' expressionList ')'
        if(tokens.peek().symbol() == '(') { //需存this指针
            writer.writePush(VMWriter.Segment.POINTER, 0);
            //subroutineName
            String subroutineName = pre.identifier();
            //左小括号
            tokens.poll();
            compileExpressionList(subroutineName);
            //右小括号
            tokens.poll();
            writer.writeCall(className + "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0) + 1);
            expressionListMap.put(subroutineName, 0);
        } else { //(className | varName) '.' subroutineName '(' expressionList ')'
            if(symbolTable.kindOf(pre.identifier()) == SymbolTable.Identifier.NONE) { //为类名，说明调用construct或function
                //点号.
                tokens.poll();
                //subroutineName
                String subroutineName = tokens.poll().identifier();
                //左小括号
                tokens.poll();
                compileExpressionList(subroutineName);
                //右小括号
                tokens.poll();
                writer.writeCall(pre.identifier() + "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0));
                expressionListMap.put(subroutineName, 0);
            } else { //为对象名，说明调用method，需要传递对象this指针
                switch (symbolTable.kindOf(pre.identifier())) {
                    case STATIC:
                        writer.writePush(VMWriter.Segment.STATIC, symbolTable.indexOf(pre.identifier()));
                        break;
                    case FIELD:
                        writer.writePush(VMWriter.Segment.THIS, symbolTable.indexOf(pre.identifier()));
                        break;
                    case ARG:
                        writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(pre.identifier()));
                        break;
                    case VAR:
                        writer.writePush(VMWriter.Segment.LOCAL, symbolTable.indexOf(pre.identifier()));
                        break;
                }
                //点号.
                tokens.poll();
                //subroutineName
                String subroutineName = tokens.poll().identifier();
                //左小括号
                tokens.poll();
                compileExpressionList(subroutineName);
                //右小括号
                tokens.poll();
                writer.writeCall(symbolTable.typeOf(pre.identifier())+ "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0) + 1);
                expressionListMap.put(subroutineName, 0);
            }
        }
        //分号;
        tokens.poll();
        writer.writePop(VMWriter.Segment.TEMP, 0);
    }
    public void compileReturn() throws IOException {
        //return关键字
        tokens.poll();
        //expression?
        if(!(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ';')) {
            compileExpression();
        } else {
            writer.writePush(VMWriter.Segment.CONST, 0);
        }
        writer.writeReturn();
        //分号;
        tokens.poll();
    }
    public void compileExpression() throws IOException {
        //term
        compileTerm();
        //(op term)*
        while(tokens.peek().tokenType() == TokenType.SYMBOL && isOp(tokens.peek().symbol())) {
            //这里采用后缀表达式，所以要先加入term，再加入操作符，但需要先提取出op
            char op = tokens.poll().symbol();
            //term
            compileTerm();
            //op
            switch (op) {
                case '<':
                    writer.writeArithmetic(VMWriter.Command.LT);
                    break;
                case '>':
                    writer.writeArithmetic(VMWriter.Command.GT);
                    break;
                case '=':
                    writer.writeArithmetic(VMWriter.Command.EQ);
                    break;
                case '&':
                    writer.writeArithmetic(VMWriter.Command.AND);
                    break;
                case '|':
                    writer.writeArithmetic(VMWriter.Command.OR);
                    break;
                case '+':
                    writer.writeArithmetic(VMWriter.Command.ADD);
                    break;
                case '-':
                    writer.writeArithmetic(VMWriter.Command.SUB);
                    break;
                case '*':
                    writer.writeCall("Math.multiply", 2);
                    break;
                case '/':
                    writer.writeCall("Math.divide", 2);
                    break;
            }
        }
    }
    /*
        integerConstant | stringConstant | keywordConstant |
        varName | varName'['expression']' | subroutineCall |
        '('expression')' | unaryOp term
     */
    public void compileTerm() throws IOException {
        if(tokens.peek().tokenType() == TokenType.INT_CONST) {
            writer.writePush(VMWriter.Segment.CONST, tokens.poll().intVal());
        } else if(tokens.peek().tokenType() == TokenType.STRING_CONST) {
            String s = tokens.poll().stringVal();
            writer.writePush(VMWriter.Segment.CONST, s.length());
            writer.writeCall("String.new", 1);
            for(int i = 0; i < s.length(); i++) {
                writer.writePush(VMWriter.Segment.CONST, s.charAt(i));
                writer.writeCall("String.appendChar", 2);
            }
        } else if(tokens.peek().tokenType() == TokenType.KEYWORD) {
            switch (tokens.poll().identifier()) {
                case "true":
                    writer.writePush(VMWriter.Segment.CONST, 0);
                    writer.writeArithmetic(VMWriter.Command.NOT);
                    break;
                case "false":
                case "null":
                    writer.writePush(VMWriter.Segment.CONST, 0);
                    break;
                case "this":
                    writer.writePush(VMWriter.Segment.POINTER, 0);
                    break;
            }
        } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '(') {
            //左小括号
            tokens.poll();
            //expression
            compileExpression();
            //右小括号
            tokens.poll();
        } else if(tokens.peek().tokenType() == TokenType.SYMBOL && isUnaryOp(tokens.peek().symbol())) {
            //后缀表达式，先入值再入操作符
            char op = tokens.poll().symbol();
            //term
            compileTerm();
            //unaryOp
            switch (op) {
                case '-':
                    writer.writeArithmetic(VMWriter.Command.NEG);
                    break;
                case '~':
                    writer.writeArithmetic(VMWriter.Command.NOT);
                    break;
            }
        } else {
            Token pre = tokens.poll();
            if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '[') {
                //varName
                String varName = pre.identifier();
                //左中括号
                tokens.poll();
                compileExpression();
                //右中括号
                tokens.poll();
                switch (symbolTable.kindOf(varName)) {
                    case FIELD:
                        writer.writePush(VMWriter.Segment.THIS, symbolTable.indexOf(varName));
                        writer.writeArithmetic(VMWriter.Command.ADD);
                        writer.writePop(VMWriter.Segment.POINTER, 1);
                        break;
                    case STATIC:
                        writer.writePush(VMWriter.Segment.STATIC, symbolTable.indexOf(varName));
                        writer.writeArithmetic(VMWriter.Command.ADD);
                        writer.writePop(VMWriter.Segment.POINTER, 1);
                        break;
                    case VAR:
                        writer.writePush(VMWriter.Segment.LOCAL, symbolTable.indexOf(varName));
                        writer.writeArithmetic(VMWriter.Command.ADD);
                        writer.writePop(VMWriter.Segment.POINTER, 1);
                        break;
                    case ARG:
                        writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(varName));
                        writer.writeArithmetic(VMWriter.Command.ADD);
                        writer.writePop(VMWriter.Segment.POINTER, 1);
                        break;
                }
                writer.writePush(VMWriter.Segment.THAT, 0);
            } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '(') {
                //subroutineName '(' expressionList ')'
                if(tokens.peek().symbol() == '(') { //需存this指针
                    writer.writePush(VMWriter.Segment.POINTER, 0);
                    //subroutineName
                    String subroutineName = pre.identifier();
                    //左小括号
                    tokens.poll();
                    compileExpressionList(subroutineName);
                    //右小括号
                    tokens.poll();
                    writer.writeCall(className + "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0) + 1);
                    expressionListMap.put(subroutineName, 0);
                }
            } else if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == '.') {
                //(className | varName) '.' subroutineName '(' expressionList ')'
                if(symbolTable.kindOf(pre.identifier()) == SymbolTable.Identifier.NONE) { //为类名，说明调用construct或function
                    //点号.
                    tokens.poll();
                    //subroutineName
                    String subroutineName = tokens.poll().identifier();
                    //左小括号
                    tokens.poll();
                    compileExpressionList(subroutineName);
                    //右小括号
                    tokens.poll();
                    writer.writeCall(pre.identifier() + "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0));
                    expressionListMap.put(subroutineName, 0);
                } else { //为对象名，说明调用method，需要传递this指针
                    switch (symbolTable.kindOf(pre.identifier())) {
                        case STATIC:
                            writer.writePush(VMWriter.Segment.STATIC, symbolTable.indexOf(pre.identifier()));
                            break;
                        case FIELD:
                            writer.writePush(VMWriter.Segment.THIS, symbolTable.indexOf(pre.identifier()));
                            break;
                        case ARG:
                            writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(pre.identifier()));
                            break;
                        case VAR:
                            writer.writePush(VMWriter.Segment.LOCAL, symbolTable.indexOf(pre.identifier()));
                            break;
                    }
                    //点号.
                    tokens.poll();
                    //subroutineName
                    String subroutineName = tokens.poll().identifier();
                    //左小括号
                    tokens.poll();
                    compileExpressionList(subroutineName);
                    //右小括号
                    tokens.poll();
                    writer.writeCall(symbolTable.typeOf(pre.identifier())+ "." + subroutineName, expressionListMap.getOrDefault(subroutineName, 0) + 1);
                    expressionListMap.put(subroutineName, 0);
                }
            } else {
                //varName
                String varName = pre.identifier();
                switch (symbolTable.kindOf(varName)) {
                    case STATIC:
                        writer.writePush(VMWriter.Segment.STATIC, symbolTable.indexOf(varName));
                        break;
                    case FIELD:
                        writer.writePush(VMWriter.Segment.THIS, symbolTable.indexOf(varName));
                        break;
                    case ARG:
                        if(isMethod) {
                            writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(varName) + 1);
                        } else {
                            writer.writePush(VMWriter.Segment.ARG, symbolTable.indexOf(varName));
                        }
                        break;
                    case VAR:
                        writer.writePush(VMWriter.Segment.LOCAL, symbolTable.indexOf(varName));
                        break;
                }
            }
        }
    }
    public void compileExpressionList(String functionName) throws IOException {
        if(tokens.peek().tokenType() == TokenType.SYMBOL && tokens.peek().symbol() == ')') {
            return;
        }
        compileExpression();
        expressionListMap.put(functionName, expressionListMap.getOrDefault(functionName, 0) + 1);
        while (tokens.peek().symbol() == ',') {
            //逗号,
            tokens.poll();
            compileExpression();
            expressionListMap.put(functionName, expressionListMap.getOrDefault(functionName, 0) + 1);
        }
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