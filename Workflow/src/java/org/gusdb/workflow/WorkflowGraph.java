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

public class WorkflowGraph<T extends WorkflowStep> {
    private List<String> params = new ArrayList<String>();
    private List<T> steps = new ArrayList<T>();
    private Map<String, T> stepsByName = new HashMap<String, T>();
    private Map<String,String> constants = new HashMap<String,String>();
    String[] sortedStepNames; 
    Workflow<T> workflow;
    final static String nl = System.getProperty("line.separator");
    HashMap<T, String> subgraphXmlFileNames;    

    public WorkflowGraph() {}

    public void addConstant(NamedValue constant) {
	constants.put(constant.getName(),constant.getValue());
    }
    
    public void addParam(String paramName) {
	params.add(paramName);
    }
    
    public void addStep(T step) {
        step.setWorkflowGraph(this);
        String stepName = step.getName();
        if (stepsByName.containsKey(stepName))
            Utilities.error("non-unique step name: '" + stepName + "'");
        stepsByName.put(stepName, step);
        steps.add(step);
        step.substituteConstantValues(constants);
    }

    void setWorkflow(Workflow<T> workflow) {
        this.workflow = workflow;
    }
    
    Workflow<T> getWorkflow() {
        return workflow;
    }

    String[] getSortedStepNames() {
        if (sortedStepNames == null) {
            sortedStepNames = new String[stepsByName.size()];
            stepsByName.keySet().toArray(sortedStepNames); 
            Arrays.sort(sortedStepNames);
        }
        return sortedStepNames;
    }
    
    Map<String, T> getStepsByName() {
        return stepsByName;
    }
    
    List<T> getSteps() {
        return steps;
    }

    void makeParentChildLinks() {
	// make the parent/child links from the remembered dependencies
	for (T step : steps) {
            for (Name dependName : step.getDependsNames()) {
                String stepName = step.getName();
                T parent = stepsByName.get(dependName.getName());
                if (parent == null) 
                    Utilities.error("step '" + stepName + "' depends on '"
                          + dependName + "' which is not found");
                step.addParent(parent);
                parent.addChild(step);
            }
            
            // while we are here, keep track of all subgraph xml files
            String sgxfn = step.getSubgraphXmlFileName();
            if (sgxfn != null) {
                subgraphXmlFileNames.put(step, sgxfn);
                T insertedChild = step.newStep();
                = step.insertChild();
            }
        }
    }
    
    List<T> getRootSteps() {
        return new ArrayList<T>();
    }
    
    List<T> getLeafSteps() {
        return new ArrayList<T>();
    }
    
    private Collection<String> getSubgraphXmlFileNames() {
        return subgraphXmlFileNames.values();
    }
     
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + steps.toString();
    }
    
    private void injectSubgraphs(HashMap<String, WorkflowGraph<T>> graphsMap) {
        for (T stepWithSubgraph : subgraphXmlFileNames.keySet()) {
            String subgraphXmlFileName = subgraphXmlFileNames.get(stepWithSubgraph);
            WorkflowGraph<T> subgraph = graphsMap.get(subgraphXmlFileName);
            subgraph.injectSubgraphs(graphsMap);
            
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    //     Static methods
    ////////////////////////////////////////////////////////////////////////
    
    static <S extends WorkflowStep > WorkflowGraph<S> constructFullGraph(Class<S> stepClass,
            Workflow<S> workflow) throws FileNotFoundException, SAXException, IOException, Exception {
        
        HashMap<String, WorkflowGraph<S>> graphsMap = new HashMap<String, WorkflowGraph<S>>();
        WorkflowGraph.makeGraphsMap(graphsMap, stepClass, workflow,
                workflow.getStepsXmlFileName(), new ArrayList<String>());
        WorkflowGraph<S> rootGraph = graphsMap.get(workflow.getStepsXmlFileName());
        rootGraph.injectSubgraphs(graphsMap);
        return rootGraph;
    }   
    
    // recursively parse graph xml files, and put all resulting graphs
    // into a map keyed on the name of the xml file
    private static <S extends WorkflowStep > void makeGraphsMap(
            Map<String, WorkflowGraph<S>> map,
            Class<S> stepClass,
            Workflow<S> workflow, String xmlFileName,
            List<String> callingXmlFileNames) throws SAXException, IOException, Exception {
         
        WorkflowGraph<S> workflowGraph;         
         if (map.containsKey(xmlFileName)) {
             workflowGraph = map.get(xmlFileName);
         } else {
             WorkflowXmlParser<S> parser = new WorkflowXmlParser<S>();
             workflowGraph = parser.parseWorkflow(workflow, stepClass, xmlFileName);
             map.put(xmlFileName, workflowGraph);
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
             
             makeGraphsMap(map, stepClass, workflow, subgraphXmlFileName,
                     callingXmlFileNames);
         }
     }

}
