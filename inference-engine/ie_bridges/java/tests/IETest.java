import org.junit.Assert;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Ignore;
import org.junit.runner.Description;
import org.junit.Rule;
import org.junit.rules.TestWatcher;

<<<<<<< HEAD
import java.nio.file.Paths;

import org.intel.openvino.*;

@Ignore
public class IETest {
=======
import org.intel.openvino.*;

import java.nio.file.Paths;

public class IETest extends TestCase {
>>>>>>> [JAVA] Code style check added
    String modelXml;
    String modelBin;
    static String device;

    public IETest() {
        try {
            System.loadLibrary(IECore.NATIVE_LIBRARY_NAME);
        } catch (UnsatisfiedLinkError e) {
            System.err.println("Failed to load Inference Engine library\n" + e);
            System.exit(1);
        }
<<<<<<< HEAD
        modelXml = Paths.get(System.getenv("MODELS_PATH"), "models", "test_model", "test_model_fp32.xml").toString();
        modelBin = Paths.get(System.getenv("MODELS_PATH"), "models", "test_model", "test_model_fp32.bin").toString();
=======

        modelXml =
                Paths.get(
                                System.getenv("MODELS_PATH"),
                                "models",
                                "test_model",
                                "test_model_fp32.xml")
                        .toString();
        modelBin =
                Paths.get(
                                System.getenv("MODELS_PATH"),
                                "models",
                                "test_model",
                                "test_model_fp32.bin")
                        .toString();
        device = "CPU";
>>>>>>> [JAVA] Code style check added
    }

    @Rule
    public TestWatcher watchman = new TestWatcher() {
        @Override
        protected void succeeded(Description description) {
            System.out.println(description + " - OK");
        }

        @Override
        protected void failed(Throwable e, Description description) {
            System.out.println(description + " - FAILED");
        }
    };
}
