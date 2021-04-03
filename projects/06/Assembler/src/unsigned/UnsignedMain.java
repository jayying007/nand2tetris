package unsigned;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class UnsignedMain {
    public static void main(String[] args) throws IOException {
        String filePath = args[0];
        File file = new File(filePath.substring(0, filePath.length() - 4) + ".hack");
        FileWriter writer = new FileWriter(file);

        Parser parser = new Parser(new File(filePath));
        Code code = new Code();
        while (parser.hasMoreCommands()) {
            if(parser.commandType() == Parser.CommandType.A_COMMAND) {
                writer.write(strToBit(parser.symbol()));
            } else {
                String s = "111" + code.comp(parser.comp()) + code.dest(parser.dest()) + code.jump(parser.jump());
                writer.write(s);
            }
            writer.write('\n');
        }
        writer.close();
    }

    public static String strToBit(String str) {
        StringBuilder res = new StringBuilder(Integer.toBinaryString(Integer.parseInt(str)));
        while (res.length() < 16) {
            res.insert(0, "0");
        }
        return res.toString();
    }
}
