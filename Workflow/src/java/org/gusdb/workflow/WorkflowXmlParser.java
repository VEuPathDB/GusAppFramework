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

public class WorkflowXmlParser extends XmlParser {

    private static final Logger logger = Logger.getLogger(WorkflowXmlParser.class);

    public WorkflowXmlParser() throws SAXException, IOException {

        super("lib/rng/workflow.rng");
    }

    public Workflow parseWorkflow(String homeDir) throws SAXException, IOException, Exception {
             
        Properties workflowProps = new Properties();
        workflowProps.load(new FileInputStream(homeDir + "config/workflow.prop"));
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
	Workflow workflow = (Workflow)digester.parse(xmlStream);
	workflow.setHomeDir(homeDir);
        return workflow;
    }

    protected Digester configureDigester() {
        Digester digester = new Digester();
        digester.setValidating(false);

        // Root -- WDK Model
        digester.addObjectCreate("workflow", Workflow.class);

        configureNode(digester, "workflow/constant", NamedValue.class,
        "addConstant");
        digester.addCallMethod("workflow/constant", "setValue", 0);

        configureNode(digester, "workflow/step", WorkflowStep.class,
                "addStep");

        configureNode(digester, "workflow/step/depends", Name.class,
                "addDependsName");
        
        configureNode(digester, "workflow/step/paramValue", NamedValue.class,
        "addParamValue");
        digester.addCallMethod("workflow/step/paramValue", "setValue", 0);

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
        WorkflowXmlParser parser = new WorkflowXmlParser();
        Workflow workflow = parser.parseWorkflow(homeDir);

        // print out the model content
        System.out.println(workflow.toString());
        System.exit(0);
    }

    private static Options declareOptions() {
        Options options = new Options();

        Utilities.addOption(options, "h", "");

        return options;
    }




}
