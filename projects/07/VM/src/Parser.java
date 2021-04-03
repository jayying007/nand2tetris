import java.io.*;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class Parser {
    private BufferedReader br = null;
    private String advance;

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

    public CommandType commandType() {
        String[] words = advance.split(" ");
        if(words.length == 1) {
            return CommandType.ARITHMETIC;
        } else if("push".equals(words[0])) {
            return CommandType.PUSH;
        } else if("POP".equals(words[0])) {
            return CommandType.POP;
        }
        return CommandType.UNKNOWN;
    }

    public String arg1() {
        String[] words = advance.split(" ");
        if(words.length == 1) {
            return words[0];
        } else {
            return words[1];
        }
    }

    public int arg2() {
        String[] words = advance.split(" ");
        return Integer.parseInt(words[2]);
    }
}