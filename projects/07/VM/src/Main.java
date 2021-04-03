import java.io.File;
import java.io.IOException;

/**
 * @author ZhuangJieYing
 * @date 2021/3/27
 */
public class Main {
    public static void main(String[] args) throws IOException {
        String filePath = args[0];
        File file = new File(filePath.substring(0, filePath.length() - 3) + ".asm");
        Parser parser = new Parser(new File(filePath));
        CodeWriter codeWriter = new CodeWriter(file);
        while (parser.hasMoreCommands()) {
            if(parser.commandType() == CommandType.ARITHMETIC) {
                codeWriter.writeArithmetic(parser.arg1());
            } else {
                codeWriter.writePushPop(parser.commandType(), parser.arg1(), parser.arg2());
            }
        }
        codeWriter.write("(END)\n@END\n0;JMP");
        codeWriter.close();
    }
}
