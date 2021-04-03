package unsigned;

import java.io.*;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class Parser {
    private BufferedReader br = null;
    private String advance = null;

    public Parser(File file) {
        try {
            this.br = new BufferedReader(new FileReader(file));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    public boolean hasMoreCommands() throws IOException {
        advance = br.readLine();
        if(advance == null) return false;
        int x = advance.indexOf("//");
        if(x == 0) return hasMoreCommands();
        else if(x > 0) advance = advance.substring(0, x);
        advance = advance.trim();
        if(advance.length() == 0) return hasMoreCommands();

        return true;
    }
    /**
     * @return 返回指令的类型
     */
    public CommandType commandType() {
        if(advance.charAt(0) == '@') {
            return CommandType.A_COMMAND;
        } else if(advance.charAt(0) == '(') {
            return CommandType.L_COMMAND;
        } else {
            return CommandType.C_COMMAND;
        }
    }
    /**
     * 要求commandType为A_COMMAND或者L_COMMAND
     * @return 返回@Xxx或(Xxx)的当前命令的符号或十进制值
     */
    public String symbol() {
        if(advance.charAt(0) == '@') {
            return advance.substring(1);
        } else {
            return advance.substring(1, advance.length() - 1);
        }
    }
    /**
     * 要求commandType为C_COMMAND
     * @return 返回当前C-指令的dest助记符
     */
    public String dest() {
        if(advance.contains("=")) {
            return advance.split("=")[0];
        } else {
            return "";
        }
    }
    /**
     * 要求commandType为C_COMMAND
     * @return 返回当前C-指令的comp助记符
     */
    public String comp() {
        if(advance.contains("=")) {
            String tmp = advance.split("=")[1];
            if(tmp.contains(";")) {
                return tmp.split(";")[0];
            } else {
                return tmp;
            }
        } else {
            return advance.split(";")[0];
        }
    }
    /**
     * 要求commandType为C_COMMAND
     * @return 返回当前C-指令的jump助记符
     */
    public String jump() {
        if(advance.contains(";")) {
            return advance.split(";")[1];
        } else {
            return "";
        }
    }


    enum CommandType {
        A_COMMAND,
        C_COMMAND,
        L_COMMAND
    }
}