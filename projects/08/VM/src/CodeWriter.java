import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author zhuangjy
 * @since 2021-3-26
 */
public class CodeWriter {
    private String filename;
    private FileWriter writer;
    private int index = 0; //用于设置条件跳转的标记
    private int callIndex = 0;

    public CodeWriter(File file) throws IOException {
        this.writer = new FileWriter(file);
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
        String s = "";
        if("temp".equals(seg)) {
            s = s + "@5\nD=A\n";
        } else if("pointer".equals(seg)) {
            s = s + "@3\nD=A\n";
        } else if("static".equals(seg)) {
            s = s + "@SP\n"
                    + "AM=M-1\n"
                    + "D=M\n"
                    + "@" + filename + "." + index + "\n"
                    + "M=D\n";
            return s;
        } else {
            s = s + "@" + seg + "\nD=M\n";
        }
        s = s + "@" + index + "\n"
                + "D=D+A\n"
                + "@R13\n"
                + "M=D\n"
                + "@SP\n"
                + "AM=M-1\n"
                + "D=M\n"
                + "@R13\n"
                + "A=M\n"
                + "M=D\n";
        return s;
    }

    private String pushTemplate(String seg, int index) {
        String s = "";
        if("temp".equals(seg)) {
            s = s + "@5\nD=A\n";
        } else if("pointer".equals(seg)) {
            s = s + "@3\nD=A\n";
        } else if("static".equals(seg)) {
            s = s + "@" + filename + "." + index + "\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n";
            return s;
        } else {
            s = s + "@" + seg + "\nD=M\n";
        }
        s = s + "@" + index + "\n"
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

    public void writeInit() throws IOException {
        writer.write("@256\nD=A\n@SP\nM=D\n");
        writeCall("Sys.init", 0);
    }
    public void writeLabel(String label) throws IOException {
        writer.write("(" + label + ")\n");
    }
    public void writeGoto(String label) throws IOException {
        writer.write("@" + label + "\n");
        writer.write("0;JMP\n");
    }
    //如果栈顶元素非0，执行跳转
    public void writeIf(String label) throws IOException {
        String s = "@SP\n"
                + "AM=M-1\n"
                + "D=M\n"
                + "@" + label + "\n"
                + "D;JNE\n";
        writer.write(s);
    }
    public void writeCall(String functionName, int numArgs) throws IOException {
        String pushD = "@SP\nA=M\nM=D\n@SP\nM=M+1\n"; //D寄存器的值入栈
        String s = "";
        //存地址
        s = s + "@return_address" + callIndex + "\n"
                + "D=A\n"
                + pushD;
        //保存LCL，ARG，THIS，THAT
        String[] names = new String[]{"LCL", "ARG", "THIS", "THAT"};
        for(String name : names) {
            s = s + "@" + name + "\n"
                    + "D=M\n"
                    + pushD;
        }
        //重置ARG
        s = s + "@SP\n"
                + "D=M\n"
                + "@" + (numArgs + 5) + "\n"
                + "D=D-A\n"
                + "@ARG\n"
                + "M=D\n";
        //重置LCL
        s = s + "@SP\n"
                + "D=M\n"
                + "@LCL\n"
                + "M=D\n";
        //跳转到函数执行
        s = s + "@" + functionName + "\n"
                + "0;JMP\n";
        s = s + "(return_address" + callIndex + ")\n";
        callIndex++;
        writer.write(s);
    }
    public void writeReturn() throws IOException {
        String s = "";
        //将返回地址存到R14的位置, 注意！！！ R13已经在writePushPop函数中使用过
        s = s + "@LCL\n"
                + "D=M\n"
                + "@5\n"
                + "A=D-A\n"
                + "D=M\n"
                + "@R14\n"
                + "M=D\n";
        writer.write(s);
        //设置函数返回值
        writePushPop(CommandType.POP, "argument", 0);
        //调整SP位置
        s = "@ARG\n"
                + "D=M+1\n"
                + "@SP\n"
                + "M=D\n";
        //恢复LCL，ARG，THIS，THAT
        String[] names = new String[]{"", "THAT", "THIS", "ARG", "LCL"};
        for(int i = 1; i < names.length; i++) {
            s = s + "@LCL\n"
                    + "D=M\n"
                    + "@" + i + "\n"
                    + "A=D-A\n"
                    + "D=M\n"
                    + "@" + names[i] + "\n"
                    + "M=D\n";
        }
        s = s + "@R14\n"
                + "A=M\n"
                + "0;JMP\n";
        writer.write(s);
    }
    public void writeFunction(String functionName, int numLocals) throws IOException {
        writer.write("(" + functionName + ")\n");
        //填充LCL的空间,使SP指针下移到“空栈”
        for(int i = 0; i < numLocals; i++) {
            writePushPop(CommandType.PUSH, "constant", 0);
        }
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }
}