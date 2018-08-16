package MyProject.jniexample;

public class JniInterface {

    static {
        System.loadLibrary( "JniInterface" );
    }

    public static native void native_func();
}
