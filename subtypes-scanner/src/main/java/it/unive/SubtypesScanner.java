package it.unive;

import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
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
        List<Path> javadocJars = downloadJavadocJars(version, tempDir);

        Map<String, String> javadocs = extractJavadocs(javadocJars);
        System.out.println("Extracted javadocs for " + javadocs.size() + " classes");

        Map<String, Object> result = scan(
                jars,
                javadocs,
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
        return downloadJars(version, dir, "");
    }

    static List<Path> downloadJavadocJars(
            String version,
            Path dir)
            throws IOException {
        return downloadJars(version, dir, "-javadoc");
    }

    static List<Path> downloadJars(
            String version,
            Path dir,
            String classifier)
            throws IOException {
        List<Path> jars = new ArrayList<>();

        for (String art : ARTIFACTS) {
            String jarName = art + "-" + version + classifier + ".jar";
            String url = BASE_URL + "/" + art + "/" + version + "/" + jarName;
            Path out = dir.resolve(jarName);

            System.out.println("Downloading " + url);
            try (InputStream in = new URL(url).openStream()) {
                Files.copy(in, out, StandardCopyOption.REPLACE_EXISTING);
            }

            jars.add(out);
        }

        return jars;
    }

    static Map<String, String> extractJavadocs(
            List<Path> javadocJars)
            throws IOException {
        Map<String, String> result = new HashMap<>();

        for (Path jar : javadocJars) {
            try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(jar))) {
                ZipEntry entry;
                while ((entry = zis.getNextEntry()) != null) {
                    String name = entry.getName();
                    if (!entry.isDirectory() && name.endsWith(".html")) {
                        String baseName = name.substring(name.lastIndexOf('/') + 1, name.length() - 5);
                        // Skip package-summary, package-tree, index, overview, etc.
                        // Class files follow PascalCase and never contain hyphens.
                        if (!baseName.isEmpty()
                                && Character.isUpperCase(baseName.charAt(0))
                                && !baseName.contains("-")) {
                            // it/unive/lisa/Foo.html -> it.unive.lisa.Foo
                            String className = name.replace('/', '.').replace('\\', '.');
                            className = className.substring(0, className.length() - 5);

                            String html = new String(zis.readAllBytes(), StandardCharsets.UTF_8);
                            String doc = extractClassDescription(html);
                            if (doc != null && !doc.isBlank())
                                result.put(className, doc);
                        }
                    }
                    zis.closeEntry();
                }
            }
        }

        return result;
    }

    static String extractClassDescription(
            String html) {
        Document doc = Jsoup.parse(html);

        // Java 17+ doclet: <section class="class-description"> ... <div class="block">
        Element block = doc.selectFirst("section.class-description .block");
        // Java 11-16 doclet: <div class="description"> ... <div class="block">
        if (block == null)
            block = doc.selectFirst("div.description .block");
        // Generic fallback: first .block on the page
        if (block == null)
            block = doc.selectFirst(".block");

        if (block == null)
            return null;

        // Unwrap relative links — they point into the javadoc tree and are broken
        // on the website; keep the link text.
        block.select("a[href]").forEach(Element::unwrap);

        return block.html().trim();
    }

    static Map<String, Object> scan(
            List<Path> jars,
            Map<String, String> javadocs,
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
                SortedMap<String, Map<String, String>> node = new TreeMap<>();
                build(rootInfo, node, javadocs);
                output.put(root, node);
            }

            return output;
        }
    }

    static void build(
            ClassInfo info,
            SortedMap<String, Map<String, String>> children,
            Map<String, String> javadocs) {
        for (ClassInfo sub : info.getSubclasses()) {
            if (kind(sub).equals("class"))
                children.put(sub.getName(), entry(sub, javadocs));
            build(sub, children, javadocs);
        }

        for (ClassInfo impl : info.getClassesImplementing()) {
            if (kind(impl).equals("class"))
                children.put(impl.getName(), entry(impl, javadocs));
            build(impl, children, javadocs);
        }
    }

    static Map<String, String> entry(
            ClassInfo ci,
            Map<String, String> javadocs) {
        String jarName = ci.getClasspathElementFile().getName();
        String artifact = jarName.substring(0, jarName.lastIndexOf('-'));

        Map<String, String> e = new LinkedHashMap<>();
        e.put("artifact", artifact);

        String doc = javadocs.get(ci.getName());
        if (doc != null)
            e.put("doc", doc);

        return e;
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
