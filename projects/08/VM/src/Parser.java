import java.io.*;
import java.util.LinkedList;
import java.util.Queue;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class Parser {
    private Queue<String> lines = new LinkedList<>();
    private String currentLine;
    private String currentFileName;
    private String outPath;
    /**
     * 构造函数
     * 解析文件，若file为文件，则读取其内容，若file为目录，则读取其子文件内容(.vm后缀)
     * @param file 目标文件
     * @throws IOException
     */
    public Parser(File file) throws IOException {
        if(file.isDirectory()) {
            for(File childFile : file.listFiles()) {
                if(childFile.getName().endsWith(".vm")) {
                    appendFile(childFile);
                }
            }
            outPath = file.getPath() + File.separatorChar + file.getName() + ".asm";
        } else {
            appendFile(file);
            outPath = file.getPath().substring(0, file.getPath().length() - 3) + ".asm";
        }
    }
    /**
     * 逐行读取文件内容，将非注释和非空行的加入到lines中
     * @param file 读取的文件
     * @throws IOException
     */
    private void appendFile(File file) throws IOException {
        lines.add("filename:" + file.getName());
        BufferedReader br = new BufferedReader(new FileReader(file));
        String s;
        while ((s = br.readLine()) != null) {
            int x = s.indexOf("//");
            if(x >= 0) {
                s = s.substring(0, x).trim();
            }
            if(s.length() != 0) {
                lines.add(s);
            }
        }
    }
    /**
     * 若存在，则将其赋值到current上
     * @return 判断是否还有命令（非注释行和空行）
     */
    public boolean hasMoreCommands() {
        if(lines.isEmpty()) {
            return false;
        } else {
            currentLine = lines.poll();
            if(currentLine.startsWith("filename:")) {
                currentFileName = currentLine.substring(9);
                currentLine = lines.poll();
            }
            return true;
        }
    }
    /**
     * @return 下一行命令的类型
     */
    public CommandType commandType() {
        String[] words = currentLine.split(" ");
        switch (words[0]) {
            case "push":
                return CommandType.PUSH;
            case "pop":
                return CommandType.POP;
            case "label":
                return CommandType.LABEL;
            case "goto":
                return CommandType.GOTO;
            case "if-goto":
                return CommandType.IF;
            case "function":
                return CommandType.FUNCTION;
            case "call":
                return CommandType.CALL;
            case "return":
                return CommandType.RETURN;
            default:
                return CommandType.ARITHMETIC;
        }
    }
    /**
     * 获取命令的第一个参数，如果没有参数，则返回命令本身
     * @return 第一个参数
     */
    public String arg1() {
        String[] words = currentLine.split(" ");
        if(words.length == 1) {
            return words[0];
        } else {
            return words[1];
        }
    }
    /**
     * 获取命令的第二个参数
     * @return 若存在第二个参数，则其必须为数字
     */
    public int arg2() {
        String[] words = currentLine.split(" ");
        return Integer.parseInt(words[2]);
    }

    public String getOutPath() {
        return outPath;
    }
    public String getCurrentFileName() {
        return currentFileName;
    }
}