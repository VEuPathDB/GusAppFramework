package org.gusdb.workflow;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Matcher;

import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.Options;
import org.apache.commons.digester.Digester;
import org.apache.log4j.Logger;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

import org.gusdb.workflow.WorkflowStep;
import org.gusdb.workflow.Name;

public class WorkflowXmlParser<T extends WorkflowStep> extends XmlParser {

    private static final Logger logger = Logger.getLogger(WorkflowXmlParser.class);
    private Class<T> stepClass;

    public WorkflowXmlParser() {
        super("lib/rng/workflow.rng");
    }

    @SuppressWarnings("unchecked")
    public WorkflowGraph<T> parseWorkflow(Workflow workflow, Class<T> stepClass) throws SAXException, IOException, Exception {
        this.stepClass = stepClass;
        configure();
        Properties workflowProps = new Properties();
        workflowProps.load(new FileInputStream(workflow.getHomeDir() + "config/workflow.prop"));
        String xmlFileName = workflowProps.getProperty("workflowXmlFile");

        // construct urls to model file, prop file, and config file
        URL modelURL = makeURL(gusHome, "lib/xml/workflow/" + xmlFileName);

        if (!validate(modelURL))
            throw new Exception("validation failed.");

        Document doc = buildDocument(modelURL);

        // load property map
        Map<String, String> properties = new HashMap<String, String>();
        //Map<String, String> properties = getPropMap(modelPropURL);

        InputStream xmlStream = substituteProps(doc, properties);
	WorkflowGraph<T> workflowGraph = (WorkflowGraph<T>)digester.parse(xmlStream);
	workflowGraph.setWorkflow(workflow);
	workflowGraph.makeParentChildLinks();
	// also, resolve embedded subgraphs
        return workflowGraph;
    }

    protected Digester configureDigester() {
        Digester digester = new Digester();
        digester.setValidating(false);
        WorkflowGraph<T> wg = new WorkflowGraph<T>();
        
        // Root -- WDK Model
        digester.addObjectCreate("workflowGraph", wg.getClass());

        configureNode(digester, "workflowGraph/constant", NamedValue.class,
        "addConstant");
        digester.addCallMethod("workflowGraph/constant", "setValue", 0);

        configureNode(digester, "workflowGraph/step", stepClass,
                "addStep");

        configureNode(digester, "workflowGraph/step/depends", Name.class,
                "addDependsName");
        
        configureNode(digester, "workflowGraph/step/paramValue", NamedValue.class,
        "addParamValue");
        digester.addCallMethod("workflowGraph/step/paramValue", "setValue", 0);

       return digester;
    }

    private InputStream substituteProps(Document masterDoc,
            Map<String, String> properties)
            throws TransformerFactoryConfigurationError, TransformerException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        // transform the DOM doc to a string
        Source source = new DOMSource(masterDoc);
        Result result = new StreamResult(out);
        Transformer transformer = TransformerFactory.newInstance().newTransformer();
        transformer.transform(source, result);
        String content = new String(out.toByteArray());

        // substitute prop macros
        for (String propName : properties.keySet()) {
            String propValue = properties.get(propName);
            content = content.replaceAll("\\@" + propName + "\\@",
                    Matcher.quoteReplacement(propValue));
        }

        // construct input stream
        return new ByteArrayInputStream(content.getBytes());
    }
    
    public static void main(String[] args) throws Exception  {
        String cmdName = System.getProperty("cmdName");
 
        // process args
        Options options = declareOptions();
        String cmdlineSyntax = cmdName + " -h workflowDir";
        String cmdDescrip = "Parse and print out a workflow xml file.";
        CommandLine cmdLine =
            Utilities.parseOptions(cmdlineSyntax, cmdDescrip, "", options, args);
        String homeDir = cmdLine.getOptionValue("h");
        
        // create a parser, and parse the model file
        Workflow<WorkflowStep> workflow = new Workflow<WorkflowStep>(homeDir);
        WorkflowXmlParser<WorkflowStep> parser = new WorkflowXmlParser<WorkflowStep>();
        WorkflowGraph<WorkflowStep> workflowGraph = parser.parseWorkflow(workflow,WorkflowStep.class);
        workflow.setWorkflowGraph(workflowGraph);

        // print out the model content
        System.out.println(workflowGraph.toString());
        System.exit(0);
    }

    private static Options declareOptions() {
        Options options = new Options();

        Utilities.addOption(options, "h", "");

        return options;
    }




}
