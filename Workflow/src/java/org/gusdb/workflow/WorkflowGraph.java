package org.gusdb.workflow;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.xml.sax.SAXException;

/*
 * Overall subgraph strategy
 *  (1) make graph templates
 *     - parse root xml file, and all xml files it refers to.  put resulting
 *       graphs into templates map, keyed on name of xml files
 *     - in this pass, any step that calls a subgraph has an "subgraph return"
 *       child inserted between it and its natural children
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
    private List<String> params = new ArrayList<String>();
    private Map<String,String> constants = new HashMap<String,String>();
    Workflow<T> workflow;
    String xmlFileName;
    
    Map<T, String> stepsWithSubgraph = new HashMap<T, String>(); 
    private List<T> rootSteps = new ArrayList<T>();
    
    // following state must be updated after expansion
    private Map<String, T> stepsByName = new HashMap<String, T>();
    private List<T> leafSteps = new ArrayList<T>();    
    List<T> sortedSteps; 
    
    final static String nl = System.getProperty("line.separator");

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addParam(String paramName) {
	params.add(paramName);
    }
    
    public void addStep(T step) {
        step.setWorkflowGraph(this);
        String stepName = step.getBaseName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
        step.substituteConstantValues(constants);
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
                    Utilities.error("step '" + stepName + "' depends on '"
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
    
    /////////////////////////////////////////////////////////////////////////
    //   subgraph expansion
    /////////////////////////////////////////////////////////////////////////
    private void expandSubgraphs(HashMap<String, WorkflowGraph<T>> templates, String path) {
        for (T stepWithSubgraph : stepsWithSubgraph.keySet()) {
        
            // get a graph to insert
            String subgraphXmlFileName = stepsWithSubgraph.get(stepWithSubgraph);
            WorkflowGraph<T> template = templates.get(subgraphXmlFileName);
            WorkflowGraph<T> subgraph = template; //.clone();
            
            // set the path of its unexpanded steps
            String newPath = path + stepWithSubgraph.getBaseName() + ".";
            subgraph.setPath(newPath);

            // expand it (recursively) 
            // (this includes setting the paths of the expanded steps
            subgraph.expandSubgraphs(templates, newPath); 
            
            // insert it
            WorkflowStep subgraphReturnStep = stepWithSubgraph.getChildren().get(0);
            stepWithSubgraph.removeChild(subgraphReturnStep);
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
            childStep.addChild(leafStep);
            leafStep.addParent(childStep);
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    //     Static methods
    ////////////////////////////////////////////////////////////////////////
    
    static <S extends WorkflowStep > WorkflowGraph<S> constructFullGraph(Class<S> stepClass,
            Workflow<S> workflow) throws FileNotFoundException, SAXException, IOException, Exception {
        
        // make templates
        HashMap<String, WorkflowGraph<S>> templates = new HashMap<String, WorkflowGraph<S>>();
        WorkflowGraph.makeGraphTemplates(templates, stepClass, workflow,
                workflow.getStepsXmlFileName(), new ArrayList<String>());
        
        // expand subgraphs
        WorkflowGraph<S> rootGraph = templates.get(workflow.getStepsXmlFileName());
        rootGraph.expandSubgraphs(templates, "");
        
        return rootGraph;
    }   
    
    // recursively parse graph xml files, and put all resulting graphs
    // into a map keyed on the name of the xml file
    // these will be used as templates to inject graphs into the main graph
    private static <S extends WorkflowStep > void makeGraphTemplates(
            Map<String, WorkflowGraph<S>> templates,
            Class<S> stepClass,
            Workflow<S> workflow, String xmlFileName,
            List<String> callingXmlFileNames) throws SAXException, IOException, Exception {
         
        WorkflowGraph<S> workflowGraph;         
         if (templates.containsKey(xmlFileName)) {
             workflowGraph = templates.get(xmlFileName);
         } else {
             WorkflowXmlParser<S> parser = new WorkflowXmlParser<S>();
             workflowGraph = parser.parseWorkflow(workflow, stepClass, xmlFileName);
             templates.put(xmlFileName, workflowGraph);
         }
         
         callingXmlFileNames = new ArrayList<String>(callingXmlFileNames);
         callingXmlFileNames.add(xmlFileName);
         
         // always have to go down path of child graphs, even if we have already
         // seen this xml file, because it may be in a different context
         // and we need to flush circular references in all contexts
         for (String subgraphXmlFileName : workflowGraph.getSubgraphXmlFileNames()) {
             if (callingXmlFileNames.contains(subgraphXmlFileName)) {
                     throw new Exception("Circular reference to graphXmlFile '"
                             + subgraphXmlFileName + "'");
             }      
             
             makeGraphTemplates(templates, stepClass, workflow, subgraphXmlFileName,
                     callingXmlFileNames);
         }
     }
}
