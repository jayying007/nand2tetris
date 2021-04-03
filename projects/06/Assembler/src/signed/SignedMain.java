package signed;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class SignedMain {
    public static void main(String[] args) throws IOException {
        String filePath = args[0];
        File file = new File(filePath.substring(0, filePath.length() - 4) + ".hack");
        FileWriter writer = new FileWriter(file);
        //第一遍
        Parser parser = new Parser(new File(filePath));
        SymbolTable symbolTable = new SymbolTable();
        int pc = 0;
        while (parser.hasMoreCommands()) {
            if(parser.commandType() == Parser.CommandType.A_COMMAND) {
                pc++;
            } else if(parser.commandType() == Parser.CommandType.C_COMMAND) {
                pc++;
            } else {
                symbolTable.addEntry(parser.symbol(), pc);
            }
        }
        //第二遍
        parser = new Parser(new File(filePath));
        Code code = new Code();
        int variableAddress = 16; //为变量分配的内存地址,书中规定从16开始
        while (parser.hasMoreCommands()) {
            if(parser.commandType() == Parser.CommandType.A_COMMAND) {
                if(isNumber(parser.symbol())) {
                    writer.write(strToBit(parser.symbol()));
                    writer.write('\n');
                } else if(symbolTable.contains(parser.symbol())) {
                    writer.write(strToBit(symbolTable.getAddress(parser.symbol()) + ""));
                    writer.write('\n');
                } else {
                    symbolTable.addEntry(parser.symbol(), variableAddress);
                    writer.write(strToBit(variableAddress + ""));
                    writer.write('\n');
                    variableAddress++;
                }
            } else if(parser.commandType() == Parser.CommandType.C_COMMAND) {
                String s = "111" + code.comp(parser.comp()) + code.dest(parser.dest()) + code.jump(parser.jump());
                writer.write(s);
                writer.write('\n');
            }
        }
        writer.close();
    }

    public static boolean isNumber(String str) {
        for(int i = 0; i < str.length(); i++) {
            if(str.charAt(i) < '0' || str.charAt(i) > '9') return false;
        }
        return true;
    }
    public static String strToBit(String str) {
        StringBuilder res = new StringBuilder(Integer.toBinaryString(Integer.parseInt(str)));
        while (res.length() < 16) {
            res.insert(0, "0");
        }
        return res.toString();
    }
}