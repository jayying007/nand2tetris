import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class CodeWriter {
    private FileWriter writer;
    private int index = 0; //用于设置条件跳转的标记

    public CodeWriter(File file) throws IOException {
        writer = new FileWriter(file);
    }

    public void writeArithmetic(String command) throws IOException {
        String s = "";
        //D保存第二个数
        String s1 = "@SP\nAM=M-1\nD=M\n";
        //A为指向第一个数的指针
        String s2 = "@SP\nAM=M-1\n";
        //
        switch (command) {
            case "add":
                s = s1 + s2 + "M=M+D\n";
                break;
            case "sub":
                s = s1 + s2 + "M=M-D\n";
                break;
            case "eq":
                s = s1 + s2 + writeJudgeString("JEQ", index++);
                break;
            case "lt":
                s = s1 + s2 + writeJudgeString("JLT", index++);
                break;
            case "gt":
                s = s1 + s2 + writeJudgeString("JGT", index++);
                break;
            case "and":
                s = s1 + s2 + "M=D&M\n";
                break;
            case "neg":
                s = s1 + "M=-D\n";
                break;
            case "or":;
                s = s1 + s2 + "M=D|M\n";
                break;
            case "not":
                s = s1 + "M=!D\n";
        }
        s = s + "@SP\nM=M+1\n";

        writer.write(s);
    }

    public void writePushPop(CommandType commandType, String segment, int index) throws IOException {
        if("constant".equals(segment)) {
            if(commandType == CommandType.PUSH) {
                writer.write("@" + index + "\n");
                writer.write("D=A\n");
                writer.write("@SP\n");
                writer.write("A=M\n");
                writer.write("M=D\n");
                writer.write("@SP\n");
                writer.write("M=M+1\n");
            }
            return;
        }
        String s = "";
        String seg = segment;
        switch (segment) {
            case "local": seg = "LCL";break;
            case "argument": seg = "ARG";break;
            case "this": seg = "THIS";break;
            case "that": seg = "THAT";break;
        }
        if(commandType == CommandType.PUSH) {
            s = pushTemplate(seg, index);
        } else if(commandType == CommandType.POP) {
            s = popTemplate(seg, index);
        }
        writer.write(s);
    }

    public void close() throws IOException {
        writer.close();
    }

    public void write(String s) throws IOException {
        writer.write(s);
    }

    private String popTemplate(String seg, int index) {
        String s = "temp".equals(seg)? ("@R5\n") : ("@" + seg + "\n");
        s = s + "D=A\n"
                + "@" + index + "\n"
                + "D=D+A\n"
                + "@R13\n"
                + "M=D\n"
                + "@SP\n"
                + "A=M-1\n"
                + "D=M\n"
                + "@R13\n"
                + "M=D\n";
        return s;
    }

    private String pushTemplate(String seg, int index) {
        String s = "temp".equals(seg)? ("@R5\n") : ("@" + seg + "\n");
        s = s + "D=A\n"
                + "@" + index + "\n"
                + "A=D+A\n"
                + "D=M\n"
                + "@SP\n"
                + "A=M\n"
                + "M=D\n"
                + "@SP\n"
                + "M=M+1\n";
        return s;
    }

    private String writeJudgeString(String judge, int index) throws IOException {
        return "D=M-D" + "\n" +
                "@TRUE" + index + "\n" +
                "D;" + judge + "\n" +
                "@SP\n" +
                "A=M\n" +
                "M=0" + "\n" +
                "@CONTINUE" + index + "\n" +
                "0;JMP" + "\n" +
                "(TRUE" + index + ")\n" +
                "@SP\n" +
                "A=M\n" +
                "M=-1" + "\n" +
                "(CONTINUE" + index + ")\n";
    }
}
