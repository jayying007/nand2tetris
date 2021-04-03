import java.io.File;

public class JackAnalyzer {
    public static void main(String[] args) throws Exception {
        String filepath = args[0];
        File file = new File(filepath);
        if(file.isDirectory()) {
            for(File child : file.listFiles()) {
                if(child.getName().endsWith(".jack")) {
                    System.out.println(child.getName());
                    JackTokenizer tokenizer = new JackTokenizer(child);
                    CompilationEngine engine = new CompilationEngine(tokenizer.getTokens(),
                            new File(file.getPath() + '/' + child.getName().substring(0, child.getName().length() - 5)+ "2.xml"));
                    engine.compileClass();
                }
            }
        } else {
            if(file.getName().endsWith(".jack")) {
                JackTokenizer tokenizer = new JackTokenizer(file);
                CompilationEngine engine = new CompilationEngine(tokenizer.getTokens(),
                        new File(file.getPath().substring(0, file.getPath().length() - 5) + "2.xml"));
                engine.compileClass();
            }
        }
    }
}
