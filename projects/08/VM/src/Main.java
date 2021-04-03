import java.io.File;
import java.io.IOException;

/**
 * @author ZhuangJieYing
 * @since 2021/3/27
 */
public class Main {
    public static void main(String[] args) throws IOException {
        String filePath = args[0];
        Parser parser = new Parser(new File(filePath));
        CodeWriter codeWriter = new CodeWriter(new File(parser.getOutPath()));
        //先添加引导代码
        codeWriter.writeInit();
        while (parser.hasMoreCommands()) {
            codeWriter.setFilename(parser.getCurrentFileName());
            switch (parser.commandType()) {
                case ARITHMETIC:
                    codeWriter.writeArithmetic(parser.arg1());break;
                case PUSH:
                case POP:
                    codeWriter.writePushPop(parser.commandType(), parser.arg1(), parser.arg2());break;
                case LABEL:
                    codeWriter.writeLabel(parser.arg1());break;
                case IF:
                    codeWriter.writeIf(parser.arg1());break;
                case GOTO:
                    codeWriter.writeGoto(parser.arg1());break;
                case FUNCTION:
                    codeWriter.writeFunction(parser.arg1(), parser.arg2());break;
                case CALL:
                    codeWriter.writeCall(parser.arg1(), parser.arg2());break;
                case RETURN:
                    codeWriter.writeReturn();break;
            }
        }
        codeWriter.close();
    }
}
