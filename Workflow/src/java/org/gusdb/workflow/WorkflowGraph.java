package org.gusdb.workflow;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import org.xml.sax.SAXException;

/*
 * Overall subgraph strategy
 *  (1) parse root graph
 *     - parsing a graph sets parent child links, and inserts sugraph return nodes
 *  
 *  (2) expand subgraphs
 *     - starting with root graph, bottom up recursion through graph/subgraph
 *       hierarchy.  
 *     - for each graph, iterate through steps that call subgraphs.  the edge
 *       between it and its subgraph-return child is replaced with (copies of)
 *       the steps from the referenced template.
 *   
 *  (3) in a final pass, set the path of each of the steps (top down recursion)
 * 
 * 
 */

public class WorkflowGraph<T extends WorkflowStep> {
    private List<String> paramDeclarations = new ArrayList<String>();
    private Map<String,String> constants = new HashMap<String,String>();
    Workflow<T> workflow;
    String xmlFileName;
    String name;
    
    Map<T, String> stepsWithSubgraph = new HashMap<T, String>(); 
    private List<T> rootSteps = new ArrayList<T>();
    
    // following state must be updated after expansion
    Map<String, T> stepsByName = new HashMap<String, T>();
    private List<T> leafSteps = new ArrayList<T>();    
    List<T> sortedSteps; 
    private Map<String, List<T>> globalSteps = new HashMap<String, List<T>>();
    
    final static String nl = System.getProperty("line.separator");

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addParamDeclaration(Name paramName) {
	paramDeclarations.add(paramName.getName());
    }
    
    public void setName(String name) {
	this.name = name;
    }

    public void addStep(T step) {
        step.setWorkflowGraph(this);
        String stepName = step.getBaseName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("in graph " + name + ", non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
    }

    void setWorkflow(Workflow<T> workflow) {
        this.workflow = workflow;
    }
    
    Workflow<T> getWorkflow() {
        return workflow;
    }

    void setXmlFileName(String xmlFileName) {
     this.xmlFileName = xmlFileName;
    }
    
    @SuppressWarnings("unchecked")
    List<T> getSortedSteps() {
        if (sortedSteps == null) {
            sortedSteps = new ArrayList<T>();
            for (T rootStep : rootSteps) {
                rootStep.addToList((List<WorkflowStep>)sortedSteps);
            }
        }
        return sortedSteps;
    }
    
    Map<String, T> getStepsByName() {
        return stepsByName;
    }
    
    Collection<T> getSteps() {
        return stepsByName.values();
    }
    
    @SuppressWarnings("unchecked")
    void makeParentChildLinks() {
	// make the parent/child links from the remembered dependencies
	for (T step : getSteps()) {
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getBaseName();
                T parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("in file " + xmlFileName + ", step '"
				    + stepName + "' depends on step '"
                          + dependName.getName() + "' which is not found");
                step.addParent(parent);
                parent.addChild(step);
            }
            
            // while we are here, keep track of all subgraph xml files
            String sgxfn = step.getSubgraphXmlFileName();
            if (sgxfn != null) {
                stepsWithSubgraph.put(step, sgxfn);
            }
        }
	
	// second pass: insert subgraph return children, and collect root steps
	Map<String, T> currentStepsByName = new HashMap<String, T>(stepsByName);
        for (T step : currentStepsByName.values()) {
            if (step.getSubgraphXmlFileName() != null) {
                T returnStep = (T)step.insertSubgraphReturnChild();
                stepsByName.put(returnStep.getBaseName(), returnStep);
            }
            
            if (step.getParents().size() == 0) rootSteps.add(step);
            if (step.getChildren().size() == 0) leafSteps.add(step);
        }
        
    }
        
