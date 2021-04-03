import java.io.File;
import java.io.IOException;

/**
 * @author zhuangjy
 * @since 2021/4/2
 */
public class JackCompiler {
    public static void main(String[] args) throws IOException {
        String filepath = args[0];
        File file = new File(filepath);
        if(file.isDirectory()) {
            for(File child : file.listFiles()) {
                compile(child);
            }
        } else {
            compile(file);
        }
    }

    public static void compile(File file) throws IOException {
        if(file.getName().endsWith(".jack")) {
            JackTokenizer tokenizer = new JackTokenizer(file);
            VMWriter writer = new VMWriter(new File(file.getPath().substring(0, file.getPath().length() - 5)+ ".vm"));
            CompilationEngine engine = new CompilationEngine(tokenizer.getTokens(), writer);
            engine.compileClass();
        }
    }
}
