package it.unive;

import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.SortedMap;
import java.util.TreeMap;

import org.yaml.snakeyaml.Yaml;

import io.github.classgraph.ClassGraph;
import io.github.classgraph.ClassInfo;
import io.github.classgraph.ScanResult;

public class SubtypesScanner {

    static final String GROUP_PATH = "io/github/lisa-analyzer";
    static final List<String> ARTIFACTS = List.of("lisa-sdk", "lisa-analyses", "lisa-program", "lisa-imp");

    static final String BASE_URL = "https://repo1.maven.org/maven2/" + GROUP_PATH;

    public static void main(
            String[] args)
            throws Exception {
        if (args.length < 1) {
            System.err.println("Usage: java SubtypesScanner <version>");
            System.exit(1);
        }

        String version = args[0];

        Path tempDir = Files.createTempDirectory("jars");
        List<Path> jars = downloadJars(version, tempDir);

        Map<String, Object> result = scan(
                jars,
                "it.unive.lisa.analysis.AbstractDomain",
                "it.unive.lisa.analysis.value.ValueDomain",
                "it.unive.lisa.analysis.type.TypeDomain",
                "it.unive.lisa.analysis.heap.HeapDomain",
                "it.unive.lisa.interprocedural.callgraph.CallGraph",
                "it.unive.lisa.interprocedural.InterproceduralAnalysis",
                "it.unive.lisa.interprocedural.OpenCallPolicy",
                "it.unive.lisa.checks.syntactic.SyntacticCheck",
                "it.unive.lisa.checks.semantic.SemanticCheck",
                "it.unive.lisa.program.cfg.fixpoints.forward.ForwardCFGFixpoint",
                "it.unive.lisa.program.cfg.fixpoints.backward.BackwardCFGFixpoint",
                "it.unive.lisa.util.collections.workset.WorkingSet",
                "it.unive.lisa.events.EventListener",
                "it.unive.lisa.events.Event",
                "it.unive.lisa.outputs.LiSAOutput");

        try (Writer w = Files.newBufferedWriter(Path.of("../_data/subtypes.yaml"))) {
            new Yaml().dump(result, w);
        }

        System.out.println("Written subtypes.yaml");
    }

    static List<Path> downloadJars(
            String version,
            Path dir)
            throws IOException {
        List<Path> jars = new ArrayList<>();

        for (String art : ARTIFACTS) {
            String jar = art + "-" + version + ".jar";
            String url = BASE_URL + "/" + art + "/" + version + "/" + jar;
            Path out = dir.resolve(jar);

            System.out.println("Downloading " + url);
            try (InputStream in = new URL(url).openStream()) {
                Files.copy(in, out, StandardCopyOption.REPLACE_EXISTING);
            }

            jars.add(out);
        }

        return jars;
    }

    static Map<String, Object> scan(
            List<Path> jars,
            String... roots) {
        try (ScanResult scan = new ClassGraph()
                .overrideClasspath(jars)
                .enableClassInfo()
                .scan()) {

            Map<String, Object> output = new LinkedHashMap<>();

            for (String root : roots) {
                ClassInfo rootInfo = scan.getClassInfo(root);
                if (rootInfo == null) {
                    System.err.println("WARNING: root not found: " + root);
                    continue;
                }
                SortedMap<String, String> node = new TreeMap<>();
                build(rootInfo, node);
                output.put(root, node);
            }

            return output;
        }
    }

    static void build(
            ClassInfo info,
            SortedMap<String, String> children) {
        for (ClassInfo sub : info.getSubclasses()) {
            if (kind(sub).equals("class")) {
                String name = sub.getClasspathElementFile().getName();
                children.put(sub.getName(), name.substring(0, name.lastIndexOf('-')));
            }
            build(sub, children);
        }

        for (ClassInfo impl : info.getClassesImplementing()) {
            if (kind(impl).equals("class")) {
                String name = impl.getClasspathElementFile().getName();
                children.put(impl.getName(), name.substring(0, name.lastIndexOf('-')));
            }
            build(impl, children);
        }
    }

    static String kind(
            ClassInfo ci) {
        if (ci.isInterface())
            return "interface";
        if (ci.isAbstract())
            return "abstract class";
        return "class";
    }
}
