package org.gusdb.workflow;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class WorkflowGraph<T extends WorkflowStep> {
    private List<String> params = new ArrayList<String>();
    private List<T> steps = new ArrayList<T>();
    private Map<String, T> stepsByName = new HashMap<String, T>();
    private Map<String,String> constants = new HashMap<String,String>();
    String[] sortedStepNames; 
    Workflow<T> workflow;
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
    }
    
    public String toString() {
        return "Constants" + nl + constants.toString() + nl + nl
        + "Steps" + nl + steps.toString();
    }

}
