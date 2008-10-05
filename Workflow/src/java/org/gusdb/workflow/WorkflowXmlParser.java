package org.gusdb.workflow;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
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

    public WorkflowXmlParser(String gusHome) throws SAXException, IOException {
        super(gusHome, "lib/rng/workflow.rng");
    }

    @SuppressWarnings("unchecked")
    public Map<String, WorkflowStep> parseWorkflow(String xmlFileName, Workflow workflow) throws SAXException, IOException, Exception {
             
        // construct urls to model file, prop file, and config file
        URL modelURL = makeURL(gusHome, "lib/xml/workflow/" + xmlFileName);

        if (!validate(modelURL))
            throw new Exception("validation failed.");

        Document doc = buildDocument(modelURL);

        // load property map
        Map<String, String> properties = new HashMap<String, String>();
        //Map<String, String> properties = getPropMap(modelPropURL);

        InputStream xmlStream = substituteProps(doc, properties);

        List<WorkflowStep> steps = (List<WorkflowStep>)digester.parse(xmlStream);
        
        Map<String, WorkflowStep> stepsByName = new HashMap();
        for (WorkflowStep step : steps) {
	    step.setWorkflow(workflow);
            String stepName = step.getName();
            if (stepsByName.containsKey(stepName))
                Utilities.error("non-unique step name: '" + stepName + "'");
            stepsByName.put(stepName, step);
        }

        // in second pass, make the parent/child links from the remembered
        // dependencies
        for (WorkflowStep step : steps) {
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getName();
                WorkflowStep parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("step '" + stepName + "' depends on '"
                          + dependName + "' which is not found");
                step.addParent(parent);
            }
        }
        
        return stepsByName;
    }

    protected Digester configureDigester() {
        Digester digester = new Digester();
        digester.setValidating(false);

        // Root -- WDK Model
        digester.addObjectCreate("workflow", ArrayList.class);

        configureNode(digester, "workflow/step", WorkflowStep.class,
                "add");

        configureNode(digester, "workflow/step/depends", Name.class,
                "addDependsName");
        
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
        String gusHome = System.getProperty("GUS_HOME");

        // process args
        Options options = declareOptions();
        String cmdlineSyntax = cmdName + " -h workflowDir";
        String cmdDescrip = "Parse and print out a workflow xml file.";
        CommandLine cmdLine =
            Utilities.parseOptions(cmdlineSyntax, cmdDescrip, "", options, args);
        String homeDir = cmdLine.getOptionValue("h");
        Properties workflowProps = new Properties();
        workflowProps.load(new FileInputStream(homeDir + "/workflow.prop"));
        String xmlFileName = workflowProps.getProperty("workflowXmlFile");

        // create a parser, and parse the model file
        WorkflowXmlParser parser = new WorkflowXmlParser(gusHome);
        Map<String,WorkflowStep> steps = parser.parseWorkflow(xmlFileName, null);

        // print out the model content
        System.out.println(steps.toString());
        System.exit(0);
    }

    private static Options declareOptions() {
        Options options = new Options();

        Utilities.addOption(options, "h", "");

        return options;
    }




}
