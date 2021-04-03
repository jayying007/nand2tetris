import java.util.HashMap;
import java.util.Map;

/**
 * @author zhuangjy
 * @since 2021/4/2
 */
public class SymbolTable {
    enum Identifier {
        STATIC, FIELD, ARG, VAR, NONE
    }
    class Table {
        private String type;
        private Identifier identifier;
        private int index;
        public Table(String type, Identifier identifier, int index) {
            this.type = type;
            this.identifier = identifier;
            this.index = index;
        }
    }
    Map<String, Table> classMap = new HashMap<>();
    int[] classIndex = new int[2]; //static, field
    Map<String, Table> methodMap = new HashMap<>();
    int[] methodIndex = new int[2]; //arg, var,  arg

    public SymbolTable() {

    }

    /**
     * 将子程序的符号表重置
     */
    public void startSubroutine() {
        methodMap = new HashMap<>();
        methodIndex = new int[2];
    }

    public void define(String name, String type, Identifier identifier) {
        if(identifier == Identifier.STATIC) {
            classMap.put(name, new Table(type, Identifier.STATIC, classIndex[0]));
            classIndex[0]++;
        } else if(identifier == Identifier.FIELD) {
            classMap.put(name, new Table(type, Identifier.FIELD, classIndex[1]));
            classIndex[1]++;
        } else if(identifier == Identifier.ARG) {
            methodMap.put(name, new Table(type, Identifier.ARG, methodIndex[0]));
            methodIndex[0]++;
        } else if(identifier == Identifier.VAR) {
            methodMap.put(name, new Table(type, Identifier.VAR, methodIndex[1]));
            methodIndex[1]++;
        }
    }
    //返回已经定义在当前作用域内的变量的数量
    public int varCount(Identifier identifier) {
        switch (identifier) {
            case STATIC: return classIndex[0];
            case FIELD: return classIndex[1];
            case ARG: return methodIndex[0];
            case VAR: return methodIndex[1];
        }
        return -1;
    }
    /**
     * @param name 标识符名称
     * @return 标识符的种类，若找不到，返回NONE
     */
    public Identifier kindOf(String name) {
        if(methodMap.containsKey(name)) {
            return methodMap.get(name).identifier;
        }
        if(classMap.containsKey(name)) {
            return classMap.get(name).identifier;
        }
        return Identifier.NONE;
    }
    public String typeOf(String name) {
        if(methodMap.containsKey(name)) {
            return methodMap.get(name).type;
        } else {
            return classMap.get(name).type;
        }
    }
    public int indexOf(String name) {
        if(methodMap.containsKey(name)) {
            return methodMap.get(name).index;
        } else {
            return classMap.get(name).index;
        }
    }
}
