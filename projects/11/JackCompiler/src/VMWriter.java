import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author Administrator
 * @since 2021/4/2
 */
public class VMWriter {
    private File outFile;
    private BufferedWriter bw;
    public VMWriter(File outFile) throws IOException {
        this.outFile = outFile;
        this.bw = new BufferedWriter(new FileWriter(outFile));
    }

    public VMWriter() {

    }
    public void writePush(Segment segment, int index) throws IOException {
        bw.write(String.format("push %s %d\n", segment.value, index));
    }
    public void writePop(Segment segment, int index) throws IOException {
        bw.write(String.format("pop %s %d\n", segment.value, index));
    }
    public void writeArithmetic(Command command) throws IOException {
        bw.write(String.format("%s\n", command.value));
    }
    public void writeLabel(String label) throws IOException {
        bw.write(String.format("label %s\n", label));
    }
    public void writeGoto(String label) throws IOException {
        bw.write(String.format("goto %s\n", label));
    }
    public void writeIf(String label) throws IOException {
        bw.write(String.format("if-goto %s\n", label));
    }
    public void writeCall(String name, int nArgs) throws IOException {
        bw.write(String.format("call %s %d\n", name, nArgs));
    }
    public void writeFunction(String name, int nLocals) throws IOException {
        bw.write(String.format("function %s %d\n", name, nLocals));
    }
    public void writeReturn() throws IOException {
        bw.write("return\n");
    }
    public void close() throws IOException {
        bw.close();
    }

    enum Segment {
        CONST("constant"),
        ARG("argument"),
        LOCAL("local"),
        STATIC("static"),
        THIS("this"),
        THAT("that"),
        POINTER("pointer"),
        TEMP("temp");

        private String value;
        Segment(String value) {
            this.value = value;
        }
    }
    enum Command {
        ADD("add"),
        SUB("sub"),
        NEG("neg"),
        EQ("eq"),
        GT("gt"),
        LT("lt"),
        AND("and"),
        OR("or"),
        NOT("not");

        private String value;
        Command(String value) {
            this.value = value;
        }
    }
}