    private Collection<String> getSubgraphXmlFileNames() {
        return stepsWithSubgraph.values();
    }
     
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + getSortedSteps().toString();
    }
    
    private void instantiateValues(Map<String,String> paramValues) {
        for (T step : getSteps()) {
            step.substituteValues(constants);
            step.substituteValues(paramValues);
        }
    }
    /////////////////////////////////////////////////////////////////////////
    //   subgraph expansion
    /////////////////////////////////////////////////////////////////////////
    private void expandSubgraphs(String path, List<String> callingXmlFileNames, Class<T> stepClass) throws SAXException, Exception {
        for (T stepWithSubgraph : stepsWithSubgraph.keySet()) {
        
            // get a graph to insert
            String subgraphXmlFileName = stepsWithSubgraph.get(stepWithSubgraph);
	    if (callingXmlFileNames.contains(subgraphXmlFileName)) {
		throw new Exception("Circular reference to graphXmlFile '"
				    + subgraphXmlFileName + "'"
				    + " step path: '" + path + "'");
	    }      
	    WorkflowXmlParser<T> parser = new WorkflowXmlParser<T>();
	    WorkflowGraph<T> subgraph =
		parser.parseWorkflow(workflow, stepClass, subgraphXmlFileName); 

            // set the path of its unexpanded steps
            String newPath = path + stepWithSubgraph.getBaseName() + ".";
            subgraph.setPath(newPath);
            
            // 
            subgraph.instantiateValues(stepWithSubgraph.getParamValues());

            // expand it (recursively) 
            // (this includes setting the paths of the expanded steps
	    List<String> callingXmlFileNamesNew = new ArrayList<String>(callingXmlFileNames);
	    callingXmlFileNamesNew.add(subgraphXmlFileName);
            subgraph.expandSubgraphs(newPath, callingXmlFileNamesNew, stepClass); 
            
            // insert it
            WorkflowStep subgraphReturnStep = stepWithSubgraph.getChildren().get(0);
            stepWithSubgraph.removeChild(subgraphReturnStep);
            subgraphReturnStep.removeParent(stepWithSubgraph);
            subgraph.attachToParentStep(stepWithSubgraph);
            subgraph.attachToChildStep(subgraphReturnStep);
            
            // add its steps to stepsByName
            for (T subgraphStep : subgraph.getSteps()) {
                stepsByName.put(subgraphStep.getFullName(), subgraphStep);
            }
        }
    }
    
    private void setPath(String path) {
        for (T step : getSteps()) step.setPath(path);
    }
    
    private void attachToParentStep(WorkflowStep parentStep) {
        for (T rootStep : rootSteps) {
            parentStep.addChild(rootStep);
            rootStep.addParent(parentStep);
        }
    }
    
    private void attachToChildStep(WorkflowStep childStep) {
        for (T leafStep : leafSteps) {
            childStep.addParent(leafStep);
            leafStep.addChild(childStep);
        }
    }
    
    private void initializeGlobalSteps() {
        for (T step : getSteps()) {
            if (step.getIsGlobal()) {
                String stepSignature = step.getSignature();
                if (!globalSteps.containsKey(stepSignature)) {
                    globalSteps.put(stepSignature, new ArrayList<T>());
                }
                List<T> sharedGlobalSteps = globalSteps.get(stepSignature);
                sharedGlobalSteps.add(step);
                step.setSharedGlobalSteps(sharedGlobalSteps);
            }
        }
        
    }
    
    ////////////////////////////////////////////////////////////////////////
    //     Static methods
    ////////////////////////////////////////////////////////////////////////
    
    static <S extends WorkflowStep > WorkflowGraph<S> constructFullGraph(Class<S> stepClass,
            Workflow<S> workflow) throws FileNotFoundException, SAXException, IOException, Exception {
        
	WorkflowXmlParser<S> parser = new WorkflowXmlParser<S>();
	WorkflowGraph<S> rootGraph =
		parser.parseWorkflow(workflow, stepClass, workflow.getStepsXmlFileName()); 

        rootGraph.instantiateValues(getRootGraphParamValues(workflow));
        
        // expand subgraphs
	List<String> callingXmlFileNames = new ArrayList<String>();
	callingXmlFileNames.add(workflow.getStepsXmlFileName());
        rootGraph.expandSubgraphs("", callingXmlFileNames, stepClass);
        
        // initialize global steps
        // rootGraph.initializeGlobalSteps();
        
        return rootGraph;
    }   
    
    @SuppressWarnings("unchecked")
    static <S extends WorkflowStep > Map<String,String>getRootGraphParamValues(Workflow<S> workflow) throws FileNotFoundException, IOException {
        Properties paramValues = new Properties();
        paramValues.load(new FileInputStream(workflow.getHomeDir() + "/config/rootParams.prop"));
        Map<String,String>map = new HashMap<String,String>();
        Enumeration<String> e = (Enumeration<String>) paramValues.propertyNames();
        while(e.hasMoreElements()) {
            String k = e.nextElement();
            map.put(k,paramValues.getProperty(k));
        }
        return map;
    }
    
}
